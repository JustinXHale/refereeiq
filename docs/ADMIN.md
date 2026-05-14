# Admin console

Operators can change **feature flags**, **Sofia/challenge prompts**, **AI provider settings**, and the **admin UID allowlist** from inside the RefereeIQ app (drawer → **Admin**).

All writes go through **Firebase Callable Functions** using the Admin SDK. Regular Firestore rules keep **`app_config`** read-only for clients.

## Bootstrap (first-time)

1. In [Firebase Console](https://console.firebase.google.com) → **Firestore**, create document **`app_config/admins`**.
2. Set field **`uids`** to an **array** containing your Firebase Auth UID (string). Example:

   ```text
   uids: ["YOUR_UID_HERE"]
   ```

   Find your UID under **Authentication → Users**.

3. Deploy callable functions (includes `adminGetConfig`, `adminUpdateFeatures`, etc.):

   ```bash
   firebase deploy --only functions:adminGetConfig,functions:adminUpdateFeatures,functions:adminUpdatePrompts,functions:adminUpdateAi,functions:adminAddAdmin,functions:adminRemoveAdmin
   ```

   Or deploy all functions: `firebase deploy --only functions`

4. Sign in to the app; **Admin** should appear in the drawer. Open it to add other admins by UID (max 20).

## Security notes

- Do **not** store API keys in **`app_config/ai`** — only **`secretName`** references (keys stay in Secret Manager).
- Removing yourself as admin closes the console; ensure at least one UID always remains (`adminRemoveAdmin` blocks removing the last admin).

## Related files

- Callables: [`functions/handlers/admin.js`](../functions/handlers/admin.js)
- Flutter UI: [`lib/screens/admin_console_screen.dart`](../lib/screens/admin_console_screen.dart), [`lib/services/admin_service.dart`](../lib/services/admin_service.dart)
- Allowlist doc: **`app_config/admins`** `{ uids: string[] }`
