#!/usr/bin/env bash
set -euo pipefail

# Setup script for scala-calico-webapp-starter template
# Run this once after `nix flake init` to customize placeholder names.

echo "=== Scala Calico Webapp Starter Setup ==="
echo ""

read -rp "App name, lowercase (e.g. myapp, coolsite): " APP_NAME
read -rp "Package organization (e.g. com.softinio): " ORGANIZATION
read -rp "App display name (e.g. My Cool Site): " DISPLAY_NAME
read -rp "Production domain (e.g. coolsite.com): " DOMAIN

ENV_PREFIX=$(echo "$APP_NAME" | tr '[:lower:]' '[:upper:]')
ORG_PATH=$(echo "$ORGANIZATION" | tr '.' '/')

echo ""
echo "Applying replacements..."

# Content replacements in every tracked text file
find . -type f \( -name "*.scala" -o -name "*.mill" -o -name "*.nix" \
    -o -name "*.toml" -o -name "*.yml" -o -name "*.md" -o -name "*.css" \
    -o -name "*.json" -o -name "*.sql" \) -not -path "./out/*" \
    -not -path "./node_modules/*" -print0 |
  while IFS= read -r -d '' f; do
    sed -i.bak \
      -e "s/com\.example\.mywebapp/${ORGANIZATION}.${APP_NAME}/g" \
      -e "s/MYWEBAPP_/${ENV_PREFIX}_/g" \
      -e "s/mywebapp/${APP_NAME}/g" \
      -e "s/My Web App/${DISPLAY_NAME}/g" \
      -e "s/MyWebApp/${DISPLAY_NAME}/g" \
      -e "s/example\.com/${DOMAIN}/g" \
      "$f"
    rm -f "$f.bak"
  done

# Move sources into the new package directory
for module in shared/src shared/test/src backend/src backend/test/src frontend/src; do
  if [[ -d "$module/com/example/mywebapp" ]]; then
    mkdir -p "$module/${ORG_PATH}"
    mv "$module/com/example/mywebapp" "$module/${ORG_PATH}/${APP_NAME}"
    # remove the old empty com/example tree if nothing is left in it
    rmdir -p "$module/com/example" 2>/dev/null || true
  fi
done

echo ""
echo "Done! Next steps:"
echo "  1. rm setup.sh"
echo "  2. git init && git add . && git commit -m 'Initial commit'"
echo "  3. nix develop   # then: runDev"
