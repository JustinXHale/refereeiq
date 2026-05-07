---
name: android-app-prd
description: |
  Android App PRD and Pre-Build Checklist Framework. Use this skill whenever you are helping create an Android app PRD, planning an Android app release, or preparing for Google Play Store submission. This applies to any app project (not websites) where the user needs: app requirements documentation, pre-build checklists, Play Store compliance verification, or release workflow guidance. Trigger on phrases like "Android app PRD", "prepare Android app for Play Store", "Android app checklist", "build Android app for release", "Android app requirements", or any discussion of launching an Android app on Google Play.
---

# Android App PRD & Pre-Build Checklist

This skill guides you through the complete Android app development and release lifecycle. Use it whenever working on Android app PRDs, pre-build preparation, or Google Play Store submissions.

## When to Use This Skill

Trigger this skill for:
- Creating or refining an Android app PRD (Product Requirements Document)
- Preparing an app for Google Play Store release
- Building pre-release checklists for Android projects
- Compliance verification before submission
- Release workflow planning and execution
- Data safety and privacy compliance documentation
- App store asset preparation

**Do NOT use for:** Website projects, iOS/web-only apps, or generic software documentation unrelated to Android releases.

## Core Workflow: 13-Step Android Release Framework

### Section 1: App Identity (Step 1)

**Purpose:** Define the app's core identity for Play Store and internal tracking.

**Deliverables:**
- App name (primary + any marketing variants)
- Unique package name (reverse domain notation: `com.company.app`)
- Version code (integer, auto-incremented per release)
- Version name (semantic versioning: 1.0.0, 1.0.1, etc.)
- App icon (512x512 PNG, RGB, no transparency for background)

**Checklist:**
- [ ] App name is unique on Play Store (verify via search)
- [ ] Package name is unique and follows naming convention
- [ ] Version code incremented (always higher than previous release)
- [ ] Version name follows semantic versioning
- [ ] Icon provided in correct format and dimensions

---

### Section 2: Platform Configuration (Step 2)

**Purpose:** Configure Android SDK targets and build requirements.

**Deliverables:**
- Minimum SDK version (recommend: API 24/Android 7.0 for broad reach)
- Target SDK version (must be latest Google Play requirement, currently API 35+)
- Release signing keystore (created and backed up securely)
- Build configuration (release vs. debug)

**Checklist:**
- [ ] Min SDK defined based on target audience
- [ ] Target SDK = latest Google Play requirement
- [ ] Keystore file created and securely stored
- [ ] Keystore password documented (encrypted, not in source control)
- [ ] Build variants configured (debug/release)
- [ ] Proguard/R8 rules configured for obfuscation

**Important:** Target SDK must comply with Google Play's current requirement (update yearly). As of 2024, this typically means API 34+.

---

### Section 3: Permissions Planning (Step 3)

**Purpose:** Define only necessary permissions with clear justification.

**Deliverables:**
- Complete list of required permissions
- Justification for each permission (tied to specific features)
- Sensitive permission strategy (camera, location, contacts, etc.)
- Runtime permission handling for API 23+

**Permission Categories:**
- **Normal permissions:** Automatically granted (e.g., INTERNET)
- **Dangerous permissions:** Require user runtime approval (e.g., CAMERA, LOCATION, READ_CONTACTS)
- **Special permissions:** Require special handling (e.g., SYSTEM_ALERT_WINDOW, INSTALL_UNKNOWN_APPS)

**Checklist:**
- [ ] Only essential permissions listed
- [ ] Justification documented for each permission
- [ ] No excessive "scary" permissions that hurt install rates
- [ ] Runtime permissions implemented for API 23+ (dangerous permissions)
- [ ] Permission rationale shown to users before requesting
- [ ] Graceful degradation if permission denied

**Example Table:**
| Permission | Category | Feature | Justification |
|-----------|----------|---------|---------------|
| INTERNET | Normal | API calls, Firebase | Core functionality |
| CAMERA | Dangerous | Photo capture | Feature request only |
| ACCESS_FINE_LOCATION | Dangerous | Location tagging | Optional, user consent |

---

### Section 4: Data & Privacy (Step 4)

**Purpose:** Establish privacy-first data practices and compliance.

**Deliverables:**
- Public Privacy Policy URL (hosted on accessible domain)
- Data collection inventory (what data, from where, why)
- Third-party services list (Firebase, Ads networks, Analytics)
- Encryption strategy (HTTPS for transit, local storage encryption)
- Data deletion/retention policy
- User account deletion mechanism (if accounts exist)

**Checklist:**
- [ ] Privacy Policy URL live and accessible
- [ ] Privacy Policy covers all data practices
- [ ] Data collection is minimal and justified
- [ ] Third-party services listed with links to their privacy policies
- [ ] All API communication over HTTPS
- [ ] Sensitive data encrypted at rest (use Android Keystore)
- [ ] Data deletion works end-to-end (backend + app)
- [ ] User account deletion is self-service or support-assisted
- [ ] Firebase/Analytics terms accepted and configured
- [ ] Data retention period defined

**Privacy Policy Must Include:**
- Data types collected (name, email, location, device ID, etc.)
- Purpose of collection
- Third-party sharing practices
- User rights (access, deletion, portability)
- Contact information for privacy inquiries
- Effective date and version control

---

### Section 5: Mandatory App Screens (Step 5)

**Purpose:** Ensure legally required and user-support screens are present.

**Deliverables:**
- In-app Privacy Policy screen (WebView or native)
- Support/Contact page (email, web form, or help center link)
- Account deletion interface (if login exists)
- About page (app version, attribution, changelog)

**Checklist:**
- [ ] Privacy Policy accessible within 1 tap from main menu
- [ ] Support contact method clearly visible
- [ ] Support email monitored and responsive
- [ ] Account deletion initiates full backend cleanup
- [ ] Account deletion confirmation sent to user email
- [ ] About/Info page displays app version matching Play Store
- [ ] Changelog visible to users (optional but recommended)

---

### Section 6: Google Play Data Safety (Step 6)

**Purpose:** Declare data practices transparently in Play Console.

**Deliverables:**
- Data types declaration (what's collected)
- Data sharing declaration (where data goes)
- Encryption declaration (transit vs. rest)
- Data safety form completion in Play Console

**Data Types to Declare:**
- Personal info (name, email, phone, address)
- Financial info (payment methods, transaction history)
- Location data (precise, approximate)
- Photos and videos
- Audio (recordings, transcriptions)
- Files (documents, downloads)
- Calendar/Contacts
- App activity (usage, interactions, crash logs)
- Device IDs (IMEI, AAID, serial number)

**Checklist:**
- [ ] All collected data types declared in Play Console
- [ ] Encryption marked for transit (HTTPS: Yes/No)
- [ ] Encryption marked for rest (Yes/No + method)
- [ ] Data sharing declared for each third party
- [ ] Purpose of collection documented
- [ ] Data retention policy stated
- [ ] Form submitted and reviewed by compliance team

**Important:** Inaccurate data safety declarations can result in app removal. Review carefully before submission.

---

### Section 7: App Stability (Step 7)

**Purpose:** Ensure production quality and error resilience.

**Deliverables:**
- Zero critical crashes in testing
- Offline mode graceful handling
- API failure recovery logic
- Debug logs removed from release builds

**Checklist:**
- [ ] No Force Close / ANR (Application Not Responding) issues
- [ ] Crash reporting tool configured (Firebase Crashlytics)
- [ ] All crash logs reviewed and fixed
- [ ] Offline mode detected and communicated to user
- [ ] Network errors retry with exponential backoff
- [ ] API timeouts handled gracefully
- [ ] Error messages user-friendly (not raw server responses)
- [ ] Debug logs removed (use BuildConfig.DEBUG checks)
- [ ] ProGuard/R8 minification tested on release build
- [ ] Testing performed on minimum SDK device

**Common Stability Issues:**
- Memory leaks in activities/fragments
- Network requests on main thread
- Unhandled null pointer exceptions
- Missing error handling in API calls
- Infinite loops or heavy background processes
- Inadequate database indexes causing UI lag

---

### Section 8: Ads & Monetization (Step 8 - If Applicable)

**Purpose:** Ensure ads comply with policy and user experience standards.

**Deliverables:**
- Ad placement strategy (native, banner, interstitial, rewarded)
- Ad network policies compliance (Google AdMob, etc.)
- Clear ad labeling in UI
- No misleading ad formats

**Checklist:**
- [ ] Ad network account created and policies reviewed
- [ ] Ads clearly labeled as "Ad" or "Sponsored"
- [ ] No ads disguised as UI buttons or content
- [ ] Ad frequency reasonable (no ad spam)
- [ ] Rewarded ads work correctly (reward only after completion)
- [ ] Click-through tracking verified
- [ ] No prohibited ad categories (gambling, adult, violence, etc.)
- [ ] Ad policy compliance verified with network
- [ ] Test ads used during development (not live ad IDs)
- [ ] Monetization strategy aligned with user expectations

**Ad Policies:**
- Never hide close buttons
- Never use misleading ad sizes
- Never auto-play audio ads
- Respect user preferences (personalized vs. non-personalized)
- Include opt-out mechanisms where applicable

---

### Section 9: Play Store Assets (Step 9)

**Purpose:** Create professional store presence with high-quality visuals.

**Required Assets:**

1. **App Icon** (512x512 PNG)
   - High quality, recognizable at small sizes
   - RGB, square (no transparency outside bounds)
   - Unique design that stands out in store

2. **Feature Graphic** (1024x500 PNG)
   - Landscape image showcasing app value
   - Text overlay explaining key feature
   - Professional, visually appealing

3. **Screenshots** (minimum 2, maximum 8)
   - 1080x1920 or 1440x2560 (or both)
   - Show key app features sequentially
   - Include brief captions (10-30 words each)
   - Text should be readable at thumbnail size

4. **Descriptions**
   - Short description: max 80 characters (headline)
   - Full description: 4000 characters max
   - Include keyword mentions for discoverability
   - Highlight unique value proposition

5. **Category & Tags**
   - Primary category (e.g., Productivity, Games, Utilities)
   - Optional secondary category
   - Relevant search tags

**Content Guidelines for Descriptions:**
- Lead with the main benefit (not feature list)
- Use bullet points for key features
- Include target audience
- End with strong call-to-action
- Avoid superlatives; be honest
- Mention any special permissions (e.g., "requires location access")

**Checklist:**
- [ ] App icon professional and on-brand
- [ ] Feature graphic eye-catching and clear
- [ ] Minimum 2 screenshots provided
- [ ] Screenshots demonstrate core features
- [ ] Captions under each screenshot
- [ ] Short description compelling (max 80 chars)
- [ ] Full description complete and keyword-rich
- [ ] Category and tags relevant
- [ ] All assets in correct format and dimensions
- [ ] No copyrighted third-party images used

---

### Section 10: Review Access (Step 10)

**Purpose:** Facilitate Play Store review team testing.

**Deliverables:**
- Test account credentials (if app requires login)
- Access instructions
- Test data setup documentation

**Checklist:**
- [ ] Test account created and credentials provided
- [ ] Test account has sufficient permissions (not admin-only features)
- [ ] Test account email in Play Console's tester list
- [ ] No test-only features (all features enabled)
- [ ] In-app purchases testable (use sandbox)
- [ ] API keys non-production (if applicable)
- [ ] Database populated with sample data for testing
- [ ] Instructions document uploaded to Play Console
- [ ] Support contact provided for review team questions

**Example Instructions Document:**
```
Test Account Access:
Email: test.reviewer@example.com
Password: [provided separately]

Testing Steps:
1. Sign in with provided credentials
2. Complete onboarding flow
3. Trigger push notification (Settings > Send Test Notification)
4. Make test in-app purchase (use Google Play sandbox)
5. Delete account (Settings > Account > Delete)
```

---

### Section 11: Build Output (Step 11)

**Purpose:** Generate production-ready release artifacts.

**Deliverables:**
- Android App Bundle (AAB) format
- Signed with release keystore
- ProGuard/R8 obfuscation applied
- Version aligned with Play Store
- Build successfully tested

**Checklist:**
- [ ] Build variant set to "release"
- [ ] Signing configuration uses release keystore
- [ ] AAB generated (not APK, unless legacy support needed)
- [ ] ProGuard/R8 rules applied
- [ ] Build size optimized (check AndroidSize Analyzer)
- [ ] Manifest version code/name updated
- [ ] Localization tested (if multilingual)
- [ ] Resources optimized (image compression, removal of unused resources)
- [ ] Signing verified (jarsigner or bundletool)

**AAB vs. APK:**
- **AAB (recommended):** Google Play generates optimized APKs per device; reduces download size
- **APK:** Monolithic; only use if targeting legacy Play Store or direct distribution

**Build Command Example:**
```bash
./gradlew bundleRelease
# Output: app/release/app-release.aab
```

---

### Section 12: Release Flow (Step 12)

**Purpose:** Staged rollout strategy to minimize risk.

**Phases:**

**Phase 1: Internal Testing** (1-2 days)
- [ ] Test on physical devices (min + target SDK)
- [ ] Test on various screen sizes
- [ ] Basic functionality verified
- [ ] Critical bugs fixed

**Phase 2: Closed Testing** (3-5 days)
- [ ] Create closed test track in Play Console
- [ ] Invite 10-50 trusted users (friends, team, community)
- [ ] Gather feedback and crash reports
- [ ] Fix critical issues
- [ ] Monitor crash logs via Crashlytics

**Phase 3: Production Release**
- [ ] Staged rollout: 5% → 25% → 50% → 100% (over 2-7 days)
- [ ] Monitor crash rates and user reviews
- [ ] Set rollback strategy (if crashes spike)
- [ ] Full rollout once stable
- [ ] Monitor reviews, ratings, and support requests

**Checklist:**
- [ ] Release notes prepared
- [ ] Privacy Policy finalized
- [ ] Data Safety form submitted
- [ ] All assets uploaded to Play Console
- [ ] Internal testing completed
- [ ] Closed testing users notified
- [ ] Feedback reviewed
- [ ] Release notes include version highlights
- [ ] Support team prepared for user inquiries
- [ ] Monitoring dashboards set up (Crashlytics, Analytics)

---

### Section 13: Policy Compliance (Step 13)

**Purpose:** Ensure app meets Google Play policy requirements.

**Core Policies:**

**No Copyright Violations**
- [ ] No unauthorized copyrighted music, images, or content
- [ ] All third-party assets properly licensed
- [ ] Attribution provided where required
- [ ] Trademark usage compliant

**No Impersonation**
- [ ] App does not impersonate Google, Android, or other brands
- [ ] App name doesn't violate trademark
- [ ] App doesn't mimic official system apps
- [ ] Icons don't copy official brand logos

**Functionality Accuracy**
- [ ] App does what the description promises
- [ ] No misleading feature claims
- [ ] No fake functionality or dummy screens
- [ ] Screenshots match actual app behavior

**Additional Policy Checks**
- [ ] No malware or security exploits
- [ ] No sexual content or adult material (unless rated)
- [ ] No hate speech or discrimination
- [ ] No illegal activity facilitation
- [ ] No excessive ads or aggressive monetization
- [ ] No fake or misleading reviews
- [ ] No clickbait titles or descriptions

**Checklist:**
- [ ] Google Play Policy review completed
- [ ] Content rating questionnaire filled (IARC)
- [ ] Ratings: Violence, Language, Ads, Mature content declared
- [ ] All policies acknowledged and confirmed
- [ ] No red-flag issues identified
- [ ] App store listing consistent with app behavior
- [ ] Support email functional and monitored
- [ ] Privacy Policy up-to-date and accurate

**Common Rejection Reasons:**
- Vague or misleading description
- Aggressive ads or monetization
- Crashes or instability on test devices
- Missing Privacy Policy
- Inaccurate data safety declaration
- Intellectual property violations
- Incomplete or dummy functionality

---

## Output Template: Android App PRD

When creating an Android app PRD, structure it as:

```markdown
# [App Name] - Android App PRD

## 1. App Identity
- App Name: [Name]
- Package Name: [com.example.app]
- Version: 1.0.0 (Code: 1)
- Icon: [Link/Status]

## 2. Platform Configuration
- Min SDK: API 24
- Target SDK: API 35
- Keystore: [Status]

## 3. Permissions
| Permission | Justification |
|-----------|---------------|
| INTERNET | API calls |
| CAMERA | Photo capture |

## 4. Data & Privacy
- Privacy Policy: [URL]
- Data Collected: [List]
- Third-party Services: [List]
- Encryption: HTTPS + Keystore

## 5. Mandatory Screens
- Privacy Policy in-app: ✓
- Support page: ✓
- Account deletion: ✓

## 6. Data Safety Declaration
- Collected types: [Declared]
- Encryption: [Transit + Rest]

## 7. Stability
- Crashes: 0
- Offline handling: ✓
- Error recovery: ✓

## 8. Monetization (if applicable)
- Ad network: [Network]
- Ad policy: [Status]

## 9. Play Store Assets
- Icon: 512x512 ✓
- Feature graphic: 1024x500 ✓
- Screenshots: 8 ✓

## 10. Review Access
- Test account: [Status]

## 11. Build
- AAB generated: ✓
- Signed: ✓

## 12. Release Plan
- Internal: [Date]
- Closed: [Date]
- Production: [Date]

## 13. Policy Compliance
- Content rating: [IARC Status]
- Policies reviewed: ✓
```

---

## Quick Validation Checklist

Use this before hitting "Submit" to Play Store:

- [ ] Version code incremented
- [ ] Target SDK = latest requirement
- [ ] All 13 steps addressed
- [ ] AAB signed and tested
- [ ] Screenshots match app (no outdated UI)
- [ ] Privacy Policy live and complete
- [ ] Data Safety form accurate
- [ ] No debug logs in release build
- [ ] Offline mode handled
- [ ] Test account credentials provided
- [ ] Support email functional
- [ ] Release notes written
- [ ] Crash-free baseline established (0 crashes in internal testing)

---

## Common Pitfalls & Solutions

| Pitfall | Impact | Solution |
|---------|--------|----------|
| Mismatched version code | Rejection during build | Always increment; test locally first |
| Outdated Target SDK | Rejection immediately | Update yearly to Google requirement |
| Missing Privacy Policy URL | Rejection for data collection | Host on accessible domain; test link |
| Inaccurate Data Safety | Potential app removal | Triple-check declarations; link to Privacy Policy |
| Crashes in review | Auto-rejection | Test on min SDK device thoroughly |
| Low-quality screenshots | Low conversion rate | Use design tool; include captions; real app UI only |
| Misleading description | Rejection + account warning | Honest feature list; no superlatives |
| Test account issues | Reviewer can't test features | Provide valid credentials; ensure tester permissions |

---

## Resources & References

- [Google Play Console Help](https://support.google.com/googleplay)
- [Android Developers: App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Policy Center](https://play.google.com/about/developer-content-policy/)
- [Android Security & Privacy Year Class](https://developer.android.com/training)
- [Firebase Crashlytics Setup](https://firebase.google.com/docs/crashlytics)
- [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)

---

## Using This Skill

When you request an Android app PRD or pre-build preparation:
1. I will gather app details (name, features, target audience)
2. I will walk through all 13 sections with you
3. I will generate a complete PRD document
4. I will create a tailored pre-build checklist
5. I will highlight any policy compliance concerns
6. I will prepare a release timeline and rollout strategy

**Note:** This skill is for apps only. For websites or cross-platform web apps, use other documentation frameworks.
