import { onRequest } from "firebase-functions/v2/https";

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
