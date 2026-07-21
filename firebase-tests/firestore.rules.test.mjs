import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { after, before, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from "firebase/firestore";

const projectId = process.env.GCLOUD_PROJECT ?? "solora-5hadowblaze";
const ownerId = "owner-user";
const otherId = "other-user";
let testEnvironment;

function validMoment(id = "moment-1") {
  return {
    id,
    title: "A useful workshop",
    caption: "I clarified the launch decision.",
    occurredAt: Timestamp.fromDate(new Date("2026-07-18T12:00:00Z")),
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    world: "memoryShelves",
    schemaVersion: 1,
    photoPaths: [],
  };
}

function validMomentV2(id = "moment-v2") {
  return {
    ...validMoment(id),
    schemaVersion: 2,
    reflection: "I led the workshop and clarified the next decision.",
    memoryType: "work",
    playbackStyle: "photoSequence",
    photoPaths: ["users/owner-user/wins/moment-v2/photos/poster.jpg"],
    visualAssets: [{
      id: "poster",
      posterPath: "users/owner-user/wins/moment-v2/photos/poster.jpg",
      kind: "photo",
    }],
  };
}

before(async () => {
  const rules = await readFile(new URL("../firestore.rules", import.meta.url), "utf8");
  testEnvironment = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await testEnvironment?.cleanup();
});

test("an owner can create and list valid moments", async () => {
  const firestore = testEnvironment.authenticatedContext(ownerId).firestore();
  await assertSucceeds(setDoc(
    doc(firestore, "users", ownerId, "wins", "moment-1"),
    validMoment()
  ));
  const snapshot = await assertSucceeds(getDocs(
    collection(firestore, "users", ownerId, "wins")
  ));
  assert.equal(snapshot.size, 1);
});

test("another account cannot read an owner's moment", async () => {
  const firestore = testEnvironment.authenticatedContext(otherId).firestore();
  await assertFails(getDoc(doc(
    firestore,
    "users",
    ownerId,
    "wins",
    "moment-1"
  )));
});

test("unknown user subcollections stay closed", async () => {
  const firestore = testEnvironment.authenticatedContext(ownerId).firestore();
  await assertFails(setDoc(
    doc(firestore, "users", ownerId, "private", "unexpected"),
    { value: true }
  ));
});

test("extra fields and invalid world values are rejected", async () => {
  const firestore = testEnvironment.authenticatedContext(ownerId).firestore();
  await assertFails(setDoc(
    doc(firestore, "users", ownerId, "wins", "invalid-extra"),
    { ...validMoment("invalid-extra"), transcript: "not accepted" }
  ));
  await assertFails(setDoc(
    doc(firestore, "users", ownerId, "wins", "invalid-world"),
    { ...validMoment("invalid-world"), world: "unknown" }
  ));
});

test("an owner can update a valid schema-v2 memory", async () => {
  const firestore = testEnvironment.authenticatedContext(ownerId).firestore();
  const reference = doc(firestore, "users", ownerId, "wins", "moment-v2");
  await assertSucceeds(setDoc(reference, validMomentV2()));
  await assertSucceeds(updateDoc(reference, {
    caption: "Changed later after reviewing the memory.",
    updatedAt: serverTimestamp(),
  }));
});

test("an owner cannot change a memory identifier", async () => {
  const firestore = testEnvironment.authenticatedContext(ownerId).firestore();
  const reference = doc(firestore, "users", ownerId, "wins", "moment-v2-invalid");
  await assertSucceeds(setDoc(reference, validMomentV2("moment-v2-invalid")));
  await assertFails(updateDoc(reference, {
    id: "different-memory",
    updatedAt: serverTimestamp(),
  }));
});
