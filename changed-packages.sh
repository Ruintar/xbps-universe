#!/usr/bin/env bash
set -u

XBPS_REPO="${1:?informe a URL do repositorio publicado}"
VOID_PACKAGES_DIR="${VOID_PACKAGES_DIR:-void-packages}"
ARCH="${ARCH:-x86_64}"
FORCE_REBUILD="${FORCE_REBUILD:-0}"

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

NEW_PKGS=/tmp/new_pkgs
OLD_PKGS=/tmp/old_pkgs
TO_BUILD=/tmp/pkgs-to-build.txt
CHANGED=/tmp/changed_names

: > "$NEW_PKGS"
: > "$OLD_PKGS"
: > "$TO_BUILD"

echo "New pkgs:"
for pkg in $PACKAGES; do
	tpl="${VOID_PACKAGES_DIR}/srcpkgs/${pkg}/template"
	if [ ! -f "$tpl" ]; then
		echo "aviso: template ausente para ${pkg}" >&2
		continue
	fi
	ver=$(grep -m1 '^version=' "$tpl" | cut -d= -f2)
	rev=$(grep -m1 '^revision=' "$tpl" | cut -d= -f2)
	rev="${rev:-1}"
	echo "${pkg}-${ver}_${rev}" | tee -a "$NEW_PKGS"
done
sort -o "$NEW_PKGS" "$NEW_PKGS"

if [ "$FORCE_REBUILD" = "1" ]; then
	echo "Force rebuild ativo: ignorando por completo o que ja esta publicado (${ARCH})"
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
	if ! xargs -r "${VOID_PACKAGES_DIR}/xbps-src" sort-dependencies < "$CHANGED" > "$TO_BUILD" 2>/tmp/sort-deps.err; then
		echo "aviso: sort-dependencies falhou, mantendo ordem alfabetica" >&2
		sort "$CHANGED" > "$TO_BUILD"
	fi
	sed 's/^/  /' "$TO_BUILD" >&2
else
	echo "  (nenhum)"
fi

echo "Resumo (${ARCH}): $(wc -l < "$TO_BUILD") pacote(s) para buildar"
exit 0
