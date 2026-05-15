# RefereeIQ PWA launch (GitHub Pages)

Use this checklist instead of Play Console steps while the web app is the primary ship target.

## 1. App identity

- **Public URL:** After the first successful deploy from branch `pwa-app`, the site is served from the `gh-pages` branch at `https://<your-username>.github.io/<repository-name>/` (unless you use a custom domain).
- **Name / branding:** `web/manifest.json` and `web/index.html` carry the RefereeIQ title and colors.
- **Version:** Web builds do not show `package_info` build numbers the same way as native; the Settings screen still shows `package_info_plus` when supported on the platform.

## 2. Hosting configuration

1. In GitHub: **Settings → Pages**, set **Source** to **Deploy from a branch**, branch **`gh-pages`**, folder **`/` (root)**.
2. Workflow [.github/workflows/web-ci-and-pages.yml](.github/workflows/web-ci-and-pages.yml) deploys only on **push** to **`pwa-app`** (adjust the `if` in the workflow if you want `main` or tags).
3. **Base path:** The workflow sets `--base-href` to `/<repo>/` for project Pages. If you use a **custom domain at the site root**, change the build step to `--base-href /` and update Pages settings accordingly.
4. **SPA routing:** The workflow copies `index.html` to `404.html` so refreshes and deep links work on GitHub Pages.

## 3. Firebase (required once per hostname)

1. **Authentication → Authorized domains:** add `localhost` (dev), `<your-username>.github.io`, and your full Pages URL if different.
2. **Google Sign-In:** Web OAuth client is referenced in [lib/services/auth_service.dart](lib/services/auth_service.dart) and `web/index.html` (`google-signin-client_id` meta). Ensure the same client exists in Google Cloud Console with your Pages origin under **Authorized JavaScript origins**.
3. Confirm **Firestore rules** and **Cloud Functions** behavior for browser clients (same project as mobile).

## 4. Mandatory product surfaces

- **Privacy / terms:** Linked from Settings (existing URLs on `refereeiq-site`).
- **Support:** Provide a monitored email or form in your site policy; list it in the repo README if needed.
- **Account deletion:** Existing in-app flow; confirm Cloud Functions still run for web users.

## 5. Review / QA access

- No Play review credentials; instead publish **test steps** (sign-up, Ask Sofia, sources PDF, profile photo) and any **feature flags** reviewers should know about.

## 6. Rollout

1. Merge or push to `pwa-app` and wait for the **Web CI and Pages** workflow.
2. Open the live URL in a private window, complete a smoke test (see [WEB_SECURITY_CHECKLIST.md](WEB_SECURITY_CHECKLIST.md) manual matrix).
3. Announce the URL; keep native store listings only if you still ship native builds.

## Known limitations (v1)

- **Push notifications:** FCM is not initialized on web; the Settings toggle is hidden on web.
- **Crashlytics:** Web uses default Flutter error presentation only (no Crashlytics wiring in `main.dart`).
- **In-app PDFs on web:** Asset PDFs open in a **new browser tab** (object URL), not inside the in-app `PDFView` widget used on Android.
