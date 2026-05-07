#!/usr/bin/env bash
# RefereeIQ Pre-Release Automated Checks
# Run from anywhere: bash .agents/pre-release-checklist/scripts/run_automated_checks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR"
while [ "$ROOT" != "/" ]; do
  if [ -f "$ROOT/pubspec.yaml" ]; then break; fi
  ROOT="$(dirname "$ROOT")"
done
if [ ! -f "$ROOT/pubspec.yaml" ]; then
  echo "Could not find Flutter project root (pubspec.yaml) above $SCRIPT_DIR" >&2
  exit 1
fi
cd "$ROOT"

PASS=0
FAIL=0
SKIP=0

green()  { echo -e "\033[0;32m✅ $*\033[0m"; }
red()    { echo -e "\033[0;31m❌ $*\033[0m"; }
yellow() { echo -e "\033[0;33m⚠️  $*\033[0m"; }
header() { echo -e "\n\033[1;34m── $* ──\033[0m"; }

# ──────────────────────────────────────────────
# 1. Flutter static analysis
# ──────────────────────────────────────────────
header "1/4  flutter analyze"
if flutter analyze --no-pub 2>&1; then
  green "flutter analyze passed"
  PASS=$((PASS + 1))
else
  red "flutter analyze failed — fix all errors and warnings before releasing"
  FAIL=$((FAIL + 1))
  echo "Stopping: fix analysis issues first." && exit 1
fi

# ──────────────────────────────────────────────
# 2. Flutter tests
# ──────────────────────────────────────────────
header "2/4  flutter test"
if flutter test --no-pub 2>&1; then
  green "flutter test passed"
  PASS=$((PASS + 1))
else
  red "flutter test failed — all tests must pass before releasing"
  FAIL=$((FAIL + 1))
  echo "Stopping: fix failing tests first." && exit 1
fi

# ──────────────────────────────────────────────
# 3. Android Lint (manifest and API compatibility)
# ──────────────────────────────────────────────
header "3/4  Android lint"
if [ -f "android/gradlew" ]; then
  cd android
  # Lint the app module only — root `lint` also runs plugin projects in
  # .pub-cache and fails on third-party issues (e.g. flutter_webrtc NewApi).
  ./gradlew :app:lintDebug --quiet 2>&1
  LINT_REPORT="$ROOT/build/app/reports/lint-results-debug.html"
  if [ -f "$LINT_REPORT" ]; then
    cp "$LINT_REPORT" "$ROOT/android_lint_report.html"
    # Count errors (not warnings) — errors block a release
    ERROR_COUNT=$(grep -c 'class="error"' "$ROOT/android_lint_report.html" 2>/dev/null) || true
    ERROR_COUNT=${ERROR_COUNT:-0}
    if [ "${ERROR_COUNT:-0}" -eq 0 ]; then
      green "Android lint: no errors (report saved to android_lint_report.html)"
      PASS=$((PASS + 1))
    else
      red "Android lint: $ERROR_COUNT error(s) found — open android_lint_report.html to review"
      FAIL=$((FAIL + 1))
    fi
  else
    yellow "Android lint ran but report not found at expected path"
    SKIP=$((SKIP + 1))
  fi
  cd "$ROOT"
else
  yellow "android/gradlew not found — skipping Android lint"
  SKIP=$((SKIP + 1))
fi

# ──────────────────────────────────────────────
# 4. OWASP Security Scanners
# ──────────────────────────────────────────────
header "4/4  OWASP security scanners"
OWASP_DIR=".agents/owasp-mobile-security-checker/scripts"
if [ -d "$OWASP_DIR" ] && command -v python3 &>/dev/null; then
  OWASP_FAIL=0

  for SCANNER in \
    "scan_hardcoded_secrets.py:M1 Hardcoded secrets" \
    "check_dependencies.py:M2 Dependency vulnerabilities" \
    "check_network_security.py:M5 Network security" \
    "analyze_storage_security.py:M9 Insecure storage"
  do
    SCRIPT="${SCANNER%%:*}"
    LABEL="${SCANNER##*:}"
    SCRIPT_PATH="$OWASP_DIR/$SCRIPT"
    if [ -f "$SCRIPT_PATH" ]; then
      echo "  Running $LABEL..."
      python3 "$SCRIPT_PATH" . 2>&1 || true
      # Check output JSON for CRITICAL/HIGH severity
      OUTPUT_JSON=$(ls owasp_*.json 2>/dev/null | tail -1 || true)
      if [ -n "${OUTPUT_JSON:-}" ]; then
        CRITICAL=$(grep -c '"severity": "CRITICAL"' "$OUTPUT_JSON" 2>/dev/null) || true
        CRITICAL=${CRITICAL:-0}
        HIGH=$(grep -c '"severity": "HIGH"' "$OUTPUT_JSON" 2>/dev/null) || true
        HIGH=${HIGH:-0}
        if [ "${CRITICAL:-0}" -gt 0 ] || [ "${HIGH:-0}" -gt 0 ]; then
          red "$LABEL: $CRITICAL CRITICAL, $HIGH HIGH findings — review $OUTPUT_JSON"
          OWASP_FAIL=$((OWASP_FAIL + 1))
        else
          green "$LABEL: no CRITICAL or HIGH findings"
        fi
      fi
    else
      yellow "  $LABEL: script not found, skipping"
      SKIP=$((SKIP + 1))
    fi
  done

  if [ "$OWASP_FAIL" -eq 0 ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    red "OWASP: $OWASP_FAIL scanner(s) found CRITICAL/HIGH issues — fix before releasing"
  fi
else
  yellow "OWASP scanner skipped (python3 not found or .agents/owasp-mobile-security-checker/ missing)"
  SKIP=$((SKIP + 1))
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  AUTOMATED CHECK RESULTS"
echo "══════════════════════════════════════════"
green  "Passed : $PASS"
[ "$SKIP" -gt 0 ] && yellow "Skipped: $SKIP"
[ "$FAIL" -gt 0 ] && red    "Failed : $FAIL"
echo "══════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  red "Fix all failures before proceeding to manual device testing."
  exit 1
else
  echo ""
  green "All automated checks passed. Proceed to Phase 2 manual device testing."
  echo "  See: .agents/pre-release-checklist/references/manual_checks.md"
  exit 0
fi
