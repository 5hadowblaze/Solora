import { createHash } from "node:crypto";

import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";

const openAIAPIKey = defineSecret("OPENAI_API_KEY");
const realtimeClientSecretsURL = "https://api.openai.com/v1/realtime/client_secrets";

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
