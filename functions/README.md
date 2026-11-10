# Username sign-in functions

The callable functions keep username-to-email records on the server. Deploy them
from the repository root with:

```powershell
firebase deploy --only functions
```

The Firebase CLI must be signed in and pointed at the `carb-crunchers` project.
Cloud Functions deployment may require the project to use the Blaze billing plan.

Before deploying, merge these denies into the existing Firestore rules. Do not
replace the project's other collection rules with these matches:

```text
match /username_index/{username} {
  allow read, write: if false;
}
match /_username_lookup_limits/{ipHash} {
  allow read, write: if false;
}
```

The functions use the Admin SDK, so they can manage these records despite the
client rules. Username lookup is rate-limited per source IP and resolves the
account's current email through Firebase Authentication, so a pending,
unverified email change is never used for sign-in.

Existing accounts do not need a username record beforehand. The first
successful **Create username** action creates it. The function derives account
identity from the signed-in Firebase Authentication token; it does not ask the
user to re-enter their email. Deploy the functions before using username
creation or username sign-in in the app.
