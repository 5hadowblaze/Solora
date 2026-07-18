import assert from "node:assert/strict";
import test from "node:test";

import { healthPayload } from "./index.js";

test("healthPayload returns the public Solora health response", () => {
  assert.deepEqual(healthPayload(), {
    service: "Solora",
    status: "ok",
  });
});
