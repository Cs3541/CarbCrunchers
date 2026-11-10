const crypto = require("node:crypto");
const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore} = require("firebase-admin/firestore");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

initializeApp();

const db = getFirestore();
const usernames = db.collection("username_index");

function normalizeUsername(value) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Enter a valid username.");
  }

  const username = value.trim().toLowerCase();
  if (!/^[a-z0-9][a-z0-9._-]{2,19}$/.test(username)) {
    throw new HttpsError(
        "invalid-argument",
        "Use 3–20 letters, numbers, periods, underscores, or hyphens.",
    );
  }
  return username;
}

async function applyLookupRateLimit(ipAddress) {
  const addressHash = crypto.createHash("sha256").update(ipAddress).digest("hex");
  const limitRef = db.collection("_username_lookup_limits").doc(addressHash);
  const now = Date.now();

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(limitRef);
    const sameWindow = snapshot.exists &&
      now - snapshot.get("windowStartedAt") < 60_000;
    const count = sameWindow ? snapshot.get("count") : 0;
    if (count >= 10) {
      throw new HttpsError(
          "resource-exhausted",
          "Too many username sign-in attempts. Try again shortly.",
      );
    }

    transaction.set(limitRef, {
      windowStartedAt: sameWindow ? snapshot.get("windowStartedAt") : now,
      count: count + 1,
    });
  });
}

exports.resolveUsername = onCall(async (request) => {
  const username = normalizeUsername(request.data?.username);
  const ipAddress = request.rawRequest.ip || "unknown";
  await applyLookupRateLimit(ipAddress);

  const snapshot = await usernames.doc(username).get();
  if (!snapshot.exists) {
    throw new HttpsError(
        "failed-precondition",
        "No account has this username yet. Set one while signed in first.",
    );
  }

  const data = snapshot.data();
  if (typeof data.uid !== "string" || data.uid.length === 0) {
    throw new HttpsError(
        "failed-precondition",
        "No account has this username yet. Set one while signed in first.",
    );
  }

  let user;
  try {
    user = await getAuth().getUser(data.uid);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new HttpsError(
          "failed-precondition",
          "No account has this username yet. Set one while signed in first.",
      );
    }
    throw error;
  }

  if (!user.email) {
    throw new HttpsError(
        "failed-precondition",
        "This account does not have a sign-in email.",
    );
  }
  return {emails: [user.email]};
});

exports.updateUsername = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to change your username.");
  }

  const username = normalizeUsername(request.data?.username);
  const pendingEmail = request.data?.pendingEmail;
  if (pendingEmail !== null && pendingEmail !== undefined) {
    if (typeof pendingEmail !== "string" ||
        !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(pendingEmail.trim())) {
      throw new HttpsError("invalid-argument", "Enter a valid new email.");
    }
    const authTime = request.auth.token.auth_time * 1000;
    if (Date.now() - authTime > 5 * 60 * 1000) {
      throw new HttpsError(
          "failed-precondition",
          "Sign in again before changing your email.",
      );
    }
  }

  const user = await getAuth().getUser(uid);
  if (!user.email) {
    throw new HttpsError("failed-precondition", "An email account is required.");
  }

  const targetRef = usernames.doc(username);
  const previousUsername = user.displayName;
  const previousKey = typeof previousUsername === "string" &&
      /^[a-z0-9][a-z0-9._-]{2,19}$/i.test(previousUsername)
      ? previousUsername.trim().toLowerCase()
      : null;
  const previousRef = previousKey ? usernames.doc(previousKey) : null;

  const previousState = await db.runTransaction(async (transaction) => {
    const targetSnapshot = await transaction.get(targetRef);
    const previousSnapshot = previousRef &&
        previousRef.path !== targetRef.path ?
      await transaction.get(previousRef) : null;

    if (targetSnapshot.exists && targetSnapshot.get("uid") !== uid) {
      throw new HttpsError("already-exists", "That username is already in use.");
    }

    const state = {
      targetExisted: targetSnapshot.exists,
      targetData: targetSnapshot.data(),
      previousData: previousSnapshot?.data(),
    };

    transaction.set(targetRef, {
      uid,
      username: username,
      email: user.email,
      pendingEmail: pendingEmail?.trim() || null,
    });

    if (previousRef && previousRef.path !== targetRef.path &&
        previousSnapshot?.get("uid") === uid) {
      transaction.delete(previousRef);
    }
    return state;
  });

  try {
    await getAuth().updateUser(uid, {displayName: request.data.username.trim()});
  } catch (error) {
    await db.runTransaction(async (transaction) => {
      const currentTarget = await transaction.get(targetRef);

      if (currentTarget.get("uid") !== uid) return;
      if (previousRef?.path === targetRef.path && previousState.targetExisted) {
        transaction.set(targetRef, previousState.targetData);
      } else if (previousState.targetExisted) {
        transaction.set(targetRef, previousState.targetData);
      } else {
        transaction.delete(targetRef);
      }

      if (previousRef && previousRef.path !== targetRef.path &&
          previousState.previousData) {
        transaction.set(previousRef, previousState.previousData);
      }
    });
    throw error;
  }

  return {username};
});

exports.removeUsername = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in to remove your username.");
  }

  const matches = await usernames.where("uid", "==", uid).get();
  if (matches.empty) return {removed: false};

  const batch = db.batch();
  for (const document of matches.docs) {
    batch.delete(document.ref);
  }
  await batch.commit();
  return {removed: true};
});
