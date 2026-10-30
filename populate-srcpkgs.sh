#!/bin/sh

set -eu

VOID_PACKAGES_DIR="${VOID_PACKAGES_DIR:-void-packages}"

# Base directory for short-lived scratch space (multirepo clone scratch).
# The workflow sets XBPS_STATE_DIR pointing to $RUNNER_TEMP/xbps-state,
# created with 0777 and no sticky bit; outside the workflow (local test),
# it falls back to RUNNER_TEMP and finally /tmp.
# This script runs entirely as root on CI, so fs.protected_regular does
# not affect it; this migration is standardization (all pipeline scratch
# in one place), not a bug fix.
STATE_DIR="${XBPS_STATE_DIR:-${RUNNER_TEMP:-/tmp}}"
mkdir -p "$STATE_DIR" 2>/dev/null || :
if [ ! -w "$STATE_DIR" ] || [ ! -x "$STATE_DIR" ]; then
    echo "error: scratch directory ${STATE_DIR} is not writable by $(id -un)" >&2
    echo "hint: the 'Prepare state directory' workflow step must create it first with chmod 0777 (no sticky bit)" >&2
    exit 1
fi

REPOS="
brave:https://codefloe.com/Ruintar/brave:master
brave-beta:https://codefloe.com/Ruintar/brave-beta:master
brave-nightly:https://codefloe.com/Ruintar/brave-nightly:master
brave-origin:https://codefloe.com/Ruintar/brave-origin:master
brave-origin-beta:https://codefloe.com/Ruintar/brave-origin-beta:master
brave-origin-nightly:https://codefloe.com/Ruintar/brave-origin-nightly:master
helium:https://codefloe.com/Ruintar/helium:master
vivaldi:https://codefloe.com/Ruintar/vivaldi:master
vivaldi-snapshot:https://codefloe.com/Ruintar/vivaldi-snapshot:master
"

for entry in $REPOS; do
  name=$(echo "$entry" | cut -d: -f1)
  branch=$(echo "$entry" | rev | cut -d: -f1 | rev)
  url=$(echo "$entry" | cut -d: -f2-3)

  echo "==> ${name} (${branch})"
  rm -rf "${VOID_PACKAGES_DIR}/srcpkgs/${name}"
  git clone --quiet --depth=1 -b "$branch" "$url" "${VOID_PACKAGES_DIR}/srcpkgs/${name}"
done

MULTIREPOS="
thorium:https://codefloe.com/Ruintar/thorium:master
"

for entry in $MULTIREPOS; do
  name=$(echo "$entry" | cut -d: -f1)
  branch=$(echo "$entry" | rev | cut -d: -f1 | rev)
  url=$(echo "$entry" | cut -d: -f2-3)

  tmp=$(mktemp -d "${STATE_DIR}/populate-${name}-XXXXXX")
  # With set -e, any failure in the block below (e.g. a broken clone)
  # aborts the script; the trap ensures the clone scratch is not left
  # orphaned in the state directory.
  trap 'rm -rf "$tmp"' EXIT
  git clone --quiet --depth=1 -b "$branch" "$url" "$tmp"
  for d in "$tmp"/*/; do
    pkg=$(basename "$d")
    if [ -f "$d/template" ]; then
      echo "==> ${pkg} (${branch}, from ${name})"
      rm -rf "${VOID_PACKAGES_DIR}/srcpkgs/${pkg}"
      mkdir -p "${VOID_PACKAGES_DIR}/srcpkgs/${pkg}"
      cp -r "${d}." "${VOID_PACKAGES_DIR}/srcpkgs/${pkg}/"
    fi
  done
  rm -rf "$tmp"
done
