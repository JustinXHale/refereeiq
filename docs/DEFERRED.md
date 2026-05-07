# Deferred Items

Things intentionally skipped during the v1.0.0 cleanup sprint. Revisit before v1.1 or when addressing scale/compliance needs.

---

## Backend / Cloud Functions

### Account deletion — subcollection cascade
**File:** `lib/services/auth_service.dart` → `deleteAccount()`
**Problem:** Deleting a user's `users/{uid}` document does NOT delete subcollections (`query_history`, `challenge_attempts`) or Firebase Storage (`profile_pics/{uid}`). Orphaned data accumulates.
**Fix:** Write a Firebase Cloud Function (`onDocumentDeleted` trigger on `users/{uid}`) that:
1. Deletes `users/{uid}/query_history` (batch)
2. Deletes `users/{uid}/challenge_attempts` (batch)
3. Deletes `storage/profile_pics/{uid}/` folder

---

## Firestore Security Rules

**File:** `firestore.rules`
**Problem:** Current rules may allow over-broad `list` access on some collections. Not fully audited.
**Fix:** Full rule review — ensure:
- Users can only read/write their own `users/{uid}` document
- `leaderboard` is readable by all, writable only by Cloud Functions or authenticated users for their own entry
- `app_config/features` is read-only for all users, writable only by admin

---

## iOS Firebase Setup (Manual — BLOCKING for iOS build)

**Problem:** `GoogleService-Info.plist` is absent from `ios/Runner/`. Firebase will crash on iOS launch.
**Fix (must do before any iOS build):**
1. Go to Firebase Console → Project Settings → iOS app
2. Download `GoogleService-Info.plist`
3. In Xcode, drag it into `ios/Runner/` (ensure "Copy items if needed" is checked)
4. Add `REVERSED_CLIENT_ID` URL scheme:
   - Open `ios/Runner/Info.plist`
   - Add a `CFBundleURLTypes` entry with the `REVERSED_CLIENT_ID` value from the plist

---

## Push Notifications — Persistence vs. Permission

**File:** `lib/screens/settings_screen.dart`
**Problem:** The notification toggle persists the user's preference in `SharedPreferences`, but does not actually call `firebase_messaging.requestPermission()` or update the FCM subscription. The toggle is cosmetic only.
**Fix:** Wire toggle to:
1. `FirebaseMessaging.instance.requestPermission()` when enabling
2. Subscribe/unsubscribe from a topic or update Firestore user doc with `notificationsEnabled` field
3. Cloud Function reads this flag before sending targeted pushes

---

## Profile Image Upload

**File:** `lib/screens/complete_profile_screen.dart`, `lib/screens/profile_screen.dart`
**Problem:** `_imageFile` is picked from the gallery but never uploaded to Firebase Storage. `photoURL` in Firestore stays as the Google/auth provider URL only.
**Fix:** After picking image, upload to `profile_pics/{uid}/avatar.jpg` via `firebase_storage`, then update `users/{uid}.photoURL` with the download URL.

---

## Conversation Detail — Timestamp Display

**File:** `lib/screens/conversation_detail_screen.dart`
**Problem:** Timestamp field on chat messages is displayed as raw UTC string with no locale formatting.
**Fix:** Format with `DateFormat.yMMMd().add_jm()` from the `intl` package, converting from UTC to device local time.

---

## Daily Challenge — Timezone

**File:** `lib/screens/daily_challenge_tab.dart` → `_nextDropLabel()`
**Problem:** Drop time is calculated against device local time. Users outside Central Time will see wrong countdown labels (e.g., "Next drop at 8:30 PM" when it's already past).
**Fix:** Convert server schedule (8:30 AM / 8:30 PM CT) to UTC, then compare against `DateTime.now().toUtc()`, and display in device local time using `intl`.

---

## flutter_markdown — Discontinued Package

**File:** `pubspec.yaml`
**Package:** `flutter_markdown: ^0.7.7+1`
**Problem:** `flutter pub get` warns this package is discontinued; replacement is `flutter_markdown_plus`.
**Fix:** Run `flutter pub add flutter_markdown_plus`, replace all `import 'package:flutter_markdown/flutter_markdown.dart'` references, test rendering of AI responses in `chat_tab.dart`.

---

## Android R8 / Dart Obfuscation (Phase 7 store build)

**File:** `android/app/build.gradle.kts`
**Problem:** `isMinifyEnabled = false` — Java/Kotlin wrapper not shrunk. Dart-level obfuscation not yet verified.
**Fix (at store build time):**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/
```
Keep `isMinifyEnabled = false` for the Android layer (Flutter default; enabling R8 risks breaking Firebase/plugin classes without full ProGuard rules).
