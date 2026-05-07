# Pre-Release Manual Checks — Reference Guide

Detailed guidance for every item in Phase 2 of the pre-release checklist.

**Product:** RefereeIQ — rugby laws assistant with Ask Sofia (chat), optional Challenge/Sources tabs (feature flags), profile, settings, and query history.

---

## 2a. Onboarding & account

**Why this matters:** Users must reach the home experience without crashes across welcome, email auth, verification, and profile completion.

**How to test:**

1. Fresh install (or clear app data).
2. Complete the flow you ship (e.g. Welcome → Sign up or Log in → Verify email if applicable → Complete profile → Home).
3. Sign out from Profile or Settings, then sign in again.
4. Confirm no stuck screens after rotating the device mid-flow.

---

## 2b. Ask Sofia (critical path)

**Why this matters:** Chat with Sofia is the primary value; failures here block release.

**How to test:**

1. From Home, open **Ask Sofia** (default tab).
2. Send a short rugby-law question; wait for a complete assistant reply (including streaming if enabled).
3. Scroll the conversation; open **Favorites** / saved flows if present and confirm they work.
4. Start a new thread or clear context per your UX — confirm state resets without crashes.

---

## 2c. Sources & documents (when enabled)

**Why this matters:** Feature-flagged tabs must not regress when Remote Config turns them on.

**How to test:**

1. With **Sources** enabled: open the tab, search or browse, open a markdown law/doc and a PDF if applicable.
2. Confirm back navigation returns to the expected screen (list vs reader).
3. With **Challenge** enabled: complete one challenge path without errors (tabs vary by implementation).

---

## 2d. Drawer & secondary routes

**Why this matters:** Settings, profile, and history are common support escalations.

**How to test:**

1. Open the navigation drawer from Home.
2. Visit **Profile**, **Settings**, and **Query history** (routes `/profile`, `/settings`, `/query-history`).
3. Change a setting (e.g. theme-related or preference), navigate away, return — value persists if designed to.
4. Android system back and iOS swipe-back exit modals/full-screen pages without a blank scaffold.

---

## 2e. Network resilience

**Android — throttle:**

- Developer Options → Networking → Simulate cellular network → **3G** (or equivalent).

**iOS — Network Link Conditioner:**

- Settings → Developer → Network Link Conditioner → **3G**
  *(Developer menu appears after enabling via Xcode on device.)*

**Test scenarios:**

| Scenario | Expected result |
|----------|-----------------|
| 3G: send Sofia message | Reply eventually arrives or a clear error/retry — no silent hang |
| Drop Wi‑Fi mid-reply | Graceful failure or retry messaging; no crash |
| Airplane mode on launch | Error or empty state that explains offline; app usable again when online |

---

## 2f. Loading / error / empty states

Walk through deliberately:

- **Empty chat:** first message only — placeholders readable.
- **Bad backend / API error:** confirm user-visible error (snackbar/dialog), no infinite spinner.
- **Invalid navigation:** deep link or manual route to missing content — friendly error, no red screen.
- **Spinners:** every loading indicator dismisses after success or failure.

---

## 2g. UI overflow + accessibility

**Large font (Android):** Settings → Accessibility → Font size → maximum.

**Large font (iOS):** Settings → Accessibility → Display & Text Size → Larger Text → maximum.

**Small screen:** Prefer a **360×640** logical resolution device or emulator.

**What to check:**

- Home **AppBar** title and tab labels do not clip.
- Ask Sofia input and send affordance remain reachable with keyboard open.
- Drawer labels and list tiles wrap without `RenderFlex` overflow errors.

---

## 2h. Navigation & deep links

**In-app:** Back from Settings/Profile returns to Home (or prior route) without losing stack oddly.

**Deep links:** If you add URL schemes or App Links later, retest cold/warm/terminated launches here. Until then, skip custom URL tests.

---

## 2i. Push notifications (FCM)

RefereeIQ initializes Firebase Messaging. Validate only what you actually send:

**If you use marketing or transactional pushes:**

1. Trigger a test notification from Firebase or your backend.
2. Foreground: banner or local notification path works without duplicate spam.
3. Background / terminated: tap opens the app to the intended screen (configure payloads accordingly).

**If pushes are unused:** Confirm app still launches and does not crash when FCM token refresh runs (check logs once).

---

## 2j. Performance

**Cold start:** Target ≤ ~3 s to interactive UI on a mid-range device.

**Android logcat (example):**

```text
ActivityManager: Displayed com.refereeiq.refereeiq/.MainActivity: +Xs
```

**Scroll:** Scroll long Sofia transcripts and Sources lists — no sustained jank (Flutter DevTools Performance if unsure).

**Memory:** Open Ask Sofia → navigate away → return several times; heap should not climb without bound.

---

## 2k. Final signed-build smoke test

**Android:**

```bash
flutter build appbundle --release
```

Install on device (bundletool or Play internal track).

**iOS:** Xcode → Archive → TestFlight or Ad Hoc.

**Checklist:**

- [ ] `version` / build number match store listing (`pubspec.yaml`).
- [ ] No debug banner (`debugShowCheckedModeBanner` stays false).
- [ ] Firebase Crashlytics (if enabled) shows sessions for the new version.
- [ ] Smoke: log in → Ask Sofia question → open drawer → Settings → back → Home.
