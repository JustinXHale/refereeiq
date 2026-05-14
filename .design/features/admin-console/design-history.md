# Admin console — design history

## 2026-05-07

### [Decision] Drawer-gated admin entry
- **Admin** appears in the app drawer only after the server confirms the signed-in user’s UID is on the allowlist, so most users never see operator tooling.
- The console uses tabs (features, prompts, AI, admins) to match RefereeIQ’s remote-config surfaces without exposing Firestore writes to the general client SDK.
