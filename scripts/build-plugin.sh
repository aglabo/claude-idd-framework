#!/usr/bin/env bash
# src: ./scripts/build-plugin.sh
# @(#): Build & Sync Claude Plugin Package
#
# Copies all required project assets (.claude + docs) into plugin folder
# using xcp.sh with update (-u), backup (-b), and hidden (-H) support.
#
# Usage:
#   ./scripts/build-plugin.sh
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

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
PLUGIN_DIR="plugins/claude-idd-framework"
XCP="./scripts/xcp.sh"

<<<<<<< HEAD
mkdir -p "$PLUGIN_DIR/.claude"

# Ensure plugin dir exists
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "❌ Error: Plugin directory '$PLUGIN_DIR' not found."
  echo "➡️  Please create it first (e.g., mkdir $PLUGIN_DIR)"
  exit 1
fi

echo "🚀 Starting plugin build & sync process..."
echo "-----------------------------------------"

# -----------------------------------------------------------------------------
# Function: copy_with_xcp
# -----------------------------------------------------------------------------
copy_with_xcp() {
  local src="$1"
  local dest="$2"
  local desc="${3:-$src}"

  if [[ ! -e "$src" ]]; then
    echo "⚠️  Skip missing: $desc"
    return
  fi

  echo "📦 Syncing: $desc → $dest"
  "$XCP" -R -u -b -H -p "$src" "$dest"
}

# -----------------------------------------------------------------------------
# Copy operations
# -----------------------------------------------------------------------------

# 1. Copy .claude/agents
copy_with_xcp ".claude/agents" "${PLUGIN_DIR}/.claude/agents"

# 2. Copy .claude/commands (includes _helpers and _libs automatically)
copy_with_xcp ".claude/commands" "${PLUGIN_DIR}/.claude/"

# 3. Copy .claude/.mcp.json
if [[ -f ".mcp.json" ]]; then
  echo "📄 Copying .mcp.json → ${PLUGIN_DIR}/.claude/"
  "$XCP" -u -b -H -p ".mcp.json" "${PLUGIN_DIR}/.claude/"
fi

# 4. Copy docs/for-AI-dev-standards
mkdir -p "${PLUGIN_DIR}/docs/"
||||||| parent of b76c9d7 (build(scripts): プラグイン同期用スクリプト追加)
=======
mkdir -p "$PLUGIN_DIR"

# Ensure plugin dir exists
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "❌ Error: Plugin directory '$PLUGIN_DIR' not found."
  echo "➡️  Please create it first (e.g., mkdir $PLUGIN_DIR)"
  exit 1
fi

echo "🚀 Starting plugin build & sync process..."
echo "-----------------------------------------"

# -----------------------------------------------------------------------------
# Function: copy_with_xcp
# -----------------------------------------------------------------------------
copy_with_xcp() {
  local src="$1"
  local dest="$2"
  local desc="${3:-$src}"

  if [[ ! -e "$src" ]]; then
    echo "⚠️  Skip missing: $desc"
    return
  fi

  echo "📦 Syncing: $desc → $dest"
  "$XCP" -R -u -b -H -p "$src" "$dest"
}

# -----------------------------------------------------------------------------
# Copy operations
# -----------------------------------------------------------------------------

# 1. Copy .claude/agents
copy_with_xcp ".claude/agents" "${PLUGIN_DIR}/.claude/"

# 2. Copy .claude/commands (includes _helpers and _libs automatically)
copy_with_xcp ".claude/commands" "${PLUGIN_DIR}/.claude/"

# 3. Copy .claude/.mcp.json
if [[ -f ".claude/.mcp.json" ]]; then
  echo "📄 Copying .mcp.json → ${PLUGIN_DIR}/.claude/"
  "$XCP" -u -b -H -p ".claude/.mcp.json" "${PLUGIN_DIR}/.claude/"
fi

# 4. Copy docs/for-AI-dev-standards
>>>>>>> b76c9d7 (build(scripts): プラグイン同期用スクリプト追加)
copy_with_xcp "docs/for-AI-dev-standards" "${PLUGIN_DIR}/docs/"

# 5. Copy docs/writing-rules
copy_with_xcp "docs/writing-rules" "${PLUGIN_DIR}/docs/"

echo "-----------------------------------------"
echo "✅ Plugin build & sync completed successfully."
echo "📁 Synced into: ${PLUGIN_DIR}/"
echo ""
echo "💡 Tip: Now you can run:"
echo "   /plugin marketplace add ./claude-idd-framework"
echo "   /plugin install claude-idd-framework@atsushifx-marketplace"
