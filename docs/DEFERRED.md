# Deferred Items

Things intentionally skipped during the v1.0.0 cleanup sprint. Revisit before v1.1 or when addressing scale/compliance needs.

---

## Implemented (2026-05)

### Account deletion — subcollection/collection cascade

**Done:** Cloud Function `cleanupUserDataOnProfileDeleted` (`functions/handlers/userCleanup.js`) runs on Firestore `users/{uid}` delete and removes:

- `query_history` where `uid` matches
- `challenge_attempts` where `uid` matches
- `sofia_chat_cache` where `uid` matches
- `leaderboard/{uid}`
- Storage object `profile_pics/{uid}.jpg` and any `profile_pics/{uid}/` prefix objects

Client flow in `auth_service.dart` still deletes the profile doc first; this trigger completes server-side cleanup.

---

### Firestore Security Rules

**Done:** Rules audited and grouped; explicit deny-all for backend-only collections (`incident_cache`, `sofia_chat_cache`, `question_bank`). Existing client rules unchanged in intent: own-data reads/writes, CF-only writes where applicable.

---

### Smart caching + model routing (Sofia chat)

**Done:**

- `getAIProvider(secretValues, { chatTier: 'simple' | 'full' })` in `functions/services/aiProvider.js`
- Firestore-configurable `providers.{active}.simpleChatModel` (default `gpt-4o-mini` for OpenAI)
- Heuristic tier: `full` when clarification/law augmentation applies, multi-turn, or long prompts; else `simple`
- `sofia_chat_cache` keyed by `sha256(sofia_v1::normalizedQuery)` per user doc `${uid}_${hash}`; cache hit skips model call and logs `metadata.cache_hit: true` on `query_history`

---

## Backend / Cloud Functions

*(Account deletion cascade moved to “Implemented” above.)*

---

## iOS Firebase Setup (Manual — BLOCKING for iOS build)

**Status:** Completed in-repo (`GoogleService-Info.plist`, URL scheme, Xcode project). Keep plist in sync with Firebase Console when rotating apps.

---

## Video Clip Analysis

**Priority:** Post-1.0 / v3-style (after user research confirms which scenarios need it)

**Concept:** User pastes a YouTube URL or uploads a short clip, marks the relevant timestamp, and asks "what's the call?" The backend trims to ~30 seconds, extracts frames (~1/sec), and sends them alongside the incident description to a vision-capable model.

**Implementation outline:**
1. Flutter: video URL input + timestamp marker in `chat_tab.dart` incident flow
2. Cloud Function: extract frames using `ffmpeg` on Cloud Run, or use YouTube Data API to pull a clip window
3. Send frames as base64 images alongside text to vision model
4. Best models today: GPT-4o (frame-by-frame), Gemini 2.0 Flash (native video input, no frame extraction)

**Why wait:** Need real user data to know which incident types actually need video clarification. Gemini native video support may also mature before building.

---

## Claude / Anthropic SDK Integration

**Priority:** When needed (Anthropic API is NOT OpenAI-compatible)

**Current state:** `ANTHROPIC_API_KEY` not yet set as a Firebase Secret. The `aiProvider.js` provider abstraction is ready to add it, but Anthropic requires its own SDK (`@anthropic-ai/sdk`) — can't just point the OpenAI SDK at Anthropic's endpoint.

**Implementation outline:**
1. `npm install @anthropic-ai/sdk` in `functions/`
2. Add `type: 'anthropic'` to provider config in Firestore
3. In `getAIProvider()`: when `activeProvider === 'anthropic'`, return an Anthropic client with a normalized wrapper that matches the OpenAI response shape handlers expect
4. `firebase functions:secrets:set ANTHROPIC_API_KEY` + redeploy

---

## Self-Hosted / Fine-Tuned Model on Cloud Run

**Priority:** Future / v3 (especially relevant when video analysis is added)

**Concept:** Host a fine-tuned open-source vision model on Cloud Run that only knows rugby. Rugby laws change infrequently — fine-tune once per law edition, serve indefinitely. Much cheaper per-query than commercial APIs at scale, and more accurate on rugby-specific scenarios.

**Why it's a moat:** A model trained specifically on rugby incidents, laws, and referee decisions would outperform general models on edge cases. Add labeled video clips during fine-tuning and you have a genuinely differentiated product.

**Implementation outline:**
1. Serve model via [Ollama](https://ollama.ai) or [vLLM](https://github.com/vllm-project/vllm) in a Cloud Run container — both expose OpenAI-compatible endpoints
2. Add Cloud Run URL as `baseURL` in `app_config/ai.providers.selfhosted`
3. No code changes — just another provider entry in Firestore
4. Fine-tune on: World Rugby law text, labeled incident Q&As, referee decision datasets

---

## Android R8 / Dart Obfuscation (Phase 7 store build)

**File:** `android/app/build.gradle.kts`
**Problem:** `isMinifyEnabled = false` — Java/Kotlin wrapper not shrunk. Dart-level obfuscation not yet verified.
**Fix (at store build time):**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/
```
Keep `isMinifyEnabled = false` for the Android layer (Flutter default; enabling R8 risks breaking Firebase/plugin classes without full ProGuard rules).
