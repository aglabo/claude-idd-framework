#!/usr/bin/env bash
# src: ./scripts/merge-mcp.sh
# @(#): Merge .mcp.json configurations with existing settings priority
#
# @file merge-mcp.sh
# @brief Merge .mcp.json configurations with existing settings priority
# @description
#   Merges claude-idd-framework's .mcp.json with the project's existing .mcp.json.
#   Key features:
#   - Existing project settings take priority
#   - mcpServers are merged (both existing and new servers preserved)
#   - Creates backup before modification
#   - Validates JSON output
#   - If no existing .mcp.json, simply copies the base file
#
# @example
#   # Merge .mcp.json configuration
#   bash scripts/merge-mcp.sh
#
#   # Verify merged servers
#   jq '.mcpServers | keys' .mcp.json
#
# @exitcode 0 If merge succeeds
# @exitcode 1 If base file not found, jq not available, or JSON validation fails
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_FILE="$REPO_ROOT/.mcp.json"
TARGET_FILE=".mcp.json"
TEMP_FILE=".mcp.json.tmp"

echo "🔧 Merging .mcp.json configuration..."
echo ""

# Change to repository root
cd "$REPO_ROOT" || exit 1

# Check if base file exists
if [ ! -f "$BASE_FILE" ]; then
  echo "❌ Base file not found: $BASE_FILE"
  exit 1
fi

# If target file doesn't exist, simply copy
if [ ! -f "$TARGET_FILE" ]; then
  echo "ℹ️ No existing .mcp.json found. Copying base file..."
  cp "$BASE_FILE" "$TARGET_FILE"
  echo "✅ .mcp.json created successfully"
  exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
  echo "❌ jq not found. Please install jq."
  echo "   - Windows: scoop install jq"
  echo "   - macOS: brew install jq"
  echo "   - Linux: sudo apt install jq"
  exit 1
fi

# Backup existing file
cp "$TARGET_FILE" "${TARGET_FILE}.bak"
echo "💾 Backup created: ${TARGET_FILE}.bak"

# Merge using jq
# Strategy: Existing settings take priority, then merge mcpServers
jq -s '
  reduce .[] as $item ({}; . * $item)
  |
  .mcpServers = (.[0].mcpServers + .[1].mcpServers)
' "$TARGET_FILE" "$BASE_FILE" > "$TEMP_FILE"

# Validate generated JSON
if ! jq empty "$TEMP_FILE" 2>/dev/null; then
  echo "❌ Generated JSON is invalid. Restoring backup..."
  mv "${TARGET_FILE}.bak" "$TARGET_FILE"
  rm -f "$TEMP_FILE"
  exit 1
fi

# Replace original file
mv "$TEMP_FILE" "$TARGET_FILE"

echo ""
echo "✅ .mcp.json merged successfully (existing settings priority)"
echo "📝 Original file backed up as: ${TARGET_FILE}.bak"
echo ""
echo "🔍 Merged mcpServers:"
jq '.mcpServers | keys' "$TARGET_FILE"
