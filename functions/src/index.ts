import { createHash } from "node:crypto";

import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";

const openAIAPIKey = defineSecret("OPENAI_API_KEY");
const realtimeClientSecretsURL = "https://api.openai.com/v1/realtime/client_secrets";
const responsesURL = "https://api.openai.com/v1/responses";
const voiceAnnotationModel = "gpt-5.6-sol";

export const realtimeSession = {
  type: "realtime",
  model: "gpt-realtime-2.1",
  instructions: [
    "You are Solora, a warm, concise career-memory companion.",
    "Use the supplied local app tools instead of claiming an action succeeded.",
    "When the user asks to go to a part of Solora, call navigate_app with userRequested true.",
    "When the user asks to view a specific memory, search first and then call open_memory_detail with the returned identifier.",
    "Never write a memory or start creation/share output without the app's explicit confirmation step.",
    "Keep spoken replies brief and ask one useful question at a time.",
  ].join(" "),
  audio: {
    output: { voice: "marin" },
  },
} as const;

type Fetch = typeof fetch;

export type VoiceMemoryDraft = {
  title: string;
  summary: string;
  category: string;
};

export async function shapeVoiceMemoryDraft(
  apiKey: string,
  transcript: string,
  userID: string,
  fetcher: Fetch = fetch,
): Promise<VoiceMemoryDraft> {
  const cleanTranscript = transcript.trim().slice(0, 8_000);
  if (!cleanTranscript) {
    throw new Error("Voice annotation was empty");
  }

  const safetyIdentifier = createHash("sha256")
    .update(`solora:${userID}`)
    .digest("hex");
  const upstream = await fetcher(responsesURL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: voiceAnnotationModel,
      reasoning: { effort: "none" },
      store: false,
      safety_identifier: safetyIdentifier,
      instructions: [
        "Turn only the user's voice annotation into one factual, first-person career memory.",
        "Do not add achievements, dates, metrics, people, or context that the annotation did not state.",
        "Write a concise title, a useful two-sentence summary, and a short category.",
      ].join(" "),
      input: cleanTranscript,
      text: {
        format: {
          type: "json_schema",
          name: "voice_memory_draft",
          strict: true,
          schema: {
            type: "object",
            additionalProperties: false,
            properties: {
              title: { type: "string" },
              summary: { type: "string" },
              category: { type: "string" },
            },
            required: ["title", "summary", "category"],
          },
        },
      },
    }),
  });

  if (!upstream.ok) {
    throw new Error(`OpenAI voice annotation request failed with status ${upstream.status}`);
  }
  const payload = await upstream.json() as {
    output?: Array<{ type?: string; content?: Array<{ type?: string; text?: string; refusal?: string }> }>;
  };
  const text = payload.output
    ?.find((item) => item.type === "message")
    ?.content?.find((item) => item.type === "output_text")?.text;
  if (!text) {
    throw new Error("OpenAI voice annotation response did not contain structured text");
  }
  const result = JSON.parse(text) as Partial<VoiceMemoryDraft>;
  if (typeof result.title !== "string" || typeof result.summary !== "string" || typeof result.category !== "string") {
    throw new Error("OpenAI voice annotation response was malformed");
  }
  return {
    title: result.title.trim().slice(0, 120),
    summary: result.summary.trim().slice(0, 2_000),
    category: result.category.trim().slice(0, 40),
  };
}

export async function mintRealtimeClientSecret(
  apiKey: string,
  userID: string,
  fetcher: Fetch = fetch,
): Promise<{ value: string; expires_at?: number }> {
  const safetyIdentifier = createHash("sha256")
    .update(`solora:${userID}`)
    .digest("hex");
  const upstream = await fetcher(realtimeClientSecretsURL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "OpenAI-Safety-Identifier": safetyIdentifier,
    },
    body: JSON.stringify({ session: realtimeSession }),
  });

  if (!upstream.ok) {
    throw new Error(`OpenAI Realtime credential request failed with status ${upstream.status}`);
  }

  const payload = await upstream.json() as { value?: unknown; expires_at?: unknown };
  if (typeof payload.value !== "string" || payload.value.length === 0) {
    throw new Error("OpenAI Realtime credential response did not contain a client secret");
  }
  return {
    value: payload.value,
    ...(typeof payload.expires_at === "number" ? { expires_at: payload.expires_at } : {}),
  };
}

/** A deterministic, public-safe response for the health endpoint. */
export function healthPayload(): { service: "Solora"; status: "ok" } {
  return {
    service: "Solora",
    status: "ok",
  };
}

export const health = onRequest((_request, response) => {
  response.status(200).json(healthPayload());
});

/** Mints a short-lived Realtime credential for an authenticated Solora client. */
export const createRealtimeClientSecret = onCall(
  {
    secrets: [openAIAPIKey],
    // The debug App Check provider on the demo build has not been registered
    // in Firebase yet. Firebase Authentication below still gates every mint.
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before starting a voice session.");
    }

    try {
      return await mintRealtimeClientSecret(openAIAPIKey.value(), request.auth.uid);
    } catch (error) {
      console.error("Unable to mint OpenAI Realtime client credential", error);
      throw new HttpsError("unavailable", "Voice is temporarily unavailable. Please try again.");
    }
  },
);

/** Turns a completed, user-recorded annotation into a local memory draft. */
export const annotateVoiceMemory = onCall(
  {
    secrets: [openAIAPIKey],
    // Firebase Authentication remains mandatory; App Check is re-enabled once the demo token is registered.
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in before annotating a memory.");
    }
    if (typeof request.data?.transcript !== "string" || !request.data.transcript.trim()) {
      throw new HttpsError("invalid-argument", "A completed voice annotation is required.");
    }
    try {
      return await shapeVoiceMemoryDraft(openAIAPIKey.value(), request.data.transcript, request.auth.uid);
    } catch (error) {
      console.error("Unable to shape voice annotation", error);
      throw new HttpsError("unavailable", "Voice annotation is temporarily unavailable. Please try again.");
    }
  },
);
