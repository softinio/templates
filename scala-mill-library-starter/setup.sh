#!/usr/bin/env bash
set -euo pipefail

# Setup script for scala-mill-library-starter template
# Run this once after `nix flake init` to customize placeholder names.
#
# Portable to bash 3.2 (the /bin/bash shipped with macOS): no ${var^^} /
# ${var,,} case-conversion expansions, which are bash 4+ only.

echo "=== Scala Mill Library Starter Setup ==="
echo ""

# --- helpers ---------------------------------------------------------------

# "cool-lib" -> "CoolLib"
to_pascal() {
  printf '%s' "$1" |
    awk -F'[^A-Za-z0-9]+' '{ for (i = 1; i <= NF; i++) printf "%s%s", toupper(substr($i, 1, 1)), substr($i, 2) }'
}

# "cool-lib" -> "COOL_LIB" (safe as an environment variable name)
to_env() {
  printf '%s' "$1" | sed 's/[^A-Za-z0-9]/_/g' | tr '[:lower:]' '[:upper:]'
}

# "cool-lib" -> "coollib" (safe as a Scala package segment)
to_pkg() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
}

# Escape a user-supplied string for use as a sed replacement with `|` delimiter
esc() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

require() {
  if [[ -z "$2" ]]; then
    echo "Error: $1 must not be empty." >&2
    exit 1
  fi
}

# --- prompt for values -----------------------------------------------------

read -rp "Library name (e.g. mylib, cool-lib): " LIBRARY_NAME
read -rp "Maven organization (e.g. com.softinio): " ORGANIZATION
read -rp "GitHub org/user (e.g. softinio): " GITHUB_ORG
read -rp "Developer name (e.g. Jane Doe): " DEV_NAME
read -rp "Developer URL (e.g. https://softinio.com): " DEV_URL
read -rp "Short library description (e.g. A fast Scala library for X): " DESCRIPTION

require "Library name" "$LIBRARY_NAME"
require "Maven organization" "$ORGANIZATION"
require "GitHub org/user" "$GITHUB_ORG"
require "Developer name" "$DEV_NAME"
require "Developer URL" "$DEV_URL"
require "Short library description" "$DESCRIPTION"

if ! printf '%s' "$LIBRARY_NAME" | grep -Eq '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
  echo "Error: library name must be lower-case alphanumeric words separated by '-' (e.g. cool-lib)." >&2
  exit 1
fi

CATS_EFFECT_NAME="${LIBRARY_NAME}-cats-effect"
PASCAL_NAME="$(to_pascal "$LIBRARY_NAME")"
UPPER_NAME="$(to_env "$LIBRARY_NAME")"
PKG_NAME="$(to_pkg "$LIBRARY_NAME")"

# Mill object names must be valid Scala identifiers; backtick hyphenated names.
case "$LIBRARY_NAME" in
  *-*) MODULE_IDENT="\`${LIBRARY_NAME}\`" ;;
  *) MODULE_IDENT="${LIBRARY_NAME}" ;;
esac

echo ""
echo "Applying replacements..."

# --- replacements ----------------------------------------------------------

R_CATS="$(esc "$CATS_EFFECT_NAME")"
R_LIB="$(esc "$LIBRARY_NAME")"
R_PASCAL="$(esc "$PASCAL_NAME")"
R_UPPER="$(esc "$UPPER_NAME")"
R_PKG_PATH="$(esc "${ORGANIZATION}.${PKG_NAME}")"
R_ORG="$(esc "$ORGANIZATION")"
R_MODULE="$(esc "$MODULE_IDENT")"
R_GITHUB="$(esc "$GITHUB_ORG")"
R_DEV_NAME="$(esc "$DEV_NAME")"
R_DEV_URL="$(esc "$DEV_URL")"
R_DESCRIPTION="$(esc "$DESCRIPTION")"

# Every tracked text file that still mentions a placeholder. Discovered rather
# than hard-coded so the list cannot drift out of sync with the template.
FILES=()
while IFS= read -r f; do
  FILES+=("$f")
done < <(
  find . \
    \( -name .git -o -name .jj -o -name out -o -name .metals -o -name .bloop -o -name target \) -prune -o \
    -type f ! -name 'setup.sh' ! -path './.claude/commands/setup.md' -print |
    sed 's|^\./||' |
    xargs grep -Il -e 'mylibrary' -e 'MyLibrary' -e 'MYLIBRARY' -e 'com\.example' \
      -e 'myorg' -e 'My Name' -e 'example\.com' -e 'A Scala 3 library' |
    sort
)

for f in "${FILES[@]}"; do
  sed -i.bak \
    -e "s|com\\.example\\.mylibrary|${R_PKG_PATH}|g" \
    -e "s|com\\.example|${R_ORG}|g" \
    -e "s|mylibrary-cats-effect|${R_CATS}|g" \
    -e "s|object mylibrary |object ${R_MODULE} |g" \
    -e "s|Seq(mylibrary(|Seq(${R_MODULE}(|g" \
    -e "s|MYLIBRARY_DOC_VERSION|${R_UPPER}_DOC_VERSION|g" \
    -e "s|mylibrary|${R_LIB}|g" \
    -e "s|MyLibrary|${R_PASCAL}|g" \
    -e "s|myorg|${R_GITHUB}|g" \
    -e "s|My Name|${R_DEV_NAME}|g" \
    -e "s|https://example\\.com|${R_DEV_URL}|g" \
    -e "s|A Scala 3 library|${R_DESCRIPTION}|g" \
    "$f"
  rm -f "${f}.bak"
  echo "  updated: $f"
done

# --- rename source directories ---------------------------------------------

if [[ -d "mylibrary" ]]; then
  mv "mylibrary" "${LIBRARY_NAME}"
  echo "Renamed directory: mylibrary -> ${LIBRARY_NAME}"
fi

if [[ -d "mylibrary-cats-effect" ]]; then
  mv "mylibrary-cats-effect" "${CATS_EFFECT_NAME}"
  echo "Renamed directory: mylibrary-cats-effect -> ${CATS_EFFECT_NAME}"
fi

# --- rename source files ---------------------------------------------------

# MyLibrary.scala -> Verdict4s.scala, MyLibraryIOTest.scala -> Verdict4sIOTest.scala, ...
while IFS= read -r src; do
  dir="$(dirname "$src")"
  base="$(basename "$src")"
  mv "$src" "${dir}/${PASCAL_NAME}${base#MyLibrary}"
  echo "Renamed file: ${src} -> ${dir}/${PASCAL_NAME}${base#MyLibrary}"
done < <(
  find . \
    \( -name .git -o -name .jj -o -name out -o -name .metals -o -name .bloop -o -name target \) -prune -o \
    -type f -name 'MyLibrary*' -print
)

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Summary of changes:"
echo "  Library name:    ${LIBRARY_NAME}"
echo "  Scala package:   ${ORGANIZATION}.${PKG_NAME}"
echo "  Scala types:     ${PASCAL_NAME}"
echo "  Docs version env: ${UPPER_NAME}_DOC_VERSION"
echo "  Organization:    ${ORGANIZATION}"
echo "  GitHub org/user: ${GITHUB_ORG}"
echo "  Developer:       ${DEV_NAME} (${DEV_URL})"
echo "  Description:     ${DESCRIPTION}"
echo ""
echo "Next steps:"
echo "  1. Review build.mill and add your library's mvnDeps"
echo "  2. Set up Maven Central publishing secrets in your GitHub repo:"
echo "     MILL_PGP_PASSPHRASE, MILL_PGP_SECRET_BASE64,"
echo "     MILL_SONATYPE_PASSWORD, MILL_SONATYPE_USERNAME"
echo "  3. Enter the dev shell: nix develop"
echo "  4. Run tests: mill __.test"
echo "  5. Delete this script: rm setup.sh"
echo ""

read -rp "Delete setup.sh and .claude/commands/setup.md now? [y/N]: " DELETE_SELF
case "$DELETE_SELF" in
  y | Y | yes | YES | Yes)
    rm -f .claude/commands/setup.md
    rm -- "$0"
    echo "setup.sh and .claude/commands/setup.md deleted."
    ;;
esac
