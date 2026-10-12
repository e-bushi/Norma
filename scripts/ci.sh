#!/bin/bash
# Local and CI entry point for the verification gate.
# Runner labels: self-hosted, macOS, ARM64 (GitHub's defaults for this Mac).

set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="/opt/homebrew/bin:${PATH:-}"

# Pinned in VERIFICATION.md. Override DEVELOPER_DIR only to point at this Xcode.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
hash -r
echo "DEVELOPER_DIR=${DEVELOPER_DIR}"
xcodebuild -version

# One DerivedData directory per Actions run and job. Local runs keep a stable path.
if [[ -n "${GITHUB_RUN_ID:-}" ]]; then
  default_derived="/tmp/norma-derived-${GITHUB_RUN_ID}-${GITHUB_JOB:-job}"
else
  default_derived="/tmp/norma-derived"
fi
DERIVED="${DERIVED_DATA_PATH:-$default_derived}"
RESULTS="${RESULTS_PATH:-/tmp/norma-results}"
mkdir -p "$RESULTS"
# iOS 26.2, not OS=latest. Recorded in VERIFICATION.md.
DESTINATION_OS="${DESTINATION_OS:-26.2}"
echo "DESTINATION_OS=${DESTINATION_OS}"
echo "DERIVED=${DERIVED}"

destination() {
  echo "platform=iOS Simulator,name=$1,OS=${DESTINATION_OS}"
}

xcode() {
  xcodebuild \
    -project Norma.xcodeproj \
    -scheme Norma \
    -derivedDataPath "$DERIVED" \
    -parallel-testing-enabled NO \
    "$@"
}

# A skipped screenshot test exits 0 from xcodebuild. That would make the gate green
# without comparing a baseline, so treat any skip as a failure.
refuse_skips() {
  local bundle="$1"
  local skipped
  skipped=$(xcrun xcresulttool get test-results summary --path "$bundle" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin).get("skippedTests", 0))')
  if [[ "$skipped" != "0" ]]; then
    echo "screenshot tests skipped ($skipped). SCREENSHOT_DEVICE did not reach the test runner." >&2
    exit 1
  fi
}

swift_sources() {
  find Norma NormaTests NormaUITests -name '*.swift' -not -path '*/Generated/*'
}

cmd="${1:-}"
case "$cmd" in
  build)
    xcode build -destination "$(destination "iPhone 17")"
    ;;
  unit-tests)
    rm -rf "$RESULTS/unit-tests.xcresult"
    xcode test \
      -destination "$(destination "iPhone 17")" \
      -only-testing:NormaTests \
      -resultBundlePath "$RESULTS/unit-tests.xcresult"
    ;;
  style)
    if ! command -v swiftlint >/dev/null 2>&1; then
      echo "swiftlint is not installed. On the runner: brew install swiftlint" >&2
      exit 1
    fi
    swiftlint lint --strict --config .swiftlint.yml
    # shellcheck disable=SC2046
    xcrun swift-format lint --strict --configuration .swift-format $(swift_sources)
    ;;
  format)
    # shellcheck disable=SC2046
    xcrun swift-format format --configuration .swift-format -i $(swift_sources)
    ;;
  screenshot)
    # PR gate: dark mode, default Dynamic Type, one screen size.
    # Also fails if the app renders light while the system appearance is light.
    rm -rf "$RESULTS/screenshot.xcresult"
    if [[ "${RECORD_SCREENSHOTS:-}" == "1" ]]; then
      xcode test \
        -destination "$(destination "iPhone 17")" \
        -only-testing:NormaUITests/ScreenshotTests/testHomeDarkDefault \
        SCREENSHOT_DEVICE=iphone-17 \
        RECORD_SCREENSHOTS=1 \
        -resultBundlePath "$RESULTS/screenshot.xcresult"
    else
      xcode test \
        -destination "$(destination "iPhone 17")" \
        -only-testing:NormaUITests/ScreenshotTests/testHomeDarkDefault \
        -only-testing:NormaUITests/NormaUITests/testStaysDarkWhenTheSystemIsLight \
        SCREENSHOT_DEVICE=iphone-17 \
        -resultBundlePath "$RESULTS/screenshot.xcresult"
    fi
    refuse_skips "$RESULTS/screenshot.xcresult"
    ;;
  screenshot-matrix)
    # Full matrix: dark mode, default and accessibility Dynamic Type, small and large phones.
    run_device() {
      local name="$1"
      local slug="$2"
      local bundle="$RESULTS/screenshots-${slug}.xcresult"
      rm -rf "$bundle"
      if [[ "${RECORD_SCREENSHOTS:-}" == "1" ]]; then
        xcode test \
          -destination "$(destination "$name")" \
          -only-testing:NormaUITests/ScreenshotTests \
          SCREENSHOT_DEVICE="$slug" \
          RECORD_SCREENSHOTS=1 \
          -resultBundlePath "$bundle"
      else
        xcode test \
          -destination "$(destination "$name")" \
          -only-testing:NormaUITests/ScreenshotTests \
          SCREENSHOT_DEVICE="$slug" \
          -resultBundlePath "$bundle"
      fi
      refuse_skips "$bundle"
    }
    run_device "iPhone 16e" "iphone-16e"
    run_device "iPhone 17 Pro Max" "iphone-17-pro-max"
    ;;
  smoke)
    rm -rf "$RESULTS/smoke.xcresult"
    xcode test \
      -destination "$(destination "iPhone 17")" \
      -only-testing:NormaUITests/NormaUITests/testOnboardAddBillAndSeeWhatsLeft \
      -only-testing:NormaUITests/NormaUITests/testStaysDarkWhenTheSystemIsLight \
      -resultBundlePath "$RESULTS/smoke.xcresult"
    ;;
  record-screenshots)
    mkdir -p ScreenshotBaselines
    touch ScreenshotBaselines/.record
    set +e
    RECORD_SCREENSHOTS=1 bash "$0" screenshot
    status=$?
    RECORD_SCREENSHOTS=1 bash "$0" screenshot-matrix
    status=$((status + $?))
    set -e
    rm -f ScreenshotBaselines/.record
    exit "$status"
    ;;
  *)
    echo "usage: scripts/ci.sh {build|unit-tests|style|format|screenshot|screenshot-matrix|smoke|record-screenshots}" >&2
    exit 1
    ;;
esac
