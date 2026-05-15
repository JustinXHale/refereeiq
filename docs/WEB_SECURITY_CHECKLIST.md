# Web / PWA security checklist (RefereeIQ)

Complements the OWASP Mobile skill scanners (run from repo root; JSON output in project root).

```bash
python3 ".cursor/skills/02-owasp-mobile-security-checker(security)/scripts/scan_hardcoded_secrets.py" .
python3 ".cursor/skills/02-owasp-mobile-security-checker(security)/scripts/check_dependencies.py" .
python3 ".cursor/skills/02-owasp-mobile-security-checker(security)/scripts/check_network_security.py" .
python3 ".cursor/skills/02-owasp-mobile-security-checker(security)/scripts/analyze_storage_security.py" .
```

## M1 — Client keys in `firebase_options.dart`

The scanners flag **Firebase Web API keys** in [lib/firebase_options.dart](lib/firebase_options.dart). These are **expected in the client** for Firebase Web. Reduce risk in **Google Cloud Console** by restricting the key to your app’s HTTP referrers and needed APIs (Firebase docs: API key restrictions).

## Web-specific items

1. **Authorized domains** — Firebase Auth must list every hostname that serves the app (GitHub Pages, custom domain, preview URLs if any).
2. **OAuth origins** — Google Sign-In web client must list the same origins under **Authorized JavaScript origins**.
3. **Content-Security-Policy** — GitHub Pages does not set CSP headers for you. A strict CSP is difficult with Flutter’s compiled bootstrap; if you add a front CDN later, introduce CSP gradually and test thoroughly.
4. **HTTPS** — GitHub Pages serves the site over HTTPS; keep all backend calls on HTTPS only.
5. **Firestore / Functions** — Browser clients can call your backend directly; treat **security rules** and **callable function auth** as the real enforcement layer (review after enabling web traffic).

## Manual smoke matrix (before sharing the URL)

| Environment | Checks |
|-------------|--------|
| Chrome desktop | Sign-in (email + Google), Ask Sofia, sources markdown + PDF open (new tab on web), profile save, settings theme |
| Chrome Android (PWA “Add to Home Screen”) | Same core flows; verify install icon and standalone display |
| Safari iOS | Same where supported; Google Sign-In may differ — verify OAuth origins |

## Privacy copy

Ensure the public **privacy policy** (linked in Settings) mentions web access, Firebase, analytics if enabled, and account deletion — aligned with actual behavior on the hosted URL.
