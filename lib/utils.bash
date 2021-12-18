#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for clang-tools-static.
GH_REPO="muttleyxd/clang-tools-static-binaries"
GH_REPO_URL="https://github.com/${GH_REPO}"
TOOL_NAME="clang-tools-static"
TOOL_TEST="clang-format"
USE_KERNEL=
USE_ARCH=
USE_PLATFORM=

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if clang-tools-static is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO_URL" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

fetch_all_assets() {
  curl -s -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${GH_REPO}/releases |
    jq -r '.[0].assets[] | "\(.name) \(.browser_download_url)"'
}

get_kernel() {

  local kernel
  kernel=$(uname -s)

  case $kernel in
  Darwin)
    echo -n "macosx"
    ;;
  Linux)
    echo -n "linux"
    ;;
  esac

  echo -n ""
}

get_arch() {
  local arch
  arch=$(uname -m)

  case $arch in
  x86_64)
    echo -n "amd64"
    ;;
  esac

  echo -n "$"
}

validate_platform() {

  if [ -n "${USE_PLATFORM}" ]; then
    return
  fi

  local kernel arch
  kernel=$(uname -s)
  arch=$(uname -m)

  case $kernel in
  Darwin)
    USE_KERNEL=macosx
    USE_ARCH=amd64
    ;;
  Linux)
    case $arch in
    x86_64)
      USE_KERNEL=linux
      USE_ARCH=amd64
      ;;
    esac
    ;;
  esac

  if [ -z "${USE_KERNEL}" ] || [ -z "${USE_ARCH}" ]; then
    fail "Unsupported platform '${kernel}-${arch}'"
  fi

  USE_PLATFORM="${USE_KERNEL}-${USE_ARCH}"
}

list_all_versions() {

  validate_platform

  local toolname=$1

  fetch_all_assets |
    grep "$toolname" |
    grep "$USE_PLATFORM" |
    grep -v "sha" |
    awk '{print $1}' |
    sed "s/^${toolname}-\(.*\)_.*/\1/"
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  # TODO: Adapt the release URL convention for clang-tools-static
  url="$GH_REPO_URL/archive/v${version}.tar.gz"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

    # TODO: Asert clang-tools-static executable exists.
    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing $TOOL_NAME $version."
  )
}
