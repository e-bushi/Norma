#!/bin/bash
# Local and CI entry point for the verification gate.
# Runner labels: self-hosted, macOS, ARM64 (GitHub's defaults for this Mac).

set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="/opt/homebrew/bin:${PATH:-}"

DERIVED="${DERIVED_DATA_PATH:-/tmp/norma-derived}"
RESULTS="${RESULTS_PATH:-/tmp/norma-results}"
mkdir -p "$RESULTS"
DESTINATION_OS="${DESTINATION_OS:-latest}"

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
    # PR gate: light mode, default Dynamic Type, one screen size.
    rm -rf "$RESULTS/screenshot.xcresult"
    if [[ "${RECORD_SCREENSHOTS:-}" == "1" ]]; then
      xcode test \
        -destination "$(destination "iPhone 17")" \
        -only-testing:NormaUITests/ScreenshotTests/testHomeLightDefault \
        TEST_RUNNER_SCREENSHOT_DEVICE=iphone-17 \
        TEST_RUNNER_RECORD_SCREENSHOTS=1 \
        -resultBundlePath "$RESULTS/screenshot.xcresult"
    else
      xcode test \
        -destination "$(destination "iPhone 17")" \
        -only-testing:NormaUITests/ScreenshotTests/testHomeLightDefault \
        TEST_RUNNER_SCREENSHOT_DEVICE=iphone-17 \
        -resultBundlePath "$RESULTS/screenshot.xcresult"
    fi
    ;;
  screenshot-matrix)
    # Full matrix: light/dark × default/accessibility, small and large phones.
    run_device() {
      local name="$1"
      local slug="$2"
      local bundle="$RESULTS/screenshots-${slug}.xcresult"
      rm -rf "$bundle"
      if [[ "${RECORD_SCREENSHOTS:-}" == "1" ]]; then
        xcode test \
          -destination "$(destination "$name")" \
          -only-testing:NormaUITests/ScreenshotTests \
          TEST_RUNNER_SCREENSHOT_DEVICE="$slug" \
          TEST_RUNNER_RECORD_SCREENSHOTS=1 \
          -resultBundlePath "$bundle"
      else
        xcode test \
          -destination "$(destination "$name")" \
          -only-testing:NormaUITests/ScreenshotTests \
          TEST_RUNNER_SCREENSHOT_DEVICE="$slug" \
          -resultBundlePath "$bundle"
      fi
    }
    run_device "iPhone 16e" "iphone-16e"
    run_device "iPhone 17 Pro Max" "iphone-17-pro-max"
    ;;
  smoke)
    rm -rf "$RESULTS/smoke.xcresult"
    xcode test \
      -destination "$(destination "iPhone 17")" \
      -only-testing:NormaUITests/NormaUITests/testOnboardAddBillAndSeeWhatsLeft \
      -resultBundlePath "$RESULTS/smoke.xcresult"
    ;;
  record-screenshots)
    RECORD_SCREENSHOTS=1 bash "$0" screenshot
    RECORD_SCREENSHOTS=1 bash "$0" screenshot-matrix
    ;;
  *)
    echo "usage: scripts/ci.sh {build|unit-tests|style|format|screenshot|screenshot-matrix|smoke|record-screenshots}" >&2
    exit 1
    ;;
esac
