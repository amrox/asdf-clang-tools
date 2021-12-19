#!/usr/bin/env bash

set -euo pipefail

# Settings
ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE=${ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE:-0}

GH_REPO="muttleyxd/clang-tools-static-binaries"
GH_REPO_URL="https://github.com/${GH_REPO}"
PLUGIN_NAME="clang-tools"
USE_KERNEL=
USE_ARCH=
USE_PLATFORM=
YES_REGEX='^[Yy](E|e)?(S|s)?$'

fail() {
  echo -e "asdf-$PLUGIN_NAME: $*"
  exit 1
}

validate_deps() {

  deps=(jq curl)

  for d in "${deps[@]}"; do
    if ! command -v "$d" >/dev/null; then
      fail "Required dependency '$d' not found."
    fi
  done
}

log() {
  echo -e "asdf-$PLUGIN_NAME: $*"
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if clang-tools is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

fetch_all_assets() {
  curl -s -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${GH_REPO}/releases |
    jq -r '.[0].assets[] | "\(.name) \(.browser_download_url)"'
}

validate_platform() {
  if [ -n "$USE_PLATFORM" ]; then
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
  local toolname version url
  toolname="$1"
  version="$2"

  validate_platform

  # TODO: split output without piping to awk
  url=$(fetch_all_assets |
    grep "^${toolname}-${version}_${USE_PLATFORM}\s" |
    awk '{print $2}')

  (
    cd "${ASDF_DOWNLOAD_PATH}" || exit 1

    echo "* Downloading $toolname release $version..."
    curl "${curl_opts[@]}" -O "$url" || fail "Could not download $url"
    # TODO: range request ('-C -') does not seem to work

    # Download checksum
    curl "${curl_opts[@]}" -O "${url}.sha512sum" || fail "Could not download $url"
  )
}

install_version() {
  local toolname="$1"
  local install_type="$2"
  local version="$3"
  local install_path="$4"

  validate_platform

  if [ "$install_type" != "version" ]; then
    fail "asdf-$PLUGIN_NAME supports release installs only"
  fi

  if command -v sha512sum >/dev/null; then
    (
      log "Checking sha512 sum..."
      cd "${ASDF_DOWNLOAD_PATH}" || exit 1
      sha512sum -c ./*.sha512sum
    )
  else
    log "WARNING: sha512sum program not found - unable to checksum. Proceed with caution."
  fi

  (
    local asset_path full_tool_cmd tool_cmd
    asset_path="$install_path/assets"

    mkdir -p "$asset_path"
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$asset_path"

    # TODO: detect this instead of hard-coding in case the format changes?
    full_tool_cmd=${toolname}-${version}_${USE_PLATFORM}
    tool_cmd="$(echo "$toolname" | cut -d' ' -f1)"

    chmod +x "${asset_path}/${full_tool_cmd}"

    mkdir -p "${install_path}/bin" || true
    ln -s "${asset_path}/${full_tool_cmd}" "$install_path/bin/$tool_cmd"

    if [ "$USE_KERNEL" == "macosx" ]; then
      if [ "$ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE" != 1 ]; then
        log "$toolname needs to be de-quarantined to run:\n\n"
        echo -e "  xattr -dr com.apple.quarantine \"${asset_path}/${full_tool_cmd}\""
        echo -e -n "\n\nProceed? [y/N] "
        read -r reply
        if [[ $reply =~ $YES_REGEX ]]; then
          ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE=1
        else
          exit 1
        fi

        if [ "$ASDF_CLANG_TOOLS_MACOS_DEQUARANTINE" == 1 ]; then
          xattr -dr com.apple.quarantine "${asset_path}/${full_tool_cmd}"
        fi
      fi
    fi

    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "$toolname $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing $toolname $version."
  )
}
