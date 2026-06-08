#!/bin/bash
# ==============================================================================
# Test runner for aidlc-workflows-setup.sh
#
# Runs BATS tests via npx (no global install required).
#
# Usage:
#   ./tests/run-tests.sh                  # Run all tests (formatted output)
#   ./tests/run-tests.sh --tap            # Run all tests (TAP output)
#   ./tests/run-tests.sh <test-file>      # Run a specific test file
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --------------------------------------------------
# npx wrapper: prefer local cache, install on demand
# --------------------------------------------------
BATS_CMD="npx --yes bats"

# --------------------------------------------------
# Main
# --------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   AI-DLC Workflows Setup — Test Suite       ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Determine test target
if [ $# -ge 1 ]; then
    TEST_TARGET=("$@")
    echo -e "${CYAN}Running specified test(s):${NC} $*"
else
    TEST_TARGET=("${SCRIPT_DIR}"/*.bats)
    echo -e "${CYAN}Running all tests in:${NC} ${SCRIPT_DIR}"
fi

echo ""

# Separate --tap flag from file arguments
BATS_ARGS=()
FILES=()
for arg in "${TEST_TARGET[@]}"; do
    if [ "$arg" == "--tap" ]; then
        BATS_ARGS+=("--tap")
    else
        FILES+=("$arg")
    fi
done

set +e
$BATS_CMD "${BATS_ARGS[@]}" "${FILES[@]}"
EXIT_CODE=$?
set -e

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All tests passed!${NC}"
else
    echo -e "${RED}${BOLD}Some tests failed (exit code: ${EXIT_CODE})${NC}"
fi

exit $EXIT_CODE
