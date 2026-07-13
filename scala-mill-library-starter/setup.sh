#!/usr/bin/env bash
set -euo pipefail

# Setup script for scala-mill-library-starter template
# Run this once after `nix flake init` to customize placeholder names.

echo "=== Scala Mill Library Starter Setup ==="
echo ""

# Prompt for values
read -rp "Library name (e.g. mylib, cool-lib): " LIBRARY_NAME
read -rp "Maven organization (e.g. com.softinio): " ORGANIZATION
read -rp "GitHub org/user (e.g. softinio): " GITHUB_ORG
read -rp "Developer name (e.g. Jane Doe): " DEV_NAME
read -rp "Developer URL (e.g. https://softinio.com): " DEV_URL
read -rp "Short library description (e.g. A fast Scala library for X): " DESCRIPTION

echo ""
echo "Applying replacements..."

# Files to perform sed replacements on
FILES=(
  build.mill
  README.md
  flake.nix
  devshell.toml
  .github/workflows/ci.yml
  .github/workflows/release.yml
  mylibrary/src/MyLibrary.scala
  mylibrary/test/src/MyLibraryTest.scala
  "mylibrary-cats-effect/src/MyLibraryIO.scala"
  "mylibrary-cats-effect/test/src/MyLibraryIOTest.scala"
  docs/index.md
  scripts/LaikaBuild.scala
  scripts/LaikaPreview.scala
)

CATS_EFFECT_NAME="${LIBRARY_NAME}-cats-effect"

for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    sed -i.bak \
      -e "s/mylibrary-cats-effect/${CATS_EFFECT_NAME}/g" \
      -e "s/mylibrary/${LIBRARY_NAME}/g" \
      -e "s/MyLibrary/${LIBRARY_NAME^}/g" \
      -e "s/com\.example/${ORGANIZATION}/g" \
      -e "s/myorg/${GITHUB_ORG}/g" \
      -e "s/My Name/${DEV_NAME}/g" \
      -e "s|https://example\.com|${DEV_URL}|g" \
      -e "s/A Scala 3 library/${DESCRIPTION}/g" \
      -e "s/MYLIBRARY_DOC_VERSION/${LIBRARY_NAME^^}_DOC_VERSION/g" \
      "$f"
    rm -f "${f}.bak"
  fi
done

# Rename source directories
if [[ -d "mylibrary" ]]; then
  mv "mylibrary" "${LIBRARY_NAME}"
  echo "Renamed directory: mylibrary -> ${LIBRARY_NAME}"
fi

if [[ -d "mylibrary-cats-effect" ]]; then
  mv "mylibrary-cats-effect" "${CATS_EFFECT_NAME}"
  echo "Renamed directory: mylibrary-cats-effect -> ${CATS_EFFECT_NAME}"
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Summary of changes:"
echo "  Library name:    ${LIBRARY_NAME}"
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

read -rp "Delete setup.sh now? [y/N]: " DELETE_SELF
if [[ "${DELETE_SELF,,}" == "y" ]]; then
  rm -- "$0"
  echo "setup.sh deleted."
fi
