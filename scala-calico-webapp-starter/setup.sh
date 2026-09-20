#!/usr/bin/env bash
set -euo pipefail

# Setup script for scala-calico-webapp-starter template
# Run this once after `nix flake init` to customize placeholder names.

echo "=== Scala Calico Webapp Starter Setup ==="
echo ""

# --- helpers ---------------------------------------------------------------

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

read -rp "App name, lowercase (e.g. myapp, coolsite): " APP_NAME
read -rp "Package organization (e.g. com.softinio): " ORGANIZATION
read -rp "App display name (e.g. My Cool Site): " DISPLAY_NAME
read -rp "Production domain (e.g. coolsite.com): " DOMAIN

require "App name" "$APP_NAME"
require "Package organization" "$ORGANIZATION"
require "App display name" "$DISPLAY_NAME"
require "Production domain" "$DOMAIN"

# The app name becomes a Scala package segment and an environment variable
# prefix, so it has to be a plain lower-case alphanumeric identifier.
if ! printf '%s' "$APP_NAME" | grep -Eq '^[a-z][a-z0-9]*$'; then
  echo "Error: app name must be lower-case alphanumeric, starting with a letter (e.g. coolsite)." >&2
  echo "       It becomes a Scala package segment, so '-', '_' and '.' are not allowed." >&2
  exit 1
fi

if ! printf '%s' "$ORGANIZATION" | grep -Eq '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$'; then
  echo "Error: organization must be dot-separated lower-case alphanumeric segments (e.g. com.softinio)." >&2
  exit 1
fi

ENV_PREFIX=$(printf '%s' "$APP_NAME" | tr '[:lower:]' '[:upper:]')
ORG_PATH=$(printf '%s' "$ORGANIZATION" | tr '.' '/')

R_PKG=$(esc "${ORGANIZATION}.${APP_NAME}")
R_ENV_PREFIX=$(esc "$ENV_PREFIX")
R_APP_NAME=$(esc "$APP_NAME")
R_DISPLAY_NAME=$(esc "$DISPLAY_NAME")
R_DOMAIN=$(esc "$DOMAIN")

echo ""
echo "Applying replacements..."

# --- content replacements --------------------------------------------------

# Every text file that still mentions a placeholder. Discovered by content
# rather than by extension, so a new file type cannot be silently skipped.
find . \
  \( -name .git -o -name .jj -o -name out -o -name node_modules -o -name .metals -o -name .bloop \) -prune -o \
  -type f ! -name 'setup.sh' -print |
  sed 's|^\./||' |
  xargs grep -Il -e 'mywebapp' -e 'MyWebApp' -e 'MYWEBAPP' -e 'My Web App' -e 'example\.com' |
  sort |
  while IFS= read -r f; do
    sed -i.bak \
      -e "s|com\\.example\\.mywebapp|${R_PKG}|g" \
      -e "s|MYWEBAPP_|${R_ENV_PREFIX}_|g" \
      -e "s|mywebapp|${R_APP_NAME}|g" \
      -e "s|My Web App|${R_DISPLAY_NAME}|g" \
      -e "s|MyWebApp|${R_DISPLAY_NAME}|g" \
      -e "s|example\\.com|${R_DOMAIN}|g" \
      "$f"
    rm -f "$f.bak"
    echo "  updated: $f"
  done

# --- move sources into the new package directory ---------------------------

for module in shared/src shared/test/src backend/src backend/test/src frontend/src; do
  if [[ -d "$module/com/example/mywebapp" ]]; then
    mkdir -p "$module/${ORG_PATH}"
    mv "$module/com/example/mywebapp" "$module/${ORG_PATH}/${APP_NAME}"
    # remove the old empty com/example tree if nothing is left in it
    rmdir -p "$module/com/example" 2>/dev/null || true
    echo "  moved:   $module/com/example/mywebapp -> $module/${ORG_PATH}/${APP_NAME}"
  fi
done

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Summary of changes:"
echo "  App name:      ${APP_NAME}"
echo "  Scala package: ${ORGANIZATION}.${APP_NAME}"
echo "  Env prefix:    ${ENV_PREFIX}_"
echo "  Display name:  ${DISPLAY_NAME}"
echo "  Domain:        ${DOMAIN}"
echo ""
echo "Next steps:"
echo "  1. rm setup.sh"
echo "  2. git init && git add . && git commit -m 'Initial commit'"
echo "  3. nix develop   # then: runDev"
