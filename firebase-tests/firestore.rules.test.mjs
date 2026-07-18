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

test("client-side updates are denied", async () => {
  const firestore = testEnvironment.authenticatedContext(ownerId).firestore();
  await assertFails(updateDoc(
    doc(firestore, "users", ownerId, "wins", "moment-1"),
    { caption: "Changed later" }
  ));
});
