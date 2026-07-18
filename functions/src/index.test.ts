import assert from "node:assert/strict";
import test from "node:test";

import { healthPayload, mintRealtimeClientSecret, realtimeSession, shapeVoiceMemoryDraft } from "./index.js";

test("healthPayload returns the public Solora health response", () => {
  assert.deepEqual(healthPayload(), {
    service: "Solora",
    status: "ok",
  });
});

test("Realtime session uses the supported model and a server-owned configuration", () => {
  assert.equal(realtimeSession.type, "realtime");
  assert.equal(realtimeSession.model, "gpt-realtime-2.1");
  assert.equal(realtimeSession.audio.output.voice, "marin");
});

test("mintRealtimeClientSecret sends a privacy-preserving safety identifier", async () => {
  let capturedRequest: RequestInit | undefined;
  const result = await mintRealtimeClientSecret("server-secret", "firebase-user", async (_input, init) => {
    capturedRequest = init;
    return new Response(JSON.stringify({ value: "ek_test", expires_at: 1234 }), { status: 200 });
  });

  assert.deepEqual(result, { value: "ek_test", expires_at: 1234 });
  const headers = capturedRequest?.headers as Record<string, string>;
  assert.equal(headers.Authorization, "Bearer server-secret");
  assert.notEqual(headers["OpenAI-Safety-Identifier"], "firebase-user");
  assert.equal(headers["OpenAI-Safety-Identifier"].length, 64);
});

test("mintRealtimeClientSecret rejects malformed upstream responses", async () => {
  await assert.rejects(
    mintRealtimeClientSecret("server-secret", "firebase-user", async () =>
      new Response(JSON.stringify({}), { status: 200 })),
    /did not contain a client secret/,
  );
});

test("shapeVoiceMemoryDraft returns a bounded structured memory", async () => {
  const result = await shapeVoiceMemoryDraft("server-secret", "I led the workshop and aligned the team on a decision.", "firebase-user", async () =>
    new Response(JSON.stringify({
      output: [{
        type: "message",
        content: [{
          type: "output_text",
          text: JSON.stringify({
            title: "Aligned the workshop",
            summary: "I led the workshop and aligned the team on a decision.",
            category: "Leadership",
          }),
        }],
      }],
    }), { status: 200 }),
  );

  assert.deepEqual(result, {
    title: "Aligned the workshop",
    summary: "I led the workshop and aligned the team on a decision.",
    category: "Leadership",
  });
});
