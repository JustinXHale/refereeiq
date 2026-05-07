# 🤖 Android App PRD & Pre-Build Checklist — Cursor Agent Skill

> A reusable Cursor skill that helps developers create complete Android App PRDs and Google Play Store pre-build checklists — structured, compliant, and ready for release.

---

## What Is This?

This is a **Cursor Agent Skill** — a structured instruction file under `.cursor/skills/` so the agent follows a consistent playbook when you're building an Android app for the Google Play Store.

Instead of re-explaining the whole Play release process each time, this skill gives the agent a battle-tested 13-step framework. It covers the full lifecycle: from defining app identity through staged rollout and policy compliance.

---

## What It Does

When this skill is active, the agent will:

- Generate a complete **Android App PRD** (Product Requirements Document)
- Walk you through a **13-section pre-build checklist** before Play Store submission
- Help you declare **Data Safety** accurately in Play Console
- Identify **common rejection reasons** before you hit submit
- Plan a **staged rollout strategy** (Internal → Closed → Production)
- Flag **policy compliance issues** early in the process

---

## The 13-Section Framework

| # | Section | What It Covers |
|---|---------|----------------|
| 1 | App Identity | Name, package name, version code, icon |
| 2 | Platform Configuration | Min SDK, target SDK, keystore, build config |
| 3 | Permissions Planning | Required permissions with justified use |
| 4 | Data & Privacy | Privacy policy, encryption, data inventory |
| 5 | Mandatory Screens | Privacy, support, account deletion, about |
| 6 | Google Play Data Safety | Play Console data declaration |
| 7 | App Stability | Crash-free baseline, offline handling, error recovery |
| 8 | Ads & Monetization | Ad compliance, placement strategy |
| 9 | Play Store Assets | Icon, feature graphic, screenshots specs |
| 10 | Review Access | Test account credentials for reviewers |
| 11 | Build & Signing | AAB generation, keystore signing, ProGuard |
| 12 | Release Flow | Internal → Closed → Production rollout |
| 13 | Policy Compliance | Copyright, impersonation, content rating, IARC |

---

## Who Is This For?

- **Solo developers** launching Android apps on the Play Store
- **Freelancers** managing client Android projects
- **Small teams** who want a standardized pre-release process
- **Teams using Cursor agents** as part of their dev workflow

---

## How to Use

### Option 1: Repo skill (this project)

Keep `SKILL.md` under `.cursor/skills/01-android-app-prd(01structure)/`. Cursor loads project skills when configured; invoke Android PRD / Play Store prep workflows in chat.

### Option 2: Manual paste

Copy the content of `SKILL.md` into the chat (or a **Cursor Rule**) as context. Then ask:

```
Help me create an Android App PRD for my app [App Name]. It does [brief description].
```

The agent can walk section by section using the framework.

---

## Output Example

After running this skill, you get a structured PRD like:

```markdown
# MyApp - Android App PRD

## 1. App Identity
- App Name: MyApp
- Package Name: com.mycompany.myapp
- Version: 1.0.0 (Code: 1)

## 2. Platform Configuration
- Min SDK: API 24 (Android 7.0)
- Target SDK: API 35

## 3. Permissions
| Permission | Justification |
|-----------|---------------|
| INTERNET | API calls |
| CAMERA | Photo capture feature |

...and so on through all 13 sections
```

---

## Quick Validation Checklist

Before hitting submit on Play Store, this skill also provides a final checklist:

- [ ] Version code incremented
- [ ] Target SDK meets current Google Play requirement
- [ ] All 13 sections addressed
- [ ] AAB signed and locally tested
- [ ] Privacy Policy live and accessible
- [ ] Data Safety form accurate
- [ ] Zero crashes in internal testing
- [ ] Debug logs removed from release build
- [ ] Test account credentials provided
- [ ] Release notes written

---

## Common Pitfalls Covered

| Pitfall | Impact | Solution |
|---------|--------|----------|
| Mismatched version code | Build rejection | Always increment; test locally first |
| Outdated Target SDK | Immediate rejection | Update yearly per Google requirements |
| Missing Privacy Policy | Rejection | Host on accessible domain; verify link |
| Inaccurate Data Safety | App removal risk | Triple-check declarations |
| Crashes in review | Auto-rejection | Test on minimum SDK device |

---

## File Structure

```
.cursor/skills/01-android-app-prd(01structure)/
├── README.md       ← You are here
└── SKILL.md        ← The skill instruction file
```

---

## Built By

Created by **Rishikesh** — Frontend & Product Engineer, building AI-native tools and products.

Part of a personal initiative to build reusable agent skills for common product engineering workflows.

---

## License

MIT — free to use, adapt, and share. Attribution appreciated.

---

## Resources

- [Google Play Console Help](https://support.google.com/googleplay)
- [Android App Signing Docs](https://developer.android.com/studio/publish/app-signing)
- [Google Play Policy Center](https://play.google.com/about/developer-content-policy/)
- [Firebase Crashlytics Setup](https://firebase.google.com/docs/crashlytics)
- [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)
