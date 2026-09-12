#!/bin/sh

set -eu

VOID_PACKAGES_DIR="${VOID_PACKAGES_DIR:-void-packages}"

REPOS="
brave:https://codefloe.com/Ruintar/brave:master
brave-beta:https://codefloe.com/Ruintar/brave-beta:master
brave-nightly:https://codefloe.com/Ruintar/brave-nightly:master
brave-origin:https://codefloe.com/Ruintar/brave-origin:master
brave-origin-beta:https://codefloe.com/Ruintar/brave-origin-beta:master
brave-origin-nightly:https://codefloe.com/Ruintar/brave-origin-nightly:master
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
