#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing dequarantine functionality${NC}\n"

# Function to run a test case
run_test() {
  local test_name=$1
  local use_kernel=$2
  local dequarantine_env=$3

  echo -e "${BLUE}Test: $test_name${NC}"
  echo "  USE_KERNEL=$use_kernel"
  echo "  ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE=$dequarantine_env"

  # Create test directories
  TEST_DIR=$(mktemp -d)
  export ASDF_DOWNLOAD_PATH="$TEST_DIR/download"
  INSTALL_PATH="$TEST_DIR/install"

  mkdir -p "$ASDF_DOWNLOAD_PATH"

  # Create a dummy binary file
  TOOLNAME="clang-format"
  VERSION="17.0.6"
  case $use_kernel in
  macosx)
    PLATFORM="${use_kernel}-amd64"
    ;;
  macos-arm)
    PLATFORM="${use_kernel}-arm64"
    ;;
  esac
  DUMMY_FILE="${TOOLNAME}-${VERSION}_${PLATFORM}"

  # Create dummy files with quarantine attribute
  echo "dummy binary" >"$ASDF_DOWNLOAD_PATH/$DUMMY_FILE"
  echo "fake-checksum  $DUMMY_FILE" >"$ASDF_DOWNLOAD_PATH/${DUMMY_FILE}.sha512sum"

  # Add quarantine attribute to simulate downloaded file
  xattr -w com.apple.quarantine "test" "$ASDF_DOWNLOAD_PATH/$DUMMY_FILE" 2>/dev/null || true

  # Set environment variables
  export ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE=$dequarantine_env

  # Source the entire utils file to get all dependencies
  source lib/utils.bash

  # Set these AFTER sourcing since utils.bash resets them
  USE_KERNEL=$use_kernel
  case $use_kernel in
  macosx)
    USE_ARCH=amd64
    ;;
  macos-arm)
    USE_ARCH=arm64
    ;;
  esac
  USE_PLATFORM="${USE_KERNEL}-${USE_ARCH}"

  # Override check_shasum to skip validation for tests
  check_shasum() {
    echo "Skipping checksum validation for test"
  }

  # Override validate_deps to skip dependency checks in tests
  validate_deps() {
    : # no-op
  }

  # Override validate_platform to keep our test values
  validate_platform() {
    : # no-op - we've already set USE_KERNEL, USE_ARCH, USE_PLATFORM
  }

  # Preserve xattrs during cp - wrap cp to use -c flag
  cp() {
    command cp -c "$@"
  }
  export -f cp

  # Call the function
  if [ "$dequarantine_env" == "0" ]; then
    # For interactive mode, pipe 'y' into the function
    (echo "y") | install_version "$TOOLNAME" "version" "$VERSION" "$INSTALL_PATH" || {
      echo "  Installation process exited with error"
    }
  else
    install_version "$TOOLNAME" "version" "$VERSION" "$INSTALL_PATH" || {
      echo "  Installation process exited with error"
    }
  fi

  # Check if quarantine attribute was removed
  INSTALLED_FILE="$INSTALL_PATH/assets/$DUMMY_FILE"
  if [ -f "$INSTALLED_FILE" ]; then
    if xattr "$INSTALLED_FILE" 2>/dev/null | grep -q com.apple.quarantine; then
      echo -e "  ${RED}✗ FAILED - quarantine attribute still present${NC}\n"
    else
      echo -e "  ${GREEN}✓ PASSED - quarantine attribute removed${NC}\n"
    fi
  else
    echo -e "  ${RED}✗ FAILED - installed file not found${NC}\n"
  fi

  # Cleanup
  rm -rf "$TEST_DIR"
}

# Run test cases
echo "Testing on $(uname -s) $(uname -m)"
echo ""

run_test "macosx with DEQUARANTINE=1" "macosx" "1"
run_test "macos-arm with DEQUARANTINE=1" "macos-arm" "1"
run_test "macosx with DEQUARANTINE=0 (auto-yes)" "macosx" "0"
run_test "macos-arm with DEQUARANTINE=0 (auto-yes)" "macos-arm" "0"

echo -e "${BLUE}All tests completed${NC}"
