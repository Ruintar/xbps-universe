#!/usr/bin/env bash
set -u

XBPS_REPO="${1:?published repository URL is required}"
VOID_PACKAGES_DIR="${VOID_PACKAGES_DIR:-void-packages}"
ARCH="${ARCH:-x86_64}"
FORCE_REBUILD="${FORCE_REBUILD:-0}"

STATE_DIR="${XBPS_STATE_DIR:-${RUNNER_TEMP:-/tmp}/xbps-state}"
mkdir -p "$STATE_DIR" 2>/dev/null || :
if [ ! -w "$STATE_DIR" ] || [ ! -x "$STATE_DIR" ]; then
    echo "error: state directory ${STATE_DIR} is not writable by $(id -un)" >&2
    echo "hint: the 'Prepare state directory' workflow step must create it first with chmod 0777 (no sticky bit)" >&2
    exit 1
fi

PACKAGES="
brave
brave-beta
brave-nightly
brave-origin
brave-origin-beta
brave-origin-nightly
helium
thorium-browser
thorium-browser-avx2
thorium-browser-avx512
thorium-browser-sse4
thorium-browser-sse3
vivaldi
vivaldi-snapshot
"

NEW_PKGS="$STATE_DIR/new_pkgs"
OLD_PKGS="$STATE_DIR/old_pkgs"
TO_BUILD="$STATE_DIR/pkgs-to-build.txt"
CHANGED="$STATE_DIR/changed_names"

: > "$NEW_PKGS"
: > "$OLD_PKGS"
: > "$TO_BUILD"

echo "New pkgs:"
for pkg in $PACKAGES; do
    tpl="${VOID_PACKAGES_DIR}/srcpkgs/${pkg}/template"
    if [ ! -f "$tpl" ]; then
        echo "warning: missing template for ${pkg}" >&2
        continue
    fi
    archs=$(grep -E '^(only_for_)?archs=' "$tpl" | head -n1 | cut -d'"' -f2)
    if [ -n "$archs" ]; then
        case " $archs " in
            *" $ARCH "*) ;;
            *) echo "skipping ${pkg}: only ${archs} (current arch: ${ARCH})" >&2
               continue ;;
        esac
    fi
    ver=$(grep -m1 '^version=' "$tpl" | cut -d= -f2)
    rev=$(grep -m1 '^revision=' "$tpl" | cut -d= -f2)
    rev="${rev:-1}"
    echo "${pkg}-${ver}_${rev}" | tee -a "$NEW_PKGS"
done
sort -o "$NEW_PKGS" "$NEW_PKGS"

if [ "$FORCE_REBUILD" = "1" ]; then
    echo "Force rebuild enabled: ignoring everything already published (${ARCH})"
else
    echo "Old pkgs (${ARCH}):"
    xbps-query -RsM "*" --repository="$XBPS_REPO" -i 2>/dev/null \
        | awk '{ print $2 }' | sort > "$OLD_PKGS" || : > "$OLD_PKGS"
fi

if [ "$FORCE_REBUILD" = "1" ] || [ ! -s "$OLD_PKGS" ]; then
    sed 's/-[^-]*$//' "$NEW_PKGS" | sort -u > "$CHANGED"
else
    comm -13 "$OLD_PKGS" "$NEW_PKGS" | sed 's/-[^-]*$//' | sort -u > "$CHANGED"
fi

echo "Changed packages:"
if [ -s "$CHANGED" ]; then
    if ! xargs -r "${VOID_PACKAGES_DIR}/xbps-src" sort-dependencies < "$CHANGED" > "$TO_BUILD" 2>"$STATE_DIR/sort-deps.err"; then
        echo "warning: sort-dependencies failed, keeping alphabetical order" >&2
        cat "$STATE_DIR/sort-deps.err" >&2
        sort "$CHANGED" > "$TO_BUILD"
    fi
    sed 's/^/  /' "$TO_BUILD" >&2
else
    echo "  (none)"
fi

echo "Summary (${ARCH}): $(wc -l < "$TO_BUILD") package(s) to build"
exit 0
