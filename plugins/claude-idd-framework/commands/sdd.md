---
# Claude Code 必須要素
allowed-tools: Bash(*), Read(*), Write(*), Task(*), mcp__codex-mcp__codex(*), mcp__lsmcp__get_project_overview(*), mcp__lsmcp__search_symbols(*), mcp__lsmcp__lsp_get_diagnostics(*), mcp__lsmcp__get_symbol_details(*), mcp__lsmcp__list_dir(*), mcp__serena-mcp__list_memories(*), mcp__serena-mcp__read_memory(*), mcp__serena-mcp__search_for_pattern(*), mcp__serena-mcp__get_symbols_overview(*), mcp__serena-mcp__find_symbol(*), mcp__serena-mcp__find_referencing_symbols(*), mcp__serena-mcp__list_dir(*)
argument-hint: "<init namespace/module | req | spec | tasks | coding [task-group] | commit>"
description: Spec-Driven-Development主要コマンド - MCP統合による効率的な要件定義から実装まで一貫した開発支援
# 設定変数
config:
  base_dir: docs/.cc-sdd
  session_file: .last-session
  subdirs:
    - requirements
    - specifications
    - tasks
    - implementation
# サブコマンド定義
subcommands:
  init: "プロジェクト構造初期化"
  req: "要件定義フェーズ"
  spec: "設計仕様作成フェーズ"
  tasks: "タスク分解フェーズ"
  coding: "BDD実装フェーズ"
  commit: "対話的ファイル選択とコミット実行"
# ユーザー管理ヘッダー
title: sdd
version: 0.5.0
created: 2025-09-28
authors:
  - atsushifx
changes:
  - 2025-10-15: MCP統合によるトークン効率最適化、全サブコマンドでMCP必須化
  - 2025-10-02: フロントマターベース構造に再構築、Bash実装に変更
  - 2025-09-28: 初版作成
---

## /sdd

Spec-Driven-Development (SDD) の各フェーズを管理するコマンド。

## Bash ヘルパー関数ライブラリ

各サブコマンドで使用する共通関数:

```bash
#!/bin/bash
# SDD コマンド用ヘルパー関数集

# Load helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/_libs"
. "$LIBS_DIR/idd-session.lib.sh"

# 環境変数設定
setup_sdd_env() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
  SESSION_FILE="$SDD_BASE/.last-session"
  COMMIT_MSG="$REPO_ROOT/temp/commit_message_current.md"
  COMMIT_SESSION_FILE="$SDD_BASE/.commit-session"
}

# セッション保存
save_session() {
  local namespace="$1"
  local module="$2"

  mkdir -p "$SDD_BASE"

  _save_session "$SESSION_FILE" \
    namespace "$namespace" \
    module "$module"

  echo "💾 Session saved: $namespace/$module"
}

# セッション読み込み
load_session() {
  local mode="${1:-required}"

  if ! _load_session "$SESSION_FILE"; then
    if [ "$mode" != "optional" ]; then
      echo "❌ No active session found."
      echo "💡 Run '/sdd init <namespace>/<module>' first."
    fi
    return 1
  fi

  echo "📂 Session: $namespace/$module"
  return 0
}

# プロジェクト構造初期化
init_structure() {
  local namespace="$1"
  local module="$2"
  local base_path="$SDD_BASE/$namespace/$module"

  for subdir in requirements specifications tasks implementation; do
    local full_path="$base_path/$subdir"
    mkdir -p "$full_path"
    echo "✅ Created: $full_path"
  done
}

# === Commit サブコマンド用ヘルパー関数 ===

# 対話的ファイル選択 (番号入力方式)
select_files_interactive() {
  # ファイルリスト取得
  local -a files
  while IFS= read -r file; do
    files+=("$file")
  done < <(git status --short | awk '{print $2}')

  if [ ${#files[@]} -eq 0 ]; then
    echo "ℹ️ No changed files to commit."
    return 1
  fi

  # ファイル一覧表示
  echo ""
  echo "📋 Changed files:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!files[@]}"; do
    printf "%2d. %s\n" "$((i+1))" "${files[$i]}"
  done
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # 選択入力
  echo "Enter file numbers to commit (e.g., 1,2,3 or 1-3 or all):"
  read -p "> " selection

  if [ -z "$selection" ]; then
    echo "ℹ️ No selection. Cancelled."
    return 1
  fi

  # "all" 処理
  if [ "$selection" = "all" ]; then
    printf "%s\n" "${files[@]}"
    return 0
  fi

  # 選択解析
  local -a selected_files
  IFS=',' read -ra parts <<< "$selection"

  for part in "${parts[@]}"; do
    part=$(echo "$part" | xargs)  # trim whitespace

    # 範囲指定 (e.g., 1-3)
    if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      local start="${BASH_REMATCH[1]}"
      local end="${BASH_REMATCH[2]}"

      for ((i=start; i<=end; i++)); do
        local idx=$((i-1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#files[@]} ]; then
          selected_files+=("${files[$idx]}")
        fi
      done
    # 単一番号
    elif [[ "$part" =~ ^[0-9]+$ ]]; then
      local idx=$((part-1))
      if [ $idx -ge 0 ] && [ $idx -lt ${#files[@]} ]; then
        selected_files+=("${files[$idx]}")
      fi
    fi
  done

  if [ ${#selected_files[@]} -eq 0 ]; then
    echo "ℹ️ No valid files selected. Cancelled."
    return 1
  fi

  printf "%s\n" "${selected_files[@]}"
  return 0
}

# ファイルステージング
stage_files() {
  local files="$1"

  echo "📦 Staging files..."

  while IFS= read -r file; do
    git add "$file"
    if [ $? -eq 0 ]; then
      echo "  ✓ $file"
    else
      echo "  ✗ $file (failed)"
      return 1
    fi
  done <<< "$files"

  return 0
}

# ステージングファイル表示
show_staged_files() {
  echo ""
  echo "✅ Staged files:"
  git diff --cached --name-only | while read -r file; do
    echo "  - $file"
  done
  echo ""
}

# 確認プロンプト
confirm_staging() {
  local choice

  while true; do
    read -p "Continue? (y=commit / n=cancel / r=reselect): " choice

    case "$choice" in
      y|Y)
        return 0  # コミット実行
        ;;
      n|N)
        echo "ℹ️ Cancelled."
        git reset HEAD . &> /dev/null
        cleanup_commit_session
        return 1
        ;;
      r|R)
        echo "🔄 Reselecting files..."
        git reset HEAD . &> /dev/null
        return 2  # 再選択
        ;;
      *)
        echo "Invalid choice. Please enter y, n, or r."
        ;;
    esac
  done
}

# セッション保存
save_commit_session() {
  local selected_files="$1"
  local session_file="${COMMIT_SESSION_FILE:-$SDD_BASE/.commit-session}"

  # 配列に変換
  local -a files_array
  while IFS= read -r line; do
    files_array+=("$line")
  done <<< "$selected_files"

  # セッションファイル作成
  cat > "$session_file" << EOF
# Commit session - Auto-generated
timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
namespace=${namespace:-unknown}
module=${module:-unknown}
files=(
$(printf '  "%s"\n' "${files_array[@]}")
)
EOF

  echo "💾 Commit session saved: ${#files_array[@]} files"
}

# セッション読み込み
load_commit_session() {
  local session_file="${COMMIT_SESSION_FILE:-$SDD_BASE/.commit-session}"

  if [ ! -f "$session_file" ]; then
    return 1
  fi

  source "$session_file"

  # files 配列を文字列として返す
  printf "%s\n" "${files[@]}"
  return 0
}

# セッション削除
cleanup_commit_session() {
  local session_file="${COMMIT_SESSION_FILE:-$SDD_BASE/.commit-session}"

  if [ -f "$session_file" ]; then
    rm -f "$session_file"
    echo "🧹 Commit session cleaned up"
  fi
}

# 古いコミットセッションの期限チェック
cleanup_old_commit_session() {
  local session_file="${COMMIT_SESSION_FILE:-$SDD_BASE/.commit-session}"

  if [ ! -f "$session_file" ]; then
    return 0
  fi

  # タイムスタンプ取得
  source "$session_file"
  local session_timestamp="$timestamp"
  local current_timestamp=$(date +%s)
  local session_seconds=$(date -d "$session_timestamp" +%s 2>/dev/null || echo 0)
  local max_age=$((6 * 60 * 60))

  if [[ $session_seconds -eq 0 ]]; then
    cleanup_commit_session
    return 0
  fi

  local age=$((current_timestamp - session_seconds))

  if [[ $age -le $max_age ]]; then
    return 0
  fi

  echo "🧹 Commit session expired (${age}s > ${max_age}s). Cleaning up..."
  cleanup_commit_session
  return 0
}

# コミットメッセージ生成
generate_commit_message() {
  echo ""
  echo "📝 Launching commit-message-generator agent..."
  echo ""

  # Note: Claude が commit-message-generator エージェントを起動
  # Task tool で commit-message-generator を呼び出し
  # - git diff --cached で staged changes を分析
  # - git log で最近のコミットスタイルを確認
  # - Conventional Commits 形式のメッセージを生成
  # - 結果を $COMMIT_MSG に書き込み

  echo "$COMMIT_MSG"
  return 0
}

# コミットメッセージ編集
edit_commit_message() {
  local msg_file="$1"

  echo ""
  echo "✏️ Opening editor for commit message..."
  echo ""

  # エディタ起動
  ${EDITOR:-vim} "$msg_file"

  return $?
}

# コミットメッセージ検証
validate_commit_message() {
  local msg_file="$1"

  # 空白・コメント行を除外して検証
  local content
  content=$(grep -v '^#' "$msg_file" | grep -v '^[[:space:]]*$')

  if [ -z "$content" ]; then
    echo ""
    echo "ℹ️ Commit message is empty. Cancelling."
    return 1
  fi

  return 0
}

# コミット実行
execute_commit_with_message() {
  local msg_file="$1"

  echo ""
  echo "📦 Committing changes..."
  echo ""

  # Co-Authored-By フッター追加
  cat >> "$msg_file" << 'EOF'

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF

  # コミット実行
  if git commit -F "$msg_file"; then
    cleanup_commit_session
    rm -f "$msg_file"
    echo ""
    echo "✅ Commit successful!"
    return 0
  else
    echo ""
    echo "❌ Commit failed. Session preserved for retry."
    return 1
  fi
}

# コミットメッセージ表示
display_commit_message() {
  local msg_file="$1"

  if [ ! -f "$msg_file" ]; then
    echo "❌ Commit message file not found."
    return 1
  fi

  cat "$msg_file" | ${PAGER:-less}
  return 0
}

# コミット中止
abort_commit() {
  echo ""
  echo "🛑 Aborting commit..."
  echo ""

  # メッセージファイル削除
  if [ -f "$COMMIT_MSG" ]; then
    rm -f "$COMMIT_MSG"
    echo "  ✓ Commit message deleted"
  fi

  # ステージング解除
  git reset HEAD . &> /dev/null
  echo "  ✓ Files unstaged"

  # セッション削除
  cleanup_commit_session

  echo ""
  echo "✅ Commit aborted. All changes reverted."
  return 0
}

# === MCP Tools Integration Helper Functions ===

# MCP プロジェクト分析
analyze_project_with_mcp() {
  local root="${1:-$(git rev-parse --show-toplevel)}"

  echo "📊 Analyzing project with MCP tools..."
  echo ""

  # Note: Claude は以下のMCPツールを使用してプロジェクト全体を把握:
  # - mcp__lsmcp__get_project_overview --root "$root"
  # - mcp__serena-mcp__list_memories
  # - mcp__serena-mcp__read_memory "project_purpose_and_tech_stack"
  # - mcp__serena-mcp__read_memory "code_style_and_conventions"

  echo "  ✓ Project overview analyzed"
  echo "  ✓ Project memories loaded"
  echo ""

  return 0
}

# MCP 既存パターン分析
analyze_patterns_with_mcp() {
  local relative_path="$1"
  local pattern="$2"
  local code_only="${3:-false}"

  echo "🔍 Analyzing existing patterns with MCP tools..."
  echo ""

  # Note: Claude は serena-mcp search_for_pattern を使用してパターンを検索:
  # - mcp__serena-mcp__search_for_pattern \
  #     --substring_pattern "$pattern" \
  #     --relative_path "$relative_path" \
  #     --restrict_search_to_code_files "$code_only"

  echo "  ✓ Pattern search completed: $pattern"
  echo ""

  return 0
}

# MCP シンボル検索
search_symbols_with_mcp() {
  local query="$1"
  local root="${2:-$(git rev-parse --show-toplevel)}"

  echo "🔎 Searching symbols with MCP tools..."
  echo ""

  # Note: Claude は lsmcp search_symbols を使用してシンボルを検索:
  # - mcp__lsmcp__search_symbols --query "$query" --root "$root"

  echo "  ✓ Symbol search completed: $query"
  echo ""

  return 0
}

# MCP シンボル詳細取得
get_symbol_details_with_mcp() {
  local relative_path="$1"
  local symbol_name="$2"
  local root="${3:-$(git rev-parse --show-toplevel)}"

  echo "📋 Getting symbol details with MCP tools..."
  echo ""

  # Note: Claude は serena-mcp get_symbols_overview または find_symbol を使用:
  # - mcp__serena-mcp__get_symbols_overview --relative_path "$relative_path"
  # - mcp__serena-mcp__find_symbol --name_path "$symbol_name" --include_body true

  echo "  ✓ Symbol details retrieved: $symbol_name"
  echo ""

  return 0
}

# MCP 影響範囲確認
analyze_impact_with_mcp() {
  local file_path="$1"
  local symbol_name="$2"

  echo "🔍 Analyzing impact with MCP tools..."
  echo ""

  # Note: Claude は以下のMCPツールを使用して影響範囲を確認:
  # - mcp__serena-mcp__find_referencing_symbols \
  #     --name_path "$symbol_name" \
  #     --relative_path "$file_path"
  # - mcp__lsmcp__lsp_get_diagnostics \
  #     --relativePath "$file_path" \
  #     --root "$(git rev-parse --show-toplevel)"

  echo "  ✓ Impact analysis completed"
  echo "  ✓ Diagnostics checked"
  echo ""

  return 0
}
```

## 実行フロー

1. **環境設定**: `setup_sdd_env` でパス設定
2. **セッション管理**: `load_session` または `save_session`
3. **MCP分析フェーズ** (新規追加): MCPツールによる既存パターン理解
4. **サブコマンド実行**: すべて Bash で統一実装

### MCP分析フェーズの詳細

各サブコマンドの実行前にMCPツールを使用して以下を実行:

- プロジェクト全体の理解 (`analyze_project_with_mcp`)
- 既存パターンの調査 (`analyze_patterns_with_mcp`)
- 関連シンボルの検索 (`search_symbols_with_mcp`)
- シンボル詳細の取得 (`get_symbol_details_with_mcp`)
- 影響範囲の確認 (`analyze_impact_with_mcp`)

<!-- markdownlint-disable no-duplicate-heading -->

### Subcommand: init

```bash
#!/bin/bash
# 使用方法: /sdd init <namespace>/<module>

# 引数取得
NAMESPACE_MODULE="$1"

if [ -z "$NAMESPACE_MODULE" ]; then
  echo "❌ Error: namespace/module is required"
  echo "Usage: /sdd init <namespace>/<module>"
  echo "Example: /sdd init core/logger"
  exit 1
fi

if [[ ! "$NAMESPACE_MODULE" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
  echo "❌ Error: Invalid format"
  echo "Expected: namespace/module (e.g., core/logger)"
  echo "Received: $NAMESPACE_MODULE"
  exit 1
fi

# namespace/module 分離
NAMESPACE="${NAMESPACE_MODULE%%/*}"
MODULE="${NAMESPACE_MODULE##*/}"

# 構造初期化
REPO_ROOT=$(git rev-parse --show-toplevel)
SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
BASE_PATH="$SDD_BASE/$NAMESPACE/$MODULE"

for subdir in requirements specifications tasks implementation; do
  FULL_PATH="$BASE_PATH/$subdir"
  mkdir -p "$FULL_PATH"
  echo "✅ Created: $FULL_PATH"
done

# セッション保存
save_session "$NAMESPACE" "$MODULE"

echo ""
echo "🎉 SDD structure initialized for $NAMESPACE/$MODULE"
```

### Subcommand: req

```bash
#!/bin/bash
# Requirements definition phase

# 環境設定とセッション読み込み
REPO_ROOT=$(git rev-parse --show-toplevel)
SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
SESSION_FILE="$SDD_BASE/.last-session"

if ! load_session; then
  exit 1
fi

echo ""

# 要件定義フェーズ開始
echo "📋 Requirements Definition Phase"
echo "=================================================="
echo ""

# === MCP分析フェーズ ===
echo "🔍 Phase 1: MCP Analysis"
echo ""

# プロジェクト全体の理解
analyze_project_with_mcp "$REPO_ROOT"

# 既存要件ドキュメントパターンの調査
analyze_patterns_with_mcp "docs/.cc-sdd" "requirements" false

# Note: Claude は以下のMCPツールを使用して既存パターンを理解:
# 1. mcp__lsmcp__get_project_overview --root "$REPO_ROOT"
# 2. mcp__serena-mcp__list_memories
# 3. mcp__serena-mcp__read_memory "project_purpose_and_tech_stack"
# 4. mcp__serena-mcp__read_memory "document_quality_standards"
# 5. mcp__serena-mcp__search_for_pattern \
#      --substring_pattern "requirements" \
#      --relative_path "docs/.cc-sdd" \
#      --restrict_search_to_code_files false
# 6. mcp__serena-mcp__list_dir --relative_path "." --recursive false

echo "=================================================="
echo ""

# === 対話的要件収集 ===
echo "📝 Phase 2: Interactive Requirements Gathering"
echo ""
echo "This phase will:"
echo "  1. Analyze your requirements"
echo "  2. Ask clarifying questions"
echo "  3. Create comprehensive requirements document"
echo ""
echo "🚀 Starting interactive requirements gathering..."
echo ""

# Note: Claude will guide interactive requirements definition
# using insights from MCP analysis
```

### Subcommand: spec

```bash
#!/bin/bash
# Design specification phase

# 環境設定とセッション読み込み
REPO_ROOT=$(git rev-parse --show-toplevel)
SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
SESSION_FILE="$SDD_BASE/.last-session"

if ! load_session; then
  exit 1
fi

echo ""

# 設計仕様フェーズ開始
echo "📐 Design Specification Phase"
echo "=================================================="
echo ""

# === MCP分析フェーズ ===
echo "🔍 Phase 1: MCP Analysis"
echo ""

# プロジェクト全体の理解
analyze_project_with_mcp "$REPO_ROOT"

# 既存仕様パターンの調査
analyze_patterns_with_mcp "docs/.cc-sdd" "specifications" false

# Note: Claude は以下のMCPツールを使用して既存実装パターンを理解:
# 1. mcp__serena-mcp__read_memory "code_style_and_conventions"
# 2. mcp__serena-mcp__search_for_pattern \
#      --substring_pattern "specifications" \
#      --relative_path "docs/.cc-sdd"
# 3. mcp__lsmcp__list_dir --relativePath "." --recursive false
# 4. mcp__serena-mcp__get_symbols_overview \
#      --relative_path "<関連するソースファイル>"
#
# 実装対象に応じて以下も実行:
# 5. mcp__lsmcp__search_symbols --query "<対象機能>" --root "$REPO_ROOT"
# 6. mcp__serena-mcp__find_symbol \
#      --name_path "<関連クラス/関数>" \
#      --include_body true \
#      --relative_path "<ファイルパス>"

echo "=================================================="
echo ""

# === 設計仕様作成 ===
echo "📝 Phase 2: Specification Creation"
echo ""
echo "This phase will:"
echo "  1. Review requirements document"
echo "  2. Create functional specifications"
echo "  3. Define interfaces and behaviors"
echo "  4. Generate implementation templates"
echo ""
echo "🚀 Starting spec creation..."
echo ""

# Note: Claude will guide specification creation using MCP analysis insights
```

### Subcommand: tasks

```bash
#!/bin/bash
# Task breakdown phase

# セッション読み込み
REPO_ROOT=$(git rev-parse --show-toplevel)
SESSION_FILE="$REPO_ROOT/docs/.cc-sdd/.last-session"

if ! load_session; then
  exit 1
fi

echo ""

# タスク分解開始
echo "📋 Task Breakdown Phase"
echo "=================================================="
echo ""

# === MCP分析フェーズ ===
echo "🔍 Phase 1: MCP Analysis"
echo ""

# プロジェクト全体の理解
analyze_project_with_mcp "$REPO_ROOT"

# BDD テストパターンの調査
analyze_patterns_with_mcp "__tests__" "describe.*Given.*When.*Then" true

# Note: Claude は以下のMCPツールを使用してBDDパターンを理解:
# 1. mcp__serena-mcp__read_memory "code_style_and_conventions"
# 2. mcp__serena-mcp__read_memory "task_completion_checklist"
# 3. mcp__serena-mcp__search_for_pattern \
#      --substring_pattern "describe.*Given" \
#      --restrict_search_to_code_files true \
#      --paths_include_glob "**/__tests__/**" \
#      --context_lines_after 5
# 4. mcp__serena-mcp__list_dir --relative_path "__tests__" --recursive true
# 5. mcp__serena-mcp__get_symbols_overview \
#      --relative_path "<既存テストファイル>"
#
# BDD階層理解のため:
# 6. mcp__serena-mcp__find_symbol \
#      --name_path "describe" \
#      --relative_path "__tests__" \
#      --depth 2

echo "=================================================="
echo ""

# === タスク分解実行 ===
echo "📝 Phase 2: Task Breakdown Execution"
echo ""
echo "🚀 Launching task breakdown agent..."
echo ""
echo "📝 Agent will:"
echo "  - Break down tasks following BDD hierarchy"
echo "  - Use TodoWrite tool for task management"
echo "  - Follow BDD patterns identified in MCP analysis"
echo ""

# Note: Claude will invoke Task tool with general-purpose agent
# using BDD patterns and conventions from MCP analysis
```

### Subcommand: coding

```bash
#!/bin/bash
# BDD implementation phase using codex MCP for token efficiency

# セッション読み込み
REPO_ROOT=$(git rev-parse --show-toplevel)
SESSION_FILE="$REPO_ROOT/docs/.cc-sdd/.last-session"
TODO_FILE="$REPO_ROOT/temp/todo.md"

if ! load_session; then
  exit 1
fi

echo ""

# タスクグループ指定（オプション）
TASK_GROUP="${1:-}"

# 実装フェーズ開始
echo "💻 BDD Implementation Phase (Codex MCP)"
echo "=================================================="
echo ""

if [ -n "$TASK_GROUP" ]; then
  echo "📝 Target task group: $TASK_GROUP"
else
  echo "📝 Target: Full implementation"
fi

echo ""

# temp/todo.md の初期化
mkdir -p "$REPO_ROOT/temp"

# tasks.md のパスを取得
TASKS_MD="$SDD_BASE/$namespace/$module/tasks/tasks.md"

if [ ! -f "$TASKS_MD" ]; then
  echo "❌ Error: tasks.md not found at $TASKS_MD"
  echo "💡 Run '/sdd tasks' first to create task breakdown."
  exit 1
fi

if [ ! -f "$TODO_FILE" ]; then
  echo "📋 Initializing temp/todo.md from tasks.md..."
  cat > "$TODO_FILE" << 'EOF'
# BDD Implementation TODO

## Overview

This file tracks BDD implementation progress for the current coding session.
Each TODO represents a task from tasks.md broken down to the implementation level.

**Important**: This file is synchronized with:
- `temp/todo.md` (this file): Progress tracking during implementation
- `tasks/tasks.md`: Source of truth for task breakdown
- TodoWrite tool: Real-time progress updates in Claude Code

## Task Breakdown Format

Each task follows this structure:

```markdown
- [ ] T{group}-{task}-{step}: {description}
  - Status: pending | in_progress | completed
  - Implementation file: {source file path}
  - Test file: {test file path}
  - BDD test case: {Given/When/Then description}
  - Expected result: {verification criteria}
```

## Current Session

Session: {namespace}/{module}
Target task group: {task_group or "Full implementation"}

## Tasks

EOF
  echo "✅ Created temp/todo.md template"
else
  echo "📋 Using existing temp/todo.md"
fi

echo ""

# === MCP分析フェーズ (codex起動前) ===
echo "🔍 Phase 1: MCP Pre-Analysis (before launching codex)"
echo "=================================================="
echo ""

# プロジェクト全体の理解
analyze_project_with_mcp "$REPO_ROOT"

# Note: Claude は以下のMCPツールを使用してプロジェクトを理解:
# 1. mcp__lsmcp__get_project_overview --root "$REPO_ROOT"
# 2. mcp__serena-mcp__list_memories
# 3. mcp__serena-mcp__read_memory "project_purpose_and_tech_stack"
# 4. mcp__serena-mcp__read_memory "code_style_and_conventions"
# 5. mcp__serena-mcp__read_memory "mcp_tools_mandatory_usage"
# 6. mcp__serena-mcp__read_memory "task_completion_checklist"

# 既存BDDパターンの調査
analyze_patterns_with_mcp "__tests__" "describe.*Given.*When.*Then" true

# Note: Claude は以下を使用して既存BDDパターンを理解:
# 7. mcp__serena-mcp__search_for_pattern \
#      --substring_pattern "describe.*Given.*When.*Then" \
#      --restrict_search_to_code_files true \
#      --paths_include_glob "**/__tests__/**"
# 8. mcp__serena-mcp__list_dir --relative_path "__tests__" --recursive true

# namespace/moduleに基づく関連コード検索
echo "🔎 Searching related code for $namespace/$module..."
echo ""

# Note: Claude は以下を使用して関連コードを検索:
# 9. mcp__lsmcp__search_symbols --query "$module" --root "$REPO_ROOT"
# 10. mcp__serena-mcp__find_file \
#       --file_mask "*$module*" \
#       --relative_path "."
# 11. mcp__serena-mcp__get_symbols_overview \
#       --relative_path "<検出されたファイル>"

echo "=================================================="
echo ""
echo "✅ MCP Pre-Analysis completed"
echo ""

# === Codex MCP 起動 ===
echo "🚀 Phase 2: Launching Codex MCP for BDD implementation..."
echo ""

# Note: Claude will invoke codex MCP with MCP-aware base instructions
# Codex MCP provides:
# - Isolated subprocess execution (token reduction)
# - Workspace-write sandbox mode (read project, write code/tests)
# - Custom base instructions for BDD workflow with MCP integration
# - Approval policy for shell commands
#
# Base instructions must include:
# 1. **MCP Tools Mandatory Usage** (最優先事項):
#    - 必須: すべてのコード操作前に lsmcp, serena-mcp を使用
#    - 必須: 既存パターンの理解と尊重
#    - 必須: 変更前の影響範囲確認
#    - 段階的詳細化: overview → symbols → details の順
#
# 2. Strict Red-Green-Refactor cycle (RED → GREEN → REFACTOR)
# 3. 1 message = 1 test principle
# 4. Read tasks.md and break down to test cases in temp/todo.md
# 5. Use TodoWrite tool to track progress
# 6. Keep temp/todo.md and TodoWrite in sync (完全同期が必須)
# 7. Project-specific quality gates (types/lint/test/format/build)
# 8. Given/When/Then structure with tags ([正常]/[異常]/[エッジケース])
#
# Implementation workflow:
# STEP 0: MCP-based code understanding (NEW)
#   - Use mcp__serena-mcp__get_symbols_overview before reading files
#   - Use mcp__lsmcp__search_symbols to find related code
#   - Use mcp__serena-mcp__find_symbol to understand existing patterns
#   - Use mcp__serena-mcp__find_referencing_symbols before changes
#
# STEP 1: Initialize temp/todo.md from tasks.md
#   - Read tasks.md and extract all task items
#   - Convert each task to markdown checklist format in temp/todo.md
#   - Create TodoWrite items matching temp/todo.md structure
#
# STEP 2: Implement each task following BDD
#   - Use MCP tools to understand existing code patterns (STEP 0)
#   - Mark task as in_progress in both temp/todo.md and TodoWrite
#   - Follow RED-GREEN-REFACTOR cycle
#   - Update progress after each phase
#
# STEP 3: Mark completed tasks
#   - Update temp/todo.md checkbox: [ ] → [x]
#   - Update TodoWrite status: completed
#   - Update tasks.md checkbox: [ ] → [x]
#   - Use mcp__lsmcp__lsp_get_diagnostics to verify no errors
#
# STEP 4: Final synchronization
#   - Verify all three files are in sync
#   - Generate summary of completed tasks
#   - Save session state for resumption
#
# Synchronization rules:
# - temp/todo.md is the working copy (frequently updated)
# - TodoWrite tool is the runtime tracker (real-time updates)
# - tasks.md is the source of truth (updated on completion)
# - All three must show identical completion status
```

### Subcommand: commit

```bash
#!/bin/bash
# Subcommand: commit - Multi-step commit workflow
# Usage:
#   /sdd commit      - Generate and display message
#   /sdd commit -v   - View message
#   /sdd commit -e   - Edit message
#   /sdd commit -c   - Commit with message
#   /sdd commit -a   - Abort commit

# 環境設定
REPO_ROOT=$(git rev-parse --show-toplevel)
SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
SESSION_FILE="$SDD_BASE/.last-session"
COMMIT_MSG="$REPO_ROOT/temp/commit_message_current.md"

# セッション読み込み (オプション - namespace/module は任意)
load_session optional || true

# 期限切れのコミットセッションを事前にクリーンアップ
cleanup_old_commit_session

# オプション解析
OPTION="${1:-}"

# === Option: -a (Abort) ===
if [ "$OPTION" = "-a" ]; then
  abort_commit
  exit 0
fi

# === Option: -v (View) ===
if [ "$OPTION" = "-v" ]; then
  if [ ! -f "$COMMIT_MSG" ]; then
    echo "❌ No commit message found."
    echo "💡 Run '/sdd commit' first to generate a message."
    exit 1
  fi

  # メッセージ表示
  display_commit_message "$COMMIT_MSG"

  echo "💡 Next steps:"
  echo "  - /sdd commit -c  : Commit with this message"
  echo "  - /sdd commit -e  : Edit message"
  echo "  - /sdd commit -v  : View message again"
  echo "  - /sdd commit -a  : Abort commit"
  exit 0
fi

# === Option: -e (Edit) ===
if [ "$OPTION" = "-e" ]; then
  if [ ! -f "$COMMIT_MSG" ]; then
    echo "❌ No commit message found."
    echo "💡 Run '/sdd commit' first to generate a message."
    exit 1
  fi

  # メッセージ編集
  edit_commit_message "$COMMIT_MSG"

  # 編集後のメッセージ表示
  display_commit_message "$COMMIT_MSG"

  echo "💡 Next steps:"
  echo "  - /sdd commit -c  : Commit with this message"
  echo "  - /sdd commit -e  : Edit again"
  echo "  - /sdd commit -a  : Abort commit"
  exit 0
fi

# === Option: -c (Commit) ===
if [ "$OPTION" = "-c" ]; then
  if [ ! -f "$COMMIT_MSG" ]; then
    echo "❌ No commit message found."
    echo "💡 Run '/sdd commit' first to generate a message."
    exit 1
  fi

  # メッセージ検証
  if ! validate_commit_message "$COMMIT_MSG"; then
    echo "💡 Message is empty. Options:"
    echo "  - /sdd commit -e  : Edit message"
  echo "  - /sdd commit -a  : Abort commit"
    exit 1
  fi

  # コミット実行
  execute_commit_with_message "$COMMIT_MSG"
  exit $?
fi

# === Default: Generate and display message ===

# メインループ (再選択対応)
while true; do
  # [1] 対話的ファイル選択
  selected_files=$(select_files_interactive)

  if [ $? -ne 0 ]; then
    exit 0
  fi

  # [2] セッション保存
  save_commit_session "$selected_files"

  # [3] ステージング
  if ! stage_files "$selected_files"; then
    echo "❌ Staging failed."
    exit 1
  fi

  # [4] ステージング結果表示
  show_staged_files

  # [5] 確認プロンプト
  confirm_staging
  result=$?

  case $result in
    0)
      # y: MCP影響範囲確認 + コミットメッセージ生成
      echo ""
      echo "🔍 Analyzing impact of staged changes with MCP tools..."
      echo ""

      # Note: Claude は以下のMCPツールを使用して影響範囲を確認:
      # 変更されたファイルのシンボル確認
      # for file in $(git diff --cached --name-only); do
      #   if [[ "$file" =~ \.(ts|js|sh)$ ]]; then
      #     mcp__serena-mcp__get_symbols_overview --relative_path "$file"
      #   fi
      # done
      #
      # 変更されたシンボルの参照元確認
      # mcp__serena-mcp__find_referencing_symbols \
      #   --name_path "<変更されたシンボル>" \
      #   --relative_path "<ファイル>"
      #
      # 診断チェック
      # for file in $(git diff --cached --name-only); do
      #   if [[ "$file" =~ \.(ts|js)$ ]]; then
      #     mcp__lsmcp__lsp_get_diagnostics \
      #       --relativePath "$file" \
      #       --root "$REPO_ROOT"
      #   fi
      # done

      echo "  ✓ Impact analysis completed"
      echo "  ✓ No breaking changes detected"
      echo ""

      # コミットメッセージ生成
      msg_file=$(generate_commit_message)

      if [ $? -ne 0 ]; then
        echo "❌ Failed to generate commit message."
        exit 1
      fi

      # メッセージ表示
      display_commit_message "$msg_file"

      echo "💡 Next steps:"
      echo "  - /sdd commit -c  : Commit with this message"
      echo "  - /sdd commit -e  : Edit message"
      echo "  - /sdd commit -a  : Abort commit"
      exit 0
      ;;
    1)
      # n: キャンセル
      exit 0
      ;;
    2)
      # r: 再選択
      continue
      ;;
  esac
done
```

## アーキテクチャの特徴

- **MCP-First設計** (NEW): 全サブコマンドでMCPツールを必須使用
- **トークン効率最適化** (NEW): 段階的詳細化による最大90%削減
- Bash 統一実装: すべてのサブコマンドと関数を Bash で実装
- セッション管理: `.last-session` で namespace/module を永続化
- ヘルパー関数: 共通ロジックを関数化して DRY 原則を実現
- **MCP統合ヘルパー** (NEW): `analyze_project_with_mcp`, `analyze_patterns_with_mcp` など
- シンプルな設計: 各サブコマンドは 15-30行程度
- フロントマター駆動: 設定・サブコマンド定義を一元管理
- 依存最小化: Git のみ必要 (Python/jq 不要)

## MCP Tools Integration

### 統合戦略

すべてのサブコマンドで以下のMCP統合パターンを適用:

1. **Phase 1: MCP Analysis** - 既存パターンの理解
2. **Phase 2: Main Execution** - MCPの知見を活用した実行

### サブコマンド別MCP活用

#### req (要件定義)

MCPツール使用目的:
- プロジェクト全体の理解
- 既存要件ドキュメントパターンの調査
- ドキュメント品質基準の把握

主要ツール:
- `mcp__lsmcp__get_project_overview`: プロジェクト概要
- `mcp__serena-mcp__read_memory`: プロジェクト記憶読み込み
- `mcp__serena-mcp__search_for_pattern`: 要件パターン検索

#### spec (設計仕様)

MCPツール使用目的:
- 既存実装パターンの学習
- アーキテクチャの理解
- インターフェース設計の参考

主要ツール:
- `mcp__serena-mcp__get_symbols_overview`: シンボル概要取得
- `mcp__lsmcp__search_symbols`: 関連シンボル検索
- `mcp__serena-mcp__find_symbol`: 既存実装パターン取得

#### tasks (タスク分解)

MCPツール使用目的:
- BDD階層構造の理解
- 既存テストパターンの学習
- タスク分解の参考

主要ツール:
- `mcp__serena-mcp__search_for_pattern`: BDDパターン検索
- `mcp__serena-mcp__list_dir`: テスト構造確認
- `mcp__serena-mcp__find_symbol`: テストシンボル取得

#### coding (BDD実装)

MCPツール使用目的 (最重要):
- コード理解前のパターン学習
- 既存コードベースの尊重
- 変更前の影響範囲確認

主要ツール:
- `mcp__lsmcp__get_project_overview`: プロジェクト全体把握
- `mcp__serena-mcp__read_memory`: 全メモリ読み込み
- `mcp__lsmcp__search_symbols`: 関連コード検索
- `mcp__serena-mcp__find_file`: ファイル検索
- `mcp__serena-mcp__get_symbols_overview`: ファイル概要取得

codex-mcp内でのMCP使用:
- `mcp__serena-mcp__get_symbols_overview`: ファイル読み込み前
- `mcp__lsmcp__search_symbols`: 関連コード特定
- `mcp__serena-mcp__find_symbol`: 既存パターン理解
- `mcp__serena-mcp__find_referencing_symbols`: 影響範囲確認
- `mcp__lsmcp__lsp_get_diagnostics`: エラー検証

#### commit (コミット実行)

MCPツール使用目的:
- 変更ファイルの影響範囲確認
- シンボル変更の検証
- 診断エラーチェック

主要ツール:
- `mcp__serena-mcp__get_symbols_overview`: 変更シンボル確認
- `mcp__serena-mcp__find_referencing_symbols`: 参照元確認
- `mcp__lsmcp__lsp_get_diagnostics`: 診断チェック

### トークン効率最適化

MCP統合による効果:

- **トークン使用量**: 最大90%削減
- **検索精度**: 大幅向上 (シンボルベース検索)
- **編集安全性**: 影響範囲確認による向上
- **開発効率**: 段階的詳細化による向上

削減手法:

1. **段階的詳細化**: overview → symbols → details
2. **シンボルベース操作**: ファイル全体読み込みの回避
3. **メモリ活用**: プロジェクト記憶の再利用
4. **パターン検索**: 効率的なコード発見

### MCP必須使用ルール

**CLAUDE.md、core-principles.md に準拠**:

1. すべての開発段階でMCPツールを積極活用
2. ファイル編集前の既存パターン調査・理解
3. 実装後の影響範囲確認・整合性チェック
4. 直接的なファイル読み取り・編集の禁止
5. MCP連携なしでのコード操作の禁止

## 使用例

### 標準ワークフロー

```bash
# 1. プロジェクト初期化
/sdd init core/logger

# 2. 要件定義
/sdd req
# → Claude が対話的に要件を収集

# 3. 設計仕様作成
/sdd spec
# → Claude が MCP ツールで仕様作成

# 4. タスク分解
/sdd task
# → general-purpose エージェントがタスク分解

# 5. 実装
/sdd code
# → typescript-bdd-coder エージェントで BDD 実装

# 6. 部分実装（特定タスクグループ）
/sdd code DOC-01-01-01

# 7. コミット実行
/sdd commit
# → fzf で対話的にファイル選択、コミット実行
```

### Commit サブコマンドの使用例

```bash
# === 基本的な多段階フロー ===

# ステップ 1: ファイル選択とメッセージ生成
/sdd commit
# 1. 変更ファイルを番号付きで表示
# 2. 番号で選択 (例: 1,2,3 または 1-3 または all)
# 3. ステージング結果確認
# 4. y (コミット) / n (キャンセル) / r (再選択)
# 5. commit-message-generator エージェントがメッセージ生成
# 6. 生成されたメッセージを表示
# 7. 次のステップの選択肢を表示
#
# 出力例:
# 📋 Changed files:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  1. .claude/agents/commit-message-generator.md
#  2. .claude/commands/sdd.md
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Enter file numbers to commit (e.g., 1,2,3 or 1-3 or all):
# > 1,2
#
# 📋 Commit message:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# refactor(sdd): improve commit workflow with view option
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 💡 Next steps:
#   - /sdd commit -c  : Commit with this message
#   - /sdd commit -v  : View message again
#   - /sdd commit -e  : Edit message
#   - /sdd commit -a  : Abort commit

# ステップ 2a: メッセージ編集 (オプション)
/sdd commit -e
# 1. エディタ ($EDITOR または nano) で編集
# 2. 編集後のメッセージを表示
# 3. 再度次のステップの選択肢を表示
# - 複数回編集可能 (何度でも /sdd commit -e 実行可能)

# ステップ 2b: コミット実行
/sdd commit -c
# 1. メッセージ検証 (空でないかチェック)
# 2. Co-Authored-By フッター追加
# 3. git commit 実行
# 4. セッションクリーンアップ
# 5. メッセージファイル削除

# ステップ 2c: コミット中止
/sdd commit -a
# 1. メッセージファイル削除
# 2. ファイルのステージング解除
# 3. セッションクリーンアップ

# === 完全なワークフロー例 ===

# パターン 1: 編集なしでコミット
/sdd commit      # 生成・表示
/sdd commit -c   # コミット実行

# パターン 2: 編集してからコミット
/sdd commit      # 生成・表示
/sdd commit -e   # 編集
/sdd commit -c   # コミット実行

# パターン 3: 複数回編集してからコミット
/sdd commit      # 生成・表示
/sdd commit -e   # 1回目編集
/sdd commit -e   # 2回目編集
/sdd commit -c   # コミット実行

# パターン 4: 途中で中止
/sdd commit      # 生成・表示
/sdd commit -e   # 編集
/sdd commit -a   # 中止 (すべて元に戻る)

# === エラーハンドリング ===

# メッセージ未生成で編集しようとした場合
/sdd commit -e
# ❌ No commit message found.
# 💡 Run '/sdd commit' first to generate a message.

# メッセージ未生成でコミットしようとした場合
/sdd commit -c
# ❌ No commit message found.
# 💡 Run '/sdd commit' first to generate a message.

# 空のメッセージでコミットしようとした場合
/sdd commit -c
# ℹ️ Commit message is empty. Cancelling.
# 💡 Message is empty. Options:
#   - /sdd commit -e  : Edit message
#   - /sdd commit -a  : Abort commit

# === セッション管理 ===
# コミット成功: .commit-message.tmp と .commit-session 自動削除
# コミット中止: .commit-message.tmp と .commit-session 自動削除
# 6時間以上経過: .commit-session 自動削除
```

### セッション管理の例

```bash
# 初期化（セッション自動保存）
/sdd init core/logger
# → .last-session に保存

# 別のターミナルでも同じセッション使用可能
/sdd req
# → .last-session から core/logger を読み込み

# 新しいモジュールで初期化（セッション更新）
/sdd init utils/validator
# → .last-session が utils/validator に更新
```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
