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
# Mill always emits a <developer><email> element, so leaving this blank ships an
# empty tag in every published POM.
read -rp "Developer email (e.g. jane@example.com): " DEV_EMAIL
read -rp "Short library description (e.g. A fast Scala library for X): " DESCRIPTION
echo ""
echo "License: any SPDX identifier Mill knows, e.g. Apache-2.0, MIT, BSD-3-Clause, MPL-2.0."
read -rp "SPDX license identifier [Apache-2.0]: " LICENSE_ID
LICENSE_ID="${LICENSE_ID:-Apache-2.0}"

require "Library name" "$LIBRARY_NAME"
require "Maven organization" "$ORGANIZATION"
require "GitHub org/user" "$GITHUB_ORG"
require "Developer name" "$DEV_NAME"
require "Developer URL" "$DEV_URL"
require "Developer email" "$DEV_EMAIL"
require "Short library description" "$DESCRIPTION"

if ! printf '%s' "$LICENSE_ID" | grep -Eq '^[A-Za-z0-9.+-]+$'; then
  echo "Error: license must be a bare SPDX identifier (e.g. MIT), not a name or URL." >&2
  exit 1
fi

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
R_DEV_EMAIL="$(esc "$DEV_EMAIL")"
R_DESCRIPTION="$(esc "$DESCRIPTION")"
R_LICENSE="$(esc "$LICENSE_ID")"

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
      -e 'myorg' -e 'My Name' -e 'example\.com' -e 'A Scala 3 library' \
      -e 'License\.`Apache-2\.0`' |
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
    -e "s|MYLIBRARY_JVM|${R_UPPER}_JVM|g" \
    -e "s|mylibrary|${R_LIB}|g" \
    -e "s|MyLibrary|${R_PASCAL}|g" \
    -e "s|myorg|${R_GITHUB}|g" \
    -e "s|My Name|${R_DEV_NAME}|g" \
    -e "s|dev@example\\.com|${R_DEV_EMAIL}|g" \
    -e "s|https://example\\.com|${R_DEV_URL}|g" \
    -e "s|A Scala 3 library|${R_DESCRIPTION}|g" \
    -e "s|License\\.\`Apache-2\\.0\`|License.\`${R_LICENSE}\`|g" \
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
echo "  Test JDK env:     ${UPPER_NAME}_JVM"
echo "  Organization:    ${ORGANIZATION}"
echo "  GitHub org/user: ${GITHUB_ORG}"
echo "  Developer:       ${DEV_NAME} (${DEV_URL})"
echo "  Developer email: ${DEV_EMAIL}"
echo "  Description:     ${DESCRIPTION}"
echo "  License:         ${LICENSE_ID}"
echo ""
if [[ "$LICENSE_ID" != "Apache-2.0" ]]; then
  echo "!! The bundled LICENSE file is still the Apache License 2.0 text, but"
  echo "!! build.mill now declares ${LICENSE_ID}. Replace LICENSE with the"
  echo "!! ${LICENSE_ID} text before publishing:"
  echo "!!   https://spdx.org/licenses/${LICENSE_ID}.html"
  echo ""
fi

echo "Next steps:"
echo "  1. Review build.mill and add your library's mvnDeps"
echo "  2. Set up Maven Central publishing secrets in your GitHub repo:"
echo "     MILL_PGP_PASSPHRASE, MILL_PGP_SECRET_BASE64,"
echo "     MILL_SONATYPE_PASSWORD, MILL_SONATYPE_USERNAME"
echo "  3. Enter the dev shell: nix develop"
echo "  4. Commit the flake.lock it writes, so CI pins the toolchain:"
echo "       git add flake.lock && git commit -m 'Pin nixpkgs'"
echo "     Without it, nixos-unstable is re-resolved on every CI run and the"
echo "     JDK, Mill and Node versions can drift between runs."
echo "  5. Run tests: mill __.test"
echo "  6. Delete this script: rm setup.sh"
echo ""

read -rp "Delete setup.sh and .claude/commands/setup.md now? [y/N]: " DELETE_SELF
case "$DELETE_SELF" in
  y | Y | yes | YES | Yes)
    rm -f .claude/commands/setup.md
    rm -- "$0"
    echo "setup.sh and .claude/commands/setup.md deleted."
    ;;
esac
