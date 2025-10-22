---
# Claude Code 必須要素
allowed-tools:
  - Bash(*)
  - Read(*)
  - Write(temp/idd/issues/**)
  - SlashCommand(/_helpers:_get-issue-types)
  - SlashCommand(/_helpers:_select-from-list)
  - Task(commit-message-generator)
  - mcp__codex-mcp__codex
argument-hint: [subcommand (new|commit)] [options (--base <domain>)]
description: Issue選択からブランチ作成・コミットまでの統合ワークフロー

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  branch_session_file: temp/idd/issues/.branch.session

# ag-logger プロジェクト要素
title: /idd:issue:branch
version: 1.3.0
created: 2025-10-23
authors:
  - atsushifx
changes:
  - 2025-10-23: v1.3.0 - newサブコマンド統合完了 (T7: 完全な処理フロー, 9テスト全合格)
  - 2025-10-23: v1.2.0 - ドメイン検出機能実装 (T3: detect_domain)
  - 2025-10-23: v1.1.0 - サブコマンドルーティング実装 (T2)
  - 2025-10-23: v1.0.0 - 初版作成 (T1: 基本構造とセッション管理)
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd:issue:branch - Issue統合ワークフロー

選択されたIssueから、ブランチ提案、ブランチ作成、コミット統合までの一連のワークフローを管理します。

## 初期設定

コマンド実行の最初に、以下の初期設定を行います:

```bash
#!/bin/bash
set -euo pipefail

# Load helper libraries
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

. "$LIBS_DIR/filename-utils.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"

# Issue-specific environment setup
setup_repo_env
ISSUES_DIR=$(get_temp_dir "idd/issues")
SESSION_FILE="$ISSUES_DIR/.last.session"
BRANCH_SESSION_FILE="$ISSUES_DIR/.branch.session"
```

この初期設定により:

- `set -euo pipefail`: エラー時の即座終了、未定義変数の検出、パイプラインエラーの伝播
- リポジトリルートを動的に取得し、ライブラリパスを構築
- 必要なライブラリを事前に読み込み、全ステップで利用可能に
- Issue管理用のディレクトリとセッションファイルのパスを設定
- ブランチ提案用の専用セッションファイルを設定

## セッション管理

### Issueセッション読み込み

```bash
# Load issue session
if ! _load_issue_session "$SESSION_FILE"; then
  exit 1
fi

# Available variables after loading:
# - filename: Issue draft filename (without extension)
# - issue_number: GitHub Issue number (empty if not pushed)
# - TITLE: Issue title
# - ISSUE_TYPE: Issue type (feature, bug, enhancement, task)
# - COMMIT_TYPE: Commit type (feat, fix, refactor, etc.)
# - BRANCH_TYPE: Branch type (feat, fix, refactor, etc.)
# - command: Last executed command
```

セッションロードが失敗した場合:

```
❌ No issue selected.
💡 Run '/idd:issue:list' to select an issue, or
   '/idd:issue:new' to create one.
```

## サブコマンドルーティング

### 引数解析とルーティング

```bash
# Parse subcommand and options using parse_subcommand_and_options()
# Function is defined in script library section below
# SUBCOMMAND and BRANCH_OPTIONS are set as global variables
parse_subcommand_and_options "$@" || exit 1

# Route to subcommand handler with parsed options
case "$SUBCOMMAND" in
  new)
    # Delegate to new subcommand implementation
    # Options are already parsed in BRANCH_OPTIONS associative array
    subcommand_new
    ;;
  commit)
    # Delegate to commit subcommand implementation
    # Options are already parsed in BRANCH_OPTIONS associative array
    subcommand_commit
    ;;
  help)
    # Show help message
    subcommand_help
    ;;
  *)
    echo "❌ Error: Unknown subcommand '$SUBCOMMAND'"
    echo ""
    echo "Available subcommands:"
    echo "  new      - Create branch proposal session (default)"
    echo "  commit   - Create branch and integrate commit"
    echo "  help     - Show help message"
    echo ""
    echo "Usage: /idd:issue:branch [new|commit|help] [options]"
    exit 1
    ;;
esac
```

このルーティングロジックにより:

- 引数なしの場合、デフォルトで `new` サブコマンドを実行
- `new` または `commit` を認識し、対応する関数に処理を委譲
- 不明なサブコマンドの場合、エラーメッセージと使用法を表示

## サブコマンド

### new - ブランチ提案セッション作成

`subcommand_new()` 関数が実装します。詳細は「## スクリプトライブラリ」セクションを参照してください。

(T3以降で実装)

### commit - ブランチ作成とコミット統合

`subcommand_commit()` 関数が実装します。詳細は「## スクリプトライブラリ」セクションを参照してください。

(T14以降で実装)

## 使用例

(このセクションは今後のタスクで実装されます)

## スクリプトライブラリ

サブコマンド:

```bash
##
# @brief Create branch proposal session
# @description Handles the 'new' subcommand to create a branch proposal
# @param $@ Command-line arguments (--base, --domain, etc.)
# @return 0 on success, 1 on failure
##
subcommand_new() {
  # Read options from associative array
  local domain_override="${BRANCH_OPTIONS["domain"]:-}"
  local base_override="${BRANCH_OPTIONS["base"]:-}"

  # 1. Get current branch
  local current_branch
  current_branch=$(git branch --show-current)

  # 2. Detect domain (uses TITLE, ISSUE_TYPE from session)
  local domain
  if [ -n "$domain_override" ]; then
    export DOMAIN="$domain_override"  # For detect_domain to prioritize
  fi
  domain=$(detect_domain "$TITLE" "${ISSUE_TYPE:-feature}")

  # 3. Determine base branch
  local base_branch
  base_branch=$(determine_base_branch "$current_branch" "$base_override")

  # 4. Generate branch name
  local suggested_branch
  suggested_branch=$(generate_branch_name "${BRANCH_TYPE:-feat}" "${issue_number:-new}" "$domain" "$TITLE")

  # 5. Save branch session
  save_branch_session "$ISSUES_DIR" "$suggested_branch" "$domain" "$base_branch" "${issue_number:-new}"

  # 6. Display proposal
  echo ""
  echo "📋 Branch Proposal"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Issue: ${TITLE}"
  echo "  Current branch: ${current_branch}"
  echo "  Suggested branch: ${suggested_branch}"
  if [ -n "$domain_override" ]; then
    echo "  Domain: ${domain} (overridden)"
  else
    echo "  Domain: ${domain}"
  fi
  if [ "$base_branch" != "$current_branch" ]; then
    echo "  Base branch: ${base_branch} (will switch before creating)"
  else
    echo "  Base branch: ${base_branch}"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "💡 Next steps:"
  echo "  - /idd:issue:branch commit  : Create the branch and switch to it"
  echo "  - /idd:issue:branch --domain <name>  : Override domain detection"
  echo "  - /idd:issue:branch --base <branch>  : Specify different base branch"
  echo ""

  return 0
}

##
# @brief Create branch and integrate commit
# @description Handles the 'commit' subcommand to create branch and commit
# @param $@ Command-line arguments
# @return 0 on success, 1 on failure
##
subcommand_commit() {
  # Implementation in T14
  echo "Not implemented yet. Run /sdd coding t14 to continue."
  exit 1
}

##
# @brief Show help message for branch command
# @description Displays usage information and available subcommands using heredoc
# @return 0 on success
##
subcommand_help() {
  cat <<'EOF'

Usage: /idd:issue:branch [SUBCOMMAND] [OPTIONS]

Create and manage Git branches from issue sessions.

Subcommands:
  new      Create branch proposal from issue (default)
  commit   Create branch and switch to it
  help     Show this help message

Options (for 'new' and 'commit'):
  --domain <name>   Override automatic domain detection
                    (hyphens converted to underscores)
  --base <branch>   Specify base branch (default: current or main)

Examples:
  /idd:issue:branch              # Create branch proposal (default 'new')
  /idd:issue:branch new          # Same as above
  /idd:issue:branch new --domain claude_command
  /idd:issue:branch new --base develop
  /idd:issue:branch commit       # Create and switch to branch
  /idd:issue:branch help         # Show this help

EOF
  return 0
}
```

```bash
#!/bin/bash

##
# @brief Get domain from title and issue type using Codex-MCP
# @description Uses AI semantic inference to determine the appropriate domain
# @param $1 Title string (may contain [type] prefix for context)
# @param $2 Issue type (feature, bug, enhancement, task)
# @return 0 on success with output, 1 on failure (no output)
# @stdout Inferred domain string (empty if inference fails)
##
_get_domain_use_codex() {
  local title="$1"
  local issue_type="$2"

  local codex_prompt="Based on the issue title \"$title\" and issue type \"$issue_type\", infer the most appropriate domain name for a Git branch in ONE WORD.

Examples:
- Title: \"Add /idd-issue command\", Type: feature → claude-commands
- Title: \"[claude-commands] Add feature\", Type: feature → claude-commands
- Title: \"Fix xcp.sh bug\", Type: bug → scripts
- Title: \"[scripts] Add utility\", Type: feature → scripts
- Title: \"Update README\", Type: enhancement → docs
- Title: \"Implement feature\", Type: feature → feature
- Title: \"Fix validation error\", Type: bug → bugfix

Note: If title contains [type] prefix, treat it as the issue type/category, not domain.
Return ONLY the domain name, no explanation."

  # Call Codex-MCP for inference (early return on failure)
  local codex_result
  if ! codex_result=$(claude mcp__codex-mcp__codex --prompt "$codex_prompt" 2>/dev/null | tail -n 1 | tr -d '[:space:]'); then
    return 1
  fi

  # Early return if result is empty
  if [ -z "$codex_result" ]; then
    return 1
  fi

  # Success path
  echo "$codex_result"
  return 0
}

##
# @brief Get domain from issue type (fallback mapping)
# @description Provides default domain mapping when Codex is unavailable
# @param $1 Issue type (feature, bug, enhancement, task)
# @return 0 on success
# @stdout Mapped domain string
##
_get_domain_from_issue_type() {
  local issue_type="$1"

  case "$issue_type" in
    bug)
      echo "bugfix"
      ;;
    feature)
      echo "feature"
      ;;
    enhancement)
      echo "enhancement"
      ;;
    task)
      echo "task"
      ;;
    *)
      # Fallback to issue_type as-is
      echo "$issue_type"
      ;;
  esac

  return 0
}

##
# @brief Detect domain from issue title (coordinator function)
# @description Determines domain using priority-based strategy:
#   1. DOMAIN variable (--domain option, highest priority)
#   2. Codex-MCP inference (unless no_codex="no_codex")
#   3. Issue type mapping (fallback)
# @param $1 Title string
# @param $2 Issue type (default: "feature")
# @param $3 no_codex flag ("no_codex" to disable Codex, empty to enable)
# @return 0 on success
# @stdout Domain string
# @example
#   domain=$(detect_domain "Add /idd-issue command" "feature")
#   domain=$(detect_domain "Fix bug" "bug" "no_codex")
##
detect_domain() {
  local title="$1"
  local issue_type="${2:-feature}"
  local no_codex="${3:-}"

  # Priority 1: --domain option override
  if [ -n "${DOMAIN:-}" ]; then
    echo "$DOMAIN"
    return 0
  fi

  # Priority 2: Codex-MCP inference
  if [ "$no_codex" != "no_codex" ]; then
    local domain
    if domain=$(_get_domain_use_codex "$title" "$issue_type"); then
      echo "$domain"
      return 0
    fi
  fi

  # Priority 3: Fallback mapping
  _get_domain_from_issue_type "$issue_type"
  return 0
}
```

```bash
##
# @brief Parse subcommand and options from command-line arguments
# @description Analyzes arguments to determine subcommand and options.
#   If first argument starts with '--', treats it as option with default 'new' subcommand.
#   Otherwise, treats first argument as subcommand (default: 'new').
#   Options are parsed into associative array with keys: domain, base.
# @param $@ All command-line arguments
# @return 0 on success
# @stdout Subcommand name (new, commit, help)
# @global BRANCH_OPTIONS Associative array of parsed options (keys: domain, base)
# @example
#   declare -A BRANCH_OPTIONS=()
#   subcommand=$(parse_subcommand_and_options "$@")
#   # Input: "new --domain claude-command --base develop"
#   # Output: "new", BRANCH_OPTIONS["domain"]="claude_command", BRANCH_OPTIONS["base"]="develop"
#   # Input: "help"
#   # Output: "help", BRANCH_OPTIONS=()
#   # Input: "--domain scripts"
#   # Output: "new", BRANCH_OPTIONS["domain"]="scripts"
##
parse_subcommand_and_options() {
  ##
  # @brief Parse options into associative array
  # @description Helper function to parse --key value pairs into BRANCH_OPTIONS
  # @param $@ Array of command-line arguments
  # @global BRANCH_OPTIONS Associative array to store parsed options
  parse_options() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --domain)
          # Convert hyphens to underscores (e.g., "claude-command" → "claude_command")
          BRANCH_OPTIONS["domain"]="${2//-/_}"
          shift 2
          ;;
        --base)
          BRANCH_OPTIONS["base"]="$2"
          shift 2
          ;;
        *)
          # Skip unknown options
          shift
          ;;
      esac
    done
  }

  declare -g SUBCOMMAND="new"  # Initialize global subcommand variable
  declare -g -A BRANCH_OPTIONS=()  # Initialize global options array

  # Case 1: No arguments → default 'new' with no options
  if [ $# -eq 0 ]; then
    return 0
  fi

  # Case 2: First argument starts with '--' → option-only, use default 'new'
  if [[ "$1" == --* ]]; then
    parse_options "$@"
    return 0
  fi

  # Case 3: First argument is subcommand - validate it
  local subcmd="$1"
  case "$subcmd" in
    new|commit|help)
      SUBCOMMAND="$subcmd"
      ;;
    *)
      echo "Error: Invalid subcommand '$subcmd'. Valid subcommands: new, commit, help" >&2
      return 1
      ;;
  esac

  shift
  parse_options "$@"
  return 0
}

##
# @brief Validate Git working directory state
# @description Checks for uncommitted changes before branch creation
# @return 0 if clean or only untracked files, 1 if uncommitted changes exist
# @example
#   if validate_git_state; then
#     echo "Working directory is clean"
#   else
#     echo "Uncommitted changes detected"
#   fi
##
validate_git_state() {
  # Get git status in porcelain format
  local status_output
  status_output=$(git status --porcelain 2>/dev/null)

  # Early return: clean working tree
  if [ -z "$status_output" ]; then
    return 0
  fi

  # Filter out untracked files (lines starting with ??)
  # Only check for uncommitted changes (M, A, D, R, C, etc.)
  local uncommitted_changes
  uncommitted_changes=$(echo "$status_output" | grep -v '^??')

  # Early return: uncommitted changes detected (error case)
  if [ -n "$uncommitted_changes" ]; then
    echo "❌ Uncommitted changes detected"
    echo "💡 Please commit or stash your changes before creating a new branch:"
    echo "   - git status              # View changes"
    echo "   - git commit -am \"msg\"    # Commit changes"
    echo "   - git stash               # Stash changes temporarily"
    return 1
  fi

  # Normal termination: only untracked files exist
  return 0
}

##
# @brief Generate Git branch name from issue information
# @description Constructs branch name in format: {type}-{number}/{domain}/{slug}
# @param $1 Branch type (e.g., "feat", "fix", "docs")
# @param $2 Issue number (e.g., "27" or "new")
# @param $3 Domain (e.g., "claude-commands", "scripts")
# @param $4 Issue title (will be converted to slug)
# @return 0 on success
# @stdout Branch name (e.g., "feat-27/claude-commands/add-branch-command")
# @example
#   branch=$(generate_branch_name "feat" "27" "claude-commands" "Add branch command")
#   echo "$branch"  # "feat-27/claude-commands/add-branch-command"
##
generate_branch_name() {
  local branch_type="$1"
  local issue_number="$2"
  local domain="$3"
  local title="$4"

  # Generate slug from title using filename-utils.lib.sh
  local slug
  slug=$(generate_slug "$title")

  # Construct branch name: {type}-{number}/{domain}/{slug}
  echo "${branch_type}-${issue_number}/${domain}/${slug}"
}

##
# @brief Determine base branch for new branch creation
# @description Returns --base option if specified, otherwise current branch
# @param $1 Current branch name
# @param $2 BASE_BRANCH override (optional, from --base option)
# @return 0 on success
# @stdout Base branch name
# @example
#   base=$(determine_base_branch "main" "")
#   # Returns: "main"
#   base=$(determine_base_branch "main" "develop")
#   # Returns: "develop"
##
determine_base_branch() {
  local current_branch="$1"
  local base_override="${2:-}"

  if [ -n "$base_override" ]; then
    echo "$base_override"
  else
    echo "$current_branch"
  fi

  return 0
}

##
# @brief Save branch session to .branch.session file
# @description Saves branch proposal information including suggested branch name,
#   domain, base branch, issue number, and timestamp
# @param $1 Issues directory path
# @param $2 Suggested branch name (e.g., "feat-27/claude-commands/add-branch-command")
# @param $3 Domain (e.g., "claude-commands")
# @param $4 Base branch (e.g., "main")
# @param $5 Issue number (e.g., "27" or "new")
# @return 0 on success
# @example
#   save_branch_session "$ISSUES_DIR" \
#     "feat-27/claude-commands/add-branch-command" \
#     "claude-commands" \
#     "main" \
#     "27"
##
save_branch_session() {
  local issues_dir="$1"
  local suggested_branch="$2"
  local domain="$3"
  local base_branch="$4"
  local issue_number="$5"

  local session_file="$issues_dir/.branch.session"

  # Prepare session data as associative array
  local -A session_data=(
    ["suggested_branch"]="$suggested_branch"
    ["domain"]="$domain"
    ["base_branch"]="$base_branch"
    ["issue_number"]="$issue_number"
  )

  # Save session using shared function
  _save_session "$session_file" session_data
}

##
# @brief Load branch session from .branch.session file
# @description
#   Loads previously saved branch session data and exports as environment variables.
#   Uses _load_session() from idd-session.lib.sh for consistent session management.
#
# @param $1 issues_dir - Directory containing .branch.session file
#
# @return 0 on success
# @return 1 on error (file not found, invalid format, missing parameter)
#
# @env SUGGESTED_BRANCH - Loaded suggested branch name
# @env DOMAIN - Loaded domain value
# @env BASE_BRANCH - Loaded base branch name
# @env ISSUE_NUMBER - Loaded issue number
# @env LAST_MODIFIED - Loaded timestamp
#
# @example
#   load_branch_session "$ISSUES_DIR"
#   echo "Last branch: $SUGGESTED_BRANCH"
##
load_branch_session() {
  local issues_dir="$1"

  if [ -z "$issues_dir" ]; then
    error_print "❌ Error: issues_dir required"
    return 1
  fi

  local session_file="$issues_dir/.branch.session"

  if [ ! -f "$session_file" ]; then
    error_print "❌ Error: Session file not found: $session_file"
    return 1
  fi

  # Load session using shared function
  # shellcheck disable=SC1090
  if ! source "$session_file"; then
    error_print "❌ Error: Failed to load session file"
    return 1
  fi

  # Export loaded variables
  export SUGGESTED_BRANCH="${suggested_branch:-}"
  export DOMAIN="${domain:-}"
  export BASE_BRANCH="${base_branch:-}"
  export ISSUE_NUMBER="${issue_number:-}"
  export LAST_MODIFIED="${LAST_MODIFIED:-}"

  return 0
}
```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
