#!/usr/bin/env bash
# setup-idd.sh - Setup script for claude-idd-framework
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📦 Setting up claude-idd-framework..."
echo ""

# Change to repository root
cd "$REPO_ROOT" || exit 1

# 1. Check jq installation
echo "🔍 Checking jq installation..."
if ! command -v jq &> /dev/null; then
  echo "❌ jq not found. Please install jq."
  echo ""
  echo "Installation instructions:"
  echo "  - Windows: choco install jq"
  echo "  - macOS: brew install jq"
  echo "  - Linux: sudo apt install jq"
  echo ""
  exit 1
fi
echo "✅ jq found: $(jq --version)"
echo ""

# 2. Merge .mcp.json
echo "🔧 Merging .mcp.json configuration..."
if bash "$SCRIPT_DIR/merge-mcp.sh"; then
  echo "✅ .mcp.json merged successfully"
else
  echo "❌ Failed to merge .mcp.json"
  exit 1
fi
echo ""

# 3. Copy GitHub Issue templates
echo "📋 Copying GitHub Issue templates..."
if [ -d ".github/ISSUE_TEMPLATE" ]; then
  echo "ℹ️ .github/ISSUE_TEMPLATE already exists, skipping..."
else
  mkdir -p .github/ISSUE_TEMPLATE
  if [ -d ".claude-idd/.github/ISSUE_TEMPLATE" ]; then
    cp .claude-idd/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/ 2>/dev/null || true
    echo "✅ Issue templates copied"
  else
    echo "⚠️ No Issue templates found in framework"
  fi
fi
echo ""

# 4. Copy GitHub Workflows
echo "⚙️ Copying GitHub Workflows..."
mkdir -p .github/workflows
if [ -f ".claude-idd/.github/workflows/ci-secrets-scan.yaml" ]; then
  if [ -f ".github/workflows/ci-secrets-scan.yaml" ]; then
    echo "ℹ️ ci-secrets-scan.yaml already exists, skipping..."
  else
    cp .claude-idd/.github/workflows/ci-secrets-scan.yaml .github/workflows/
    echo "✅ Workflow copied: ci-secrets-scan.yaml"
  fi
else
  echo "⚠️ ci-secrets-scan.yaml not found in framework"
fi
echo ""

# 5. Copy config files
echo "🔐 Copying security config files..."
mkdir -p configs
if [ -f ".claude-idd/configs/gitleaks.toml" ]; then
  if [ -f "configs/gitleaks.toml" ]; then
    echo "ℹ️ gitleaks.toml already exists, skipping..."
  else
    cp .claude-idd/configs/gitleaks.toml configs/
    echo "✅ Config copied: gitleaks.toml"
  fi
else
  echo "⚠️ gitleaks.toml not found in framework"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Verify .mcp.json configuration:"
echo "     jq '.mcpServers | keys' .mcp.json"
echo ""
echo "  2. Restart Claude Code to load new configuration"
echo ""
echo "  3. Verify commands are available:"
echo "     /help"
echo ""
echo "  4. Test MCP servers:"
echo '     "lsmcp でプロジェクト概要を取得して"'
echo ""
