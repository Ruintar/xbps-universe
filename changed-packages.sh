set -uo pipefail

XBPS_REPO="$1"
VOID_PACKAGES_DIR="${VOID_PACKAGES_DIR:-void-packages}"

PACKAGES="
brave
brave-beta
brave-nightly
brave-origin
brave-origin-beta
brave-origin-nightly
vivaldi
vivaldi-snapshot
"

echo "Old pkgs:"
xbps-query -RsM "*" --repository="$XBPS_REPO" -i 2>/dev/null \
	| awk '{ print $2 }' | tee /tmp/old_pkgs

echo "New pkgs:"
: > /tmp/new_pkgs
for pkg in $PACKAGES; do
	ver=$(grep "^version=" "${VOID_PACKAGES_DIR}/srcpkgs/${pkg}/template" | awk -F= '{ print $2 }')
	rev=$(grep "^revision=" "${VOID_PACKAGES_DIR}/srcpkgs/${pkg}/template" | awk -F= '{ print $2 }')
	rev="${rev:-1}"
	echo -e "${pkg}-${ver}_${rev}" | tee -a /tmp/new_pkgs
done

sort /tmp/new_pkgs -o /tmp/new_pkgs
sort /tmp/old_pkgs -o /tmp/old_pkgs 2>/dev/null || : > /tmp/old_pkgs

echo -e '\x1b[32mChanged packages:\x1b[0m'
comm -13 /tmp/old_pkgs /tmp/new_pkgs |
	sed 's/-[^-]*$//' |
	xargs -r "${VOID_PACKAGES_DIR}/xbps-src" sort-dependencies |
	tee /tmp/pkgs-to-build.txt |
	sed "s/^/  /" >&2
