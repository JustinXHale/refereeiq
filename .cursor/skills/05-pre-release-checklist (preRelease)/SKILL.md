---
name: pre-release-checklist
description: Run a structured pre-release quality sweep for the RefereeIQ Flutter app before submitting to the App Store or Play Store. Use when the user says "pre-release", "prepare a release", "ready to ship", "release checklist", or "submit to the store". Runs automated checks first, then guides through manual device testing. Covers static analysis, tests, Android lint, permissions, network resilience, UI overflow, back navigation, Firebase messaging where used, performance, and a signed-build smoke test.
---

# Pre-Release Checklist — RefereeIQ

Two phases: **automated** (run once, fix before continuing) then **manual** (device testing).

## Phase 1 — Automated Checks

Run the script. Fix all failures before moving to Phase 2.

```bash
bash .agents/pre-release-checklist/scripts/run_automated_checks.sh
```

The script runs in order and stops on the first failure:
1. `flutter analyze` — static analysis
2. `flutter test` — full unit + widget suite
3. `./gradlew lint` — Android manifest/API compliance
4. OWASP security scanners (if `.agents/owasp-mobile-security-checker/` exists)

Output files produced: `android_lint_report.html`, `owasp_*.json` (review for CRITICAL/HIGH).

## Phase 2 — Manual Device Tests

Work through each section. Test on **one real Android device (API 34+) and one real iOS device** — not emulator/simulator only.

For detail on each check, see [references/manual_checks.md](references/manual_checks.md).

### 2a. Onboarding & account
- [ ] Fresh install completes welcome → auth → home (and verify-email / profile if applicable)
- [ ] Sign out and sign back in without crash

### 2b. Ask Sofia (critical path)
- [ ] Send a message; receive a full reply (streaming OK)
- [ ] Scroll transcript; favorites/saved flows if applicable

### 2c. Sources & Challenge (when feature flags on)
- [ ] Sources: browse/open markdown or PDF; back navigation correct
- [ ] Challenge: complete one flow without errors

### 2d. Drawer & secondary screens
- [ ] Profile, Settings, Query history open and return cleanly

### 2e. Network resilience
- [ ] Throttled 3G: Sofia still responds or shows clear error
- [ ] Airplane mode / offline: no hang; recovery when back online

### 2f. Loading / error / empty states
- [ ] Empty chat and error paths show intentional UI, no stuck spinners

### 2g. UI overflow + accessibility
- [ ] Largest system font: no clipped text or `RenderFlex` overflow on Home and Ask Sofia
- [ ] Smallest supported width (~360 logical): tabs and drawer usable

### 2h. Navigation
- [ ] Android back / iOS swipe-back from secondary screens returns correctly

### 2i. Push notifications (if used)
- [ ] Test notification received; tap opens expected screen (foreground/background/terminated)

### 2j. Performance
- [ ] Cold start acceptable on low-end device
- [ ] Scroll long chat/sources lists without sustained jank

### 2k. Final signed-build smoke test
- [ ] Release **AAB/IPA** installed (not debug-only)
- [ ] Smoke: login → Ask Sofia → drawer → Settings → Home
- [ ] Crashlytics sessions for new build (if enabled)
- [ ] Version name/build match store listing

## Outcome

After all boxes checked:

- ✅ All automated checks pass
- ✅ All manual boxes ticked on real devices
- ✅ No CRITICAL/HIGH OWASP findings unresolved

→ Safe to submit to Play Store / App Store.

## Failing a check

- **Automated failure**: fix before any manual testing — do not skip.
- **Manual failure**: file it as a bug, do not ship until fixed or explicitly accepted as known limitation.
