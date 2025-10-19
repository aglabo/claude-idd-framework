---
# Claude Code 必須要素
allowed-tools:
  Bash(
    git:*, gh:*, gh issue:*,
    mkdir:*, date:*, cat:*, ls:*, head:*, tail:*, basename:*, wc:*, stat:*,
    sed:*, tr:*, cut:*, mktemp:*, rm:*, mv:*, source:*, echo:*, export:*,
    test:*, command:*, jq:*, code:*
  ),
  Read(*), Write(*), Task(*), TodoWrite(*),
  mcp__codex-mcp__codex(*),
  mcp__serena-mcp__*,
  mcp__lsmcp__*
argument-hint: [subcommand (new|list|view|edit|load|push|branch)] [options(issue_no)]
description: GitHub Issue 作成・管理システム - issue-generatorエージェントによる構造化Issue作成

# 設定変数
config:
  temp_dir: temp/idd/issues
  issue_types:
    - feature
    - bug
    - enhancement
    - task
  default_editor: ${EDITOR:-code}
  default_pager: ${PAGER:-less}

# サブコマンド定義
subcommands:
  new: "issue-generatorエージェントで新規Issue作成 (デフォルト)"
  list: "保存済みIssueドラフト一覧表示 → セッション準備 → /select-from-list で選択"
  view: "特定のIssueドラフト表示"
  edit: "Issueドラフト編集"
  load: "GitHub IssueをローカルにImport"
  push: "ドラフトをGitHubにPush (新規作成または更新)"
  branch: "Issueからブランチ名を提案・作成 (デフォルト: 提案のみ, -c: 作成)"

# ag-logger プロジェクト要素
title: idd-issue
version: 1.2.0
created: 2025-09-30
authors:
  - atsushifx
changes:
  - 2025-10-15: Type自動判定機能追加 - Codexがcommitlint.config.jsとIssue Templatesから最適なtypeを判定
  - 2025-10-13: issue-generatorエージェントの Claude/Codex 両モードサポートに対応
  - 2025-10-03:
      allowed-toolsに各種コマンドを追加、見やすいように成形
      ブランチ自動作成機能追加 - codex-mcpによるcommitlint準拠のブランチ名生成
      セッション管理機能追加 - .last-sessionでコマンド間でIssue状態を保持
  - 2025-10-02: フロントマターベース構造に再構築、/idd-issue に名称変更
  - 2025-09-30: 初版作成 - 6サブコマンド体系でIssue管理機能を実装
---

## /idd-issue

issue-generator エージェントを使用して、GitHub Issue を作成・管理するコマンド。

## Bash 初期設定

各サブコマンドは `.claude/commands/_libs/` のヘルパー関数を使用します。
詳細は `.claude/commands/_helpers/README.md` を参照。

```bash
#!/bin/bash
# Load helper libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBS_DIR="$SCRIPT_DIR/_libs"

. "$LIBS_DIR/io-utils.lib.sh"
. "$LIBS_DIR/idd-env.lib.sh"
. "$LIBS_DIR/idd-file-ops.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"
. "$LIBS_DIR/idd-git-ops.lib.sh"

# Issue-specific environment setup
setup_issue_env() {
  _setup_repo_env
  export ISSUES_DIR=$(_get_temp_dir "idd/issues")
  export SESSION_FILE="$ISSUES_DIR/.last.session"
  export PAGER="${PAGER:-less}"
  export EDITOR="${EDITOR:-code}"
}
```

## アーキテクチャの特徴

- エージェント連携: Issue 生成の複雑なロジックを issue-generator エージェントに委譲
- 関数化設計: 共通ロジックをヘルパー関数に集約し、各サブコマンドは 5-15行程度に簡素化
- 明確な責務分離: 生成 (agent) とユーティリティ (local scripts) を分離
- 設定の一元管理: フロントマターで設定・サブコマンド定義を集約
- 保守しやすい設計: 共通ロジックの修正はヘルパー関数のみで完結
- 拡張しやすい設計: 新サブコマンドはヘルパー関数を組み合わせるだけで実現可能

## issue-generatorエージェントとの連携

`/idd-issue new` コマンドは以下の流れで動作:

1. **コマンド実行**: ユーザーが `/idd-issue new` を実行
2. **Issue種別選択**: 利用可能な Issue 種別を表示
3. **エージェント起動**: Claude が Task tool で issue-generator エージェントを起動
   - デフォルト: Codex モード (Codex MCP に委譲)
   - `--use-claude` 指定時: Claude モード (Claude が直接処理)
4. **エージェント処理**:
   - Issue 種別とタイトル取得
   - `.github/ISSUE_TEMPLATE/{種別}.yml` 読み込み
   - YML 構造解析
   - 対話的な情報収集
   - Issue ドラフト生成
   - `temp/idd/issues/new-{timestamp}-{type}-{slug}.md` に保存
   - セッション保存: `save_issue_session()` でセッション情報を保存
5. **完了報告**: エージェントが生成結果を報告

### 生成モードの選択

- **Codex モード** (デフォルト): Codex の強力な推論能力により、プロジェクトの文脈を深く理解した具体的な Issue を生成
- **Claude モード** (`--use-claude`): Claude が直接処理し、ユーザーとの対話が同一セッション内で完結、処理過程が可視化される

### セッション管理

各サブコマンド実行後、`temp/idd/issues/.last-session` にセッション情報を保存:

- 引数なしでコマンド実行時、セッションファイル優先で Issue を選択
- 後方互換性: セッションがない場合は最新ファイルを使用

## ファイル命名規則

Issue ドラフトファイルは決定的な命名規則を使用:

- 新規 Issue: `new-{yymmdd-HHMMSS}-{type}-{slug}.md`
  - 例: `new-251002-143022-feature-user-authentication.md`
- Import 済み Issue: `{issue-num}-{yymmdd-HHMMSS}-{type}-{slug}.md`
  - 例: `123-251002-143500-bug-form-validation.md`

## 実行フロー

1. **設定読み込み**: メタデータの `config` セクションから設定を取得
2. **パス構築**: `{git_root}/{temp_dir}` で Issue ドラフトディレクトリパスを構築
3. **サブコマンド実行**: 以下のいずれかを実行

### Subcommand: new (デフォルト)

```bash
#!/bin/bash
setup_issue_env
ensure_issues_dir

# Claude will use Task tool to launch issue-generator agent
# Agent creates issue draft with user input (title + body)
# After completion, determine_issue_type() analyzes the draft via Codex
# Codex reviews: configs/commitlint.config.js types + .github/ISSUE_TEMPLATE/*.yml
# Returns optimal type (e.g., chore, feat, task, etc.)
# Renames file with determined type: new-{timestamp}-{type}-{slug}.md
# Calls save_issue_session() with final type
```

### Subcommand: list

```bash
#!/bin/bash
setup_issue_env

# Load subcommand session library
. "$LIBS_DIR/idd-subcommand-session.lib.sh"

# Check if issues exist
if [ ! -d "$ISSUES_DIR" ] || [ -z "$(ls -A "$ISSUES_DIR"/*.md 2>/dev/null)" ]; then
  echo "No issues found. Run: /idd-issue new"
  exit 0
fi

# Display issue list with details
echo "Issues:"
for file in "$ISSUES_DIR"/*.md; do
  [ -f "$file" ] || continue
  local filename=$(basename "$file" .md)
  local title=$(_extract_title "$file")
  local modified=$(_get_file_timestamp "$file")
  echo "$filename"
  echo "  $title ($modified)"
done
echo ""

# Get issue file list (newest first)
mapfile -t files < <(ls -t "$ISSUES_DIR"/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//')

# Get current selection from .last.session
current_issue=""
if _load_session && [ -n "$LAST_ISSUE_FILE" ]; then
  current_issue="$LAST_ISSUE_FILE"
fi

# Prepare INPUT JSON for /select-from-list
list_json=$(printf '%s\n' "${files[@]}" | jq -R . | jq -s .)

if [ -n "$current_issue" ]; then
  input_json=$(jq -n \
    --arg prompt "Select issue" \
    --argjson list "$list_json" \
    --arg current "$current_issue" \
    '{prompt: $prompt, list: $list, current: $current}')
else
  input_json=$(jq -n \
    --arg prompt "Select issue" \
    --argjson list "$list_json" \
    '{prompt: $prompt, list: $list}')
fi

# Write to subcommand session
_write_subcommand_input "select-from-list" "$input_json"

echo "📋 Session prepared."
echo ""
echo "To select: /select-from-list"
echo "Then: /idd-issue view (or edit/push/branch)"
```

### Subcommand: view

```bash
#!/bin/bash
setup_issue_env

# Check for selection from /select-from-list subcommand (priority 1)
if [ -z "$1" ]; then
  . "$LIBS_DIR/idd-subcommand-session.lib.sh"

  if _has_subcommand_session; then
    output=$(_read_subcommand_output)

    if [ "$output" != "null" ]; then
      cancelled=$(echo "$output" | jq -r '.cancelled // false')

      if [ "$cancelled" = "false" ]; then
        selected=$(echo "$output" | jq -r '.selected_item')
        echo "Using selection: $selected"

        # Set argument for find_issue_file
        set -- "$selected"

        # Clear subcommand session after use
        _clear_subcommand_session
      fi
    fi
  fi
fi

# Find issue file (priority 2: .last.session, priority 3: interactive selection)
find_issue_file "$1" || exit 1

# Claude will use Read tool to display $ISSUE_FILE
# Show stats via Bash(wc), update session, suggest next commands
update_issue_session "view"
```

### Subcommand: edit

```bash
#!/bin/bash
setup_issue_env

# Check for selection from /select-from-list subcommand (priority 1)
if [ -z "$1" ]; then
  . "$LIBS_DIR/idd-subcommand-session.lib.sh"

  if _has_subcommand_session; then
    output=$(_read_subcommand_output)

    if [ "$output" != "null" ]; then
      cancelled=$(echo "$output" | jq -r '.cancelled // false')

      if [ "$cancelled" = "false" ]; then
        selected=$(echo "$output" | jq -r '.selected_item')
        set -- "$selected"
        _clear_subcommand_session
      fi
    fi
  fi
fi

# Find issue file (priority 2: .last.session, priority 3: interactive selection)
find_issue_file "$1" || exit 1

# Open $ISSUE_FILE in $EDITOR, update session after edit
$EDITOR "$ISSUE_FILE"
update_issue_session "edit"
```

### Subcommand: load

```bash
#!/bin/bash
setup_issue_env
ensure_issues_dir
validate_issue_number "$1" || exit 1

# Claude will use Bash(gh issue view) to fetch issue
# Save via Write tool, call save_issue_session()
import_github_issue "$1"
```

### Subcommand: push

```bash
#!/bin/bash
setup_issue_env
find_issue_file "$1" || exit 1

# Claude will use Read to extract title/body
# Use Bash(gh issue create/edit) to push
# Call update_issue_session("push"), rename file if new issue
push_issue_to_github "$ISSUE_FILE" "$(prepare_issue_body "$ISSUE_FILE")"
```

### Subcommand: branch

```bash
#!/bin/bash
setup_issue_env
parse_branch_options "$@" || exit 1
shift $((OPTIND-1))
find_issue_file "$1" || exit 1

# Claude will use Read to get issue content
# Use mcp__codex-mcp__codex with analyze_issue_for_branch() prompt
# Generate commitlint-compliant branch name, save to session
# If -c flag: use Bash(git switch -c) to create branch
get_or_generate_branch_name "$ISSUE_FILE"
[ "$CREATE_BRANCH" = true ] && create_branch_from_suggestion "$SUGGESTED_BRANCH"
```

## Bashヘルパーライブラリ

```bash
# ============================================================
# 1. 環境設定・初期化関数
# ============================================================

# Issue ディレクトリ作成
ensure_issues_dir() {
  _ensure_dir "$ISSUES_DIR"
}

# Commitlint types 読み込み (type: description のペア)
# 戻り値: 標準出力に type リスト (改行区切り、各行: "type: description")
load_commitlint_types() {
  local config_file="$REPO_ROOT/configs/commitlint.config.js"

  if [ ! -f "$config_file" ]; then
    cat << 'EOF'
feat: New feature
fix: Bug fix
chore: Routine task, maintenance
docs: Documentation only
test: Adding or updating tests
refactor: Code change without fixing a bug or adding a feature
perf: Performance improvement
ci: CI/CD related change
EOF
    return 0
  fi

  # Extract type-enum section with comments
  # Format: 'type', // Description
  grep -A 30 "'type-enum'" "$config_file" | \
    grep -E "^\s*'[a-z]+'" | \
    sed -E "s/^\s*'([a-z]+)',\s*\/\/\s*(.*)$/\1: \2/" | \
    sed 's/\s*$//'
}

# GitHub Issue Templates 一覧取得
# 戻り値: 標準出力に template リスト (カンマ区切り)
list_issue_templates() {
  local templates_dir="$REPO_ROOT/.github/ISSUE_TEMPLATE"

  if [ ! -d "$templates_dir" ]; then
    echo "feature_request,bug_report,enhancement,task"
    return 0
  fi

  # List all .yml files without extension
  ls "$templates_dir"/*.yml 2>/dev/null | \
    xargs -n1 basename | \
    sed 's/\.yml$//' | \
    grep -v "^config$" | \
    tr '\n' ',' | \
    sed 's/,$//'
}

# Codex で Issue type 自動判定
# 引数: $1 - Issue タイトル, $2 - Issue 本文
# 戻り値: 標準出力に判定された type
determine_issue_type() {
  local title="$1"
  local body="$2"

  # Get available types with descriptions
  local commitlint_types=$(load_commitlint_types)
  local issue_templates=$(list_issue_templates)

  # Claude will use mcp__codex-mcp__codex with the following prompt:
  local TYPE_PROMPT="Analyze this GitHub Issue and determine the most appropriate type.

Issue Title: $title

Issue Body:
$body

Available Types (prioritized):

1. GitHub Issue Templates:
   $issue_templates

2. Commitlint Types with Descriptions:
$commitlint_types

Priority Rules:
- If the issue is about adding a NEW feature → prefer 'feature_request' (template) or 'feat' (commitlint)
- If the issue is about fixing a bug → prefer 'bug_report' (template) or 'fix' (commitlint)
- If the issue is about improving EXISTING functionality → prefer 'enhancement' (template)
- If the issue is about development/maintenance tasks → prefer 'task' (template) or 'chore' (commitlint)
- If the issue is about release management → use 'release' (template)
- If the issue is about documentation only → use 'docs' (commitlint)
- For other cases, use appropriate commitlint type based on descriptions

Output ONLY the type name, nothing else (e.g., 'chore' or 'task' or 'docs')."

  # Note: Claude will invoke mcp__codex-mcp__codex and return the type
  # For now, return a placeholder
  echo "task"
}

# ============================================================
# 2. Issue検索・一覧表示関数
# ============================================================

# Issue ファイル検索
# 引数: $1 - Issue番号またはファイル名 (省略時は対話的選択、セッション優先)
# 戻り値: グローバル変数 ISSUE_FILE に見つかったファイルパスを設定
find_issue_file() {
  local ISSUE_INPUT="$1"
  ISSUE_FILE=""

  if [ -z "$ISSUE_INPUT" ]; then
    # 引数なし: セッションファイル優先
    if _load_session && [ -f "$ISSUES_DIR/$LAST_ISSUE_FILE.md" ]; then
      ISSUE_FILE="$ISSUES_DIR/$LAST_ISSUE_FILE.md"
      echo "Using session: $(basename "$ISSUE_FILE" .md)"
      return 0
    fi

    # セッションがない場合: 対話的選択
    local selected
    if selected=$(select_issue_file "$ISSUES_DIR" "Select issue"); then
      ISSUE_FILE="$ISSUES_DIR/${selected}.md"
      echo "Selected: $selected"
      return 0
    else
      return 1
    fi

  elif [[ "$ISSUE_INPUT" =~ ^[0-9]+$ ]]; then
    # Issue番号: マッチするファイルを検索
    ISSUE_FILE=$(ls "$ISSUES_DIR"/${ISSUE_INPUT}-*.md 2>/dev/null | head -1)
    if [ -z "$ISSUE_FILE" ]; then
      error_print "No draft for issue #$ISSUE_INPUT"
      return 1
    fi
    echo "Found: $(basename "$ISSUE_FILE" .md)"
    return 0

  else
    # ファイル名直接指定
    ISSUE_FILE="$ISSUES_DIR/$ISSUE_INPUT.md"
    if [ ! -f "$ISSUE_FILE" ]; then
      error_print "Issue not found: $ISSUE_INPUT"
      return 1
    fi
  fi
  return 0
}

# Issue ファイル一覧表示
list_issue_files() {
  if [ ! -d "$ISSUES_DIR" ] || [ -z "$(ls -A "$ISSUES_DIR"/*.md 2>/dev/null)" ]; then
    echo "No issues found. Run: /idd-issue new"
    return 0
  fi

  echo "Issues:"
  for file in "$ISSUES_DIR"/*.md; do
    [ -f "$file" ] || continue
    local filename=$(basename "$file" .md)
    local title=$(_extract_title "$file")
    local modified=$(_get_file_timestamp "$file")
    echo "$filename"
    echo "  $title ($modified)"
  done

  echo ""
  echo "view/edit/push <name>"
}

# ============================================================
# 3. Issue解析・変換関数
# ============================================================

# Issue種別検出
# 引数: $1 - タイトル文字列
detect_issue_type() {
  local title="$1"

  if [[ "$title" =~ ^\[Feature\] ]]; then
    echo "feature"
  elif [[ "$title" =~ ^\[Bug\] ]]; then
    echo "bug"
  elif [[ "$title" =~ ^\[Enhancement\] ]]; then
    echo "enhancement"
  elif [[ "$title" =~ ^\[Task\] ]]; then
    echo "task"
  else
    echo "issue"
  fi
}

# タイトルからスラッグ生成
# 引数: $1 - タイトル文字列
generate_slug() {
  local title="$1"

  echo "$title" | \
    sed 's/\[.*\][[:space:]]*//' | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9[:space:]-]//g' | \
    tr -s '[:space:]' '-' | \
    sed 's/^-\+//; s/-\+$//' | \
    cut -c1-50
}

# Issue番号抽出
# 引数: $1 - ファイル名
extract_issue_number() {
  local filename="$1"
  echo "$filename" | sed 's/-.*//'
}

# Issue情報からファイル名生成
# 引数: $1 - Issue番号 (新規の場合は "new"), $2 - タイトル
# 戻り値: 標準出力にファイル名 (拡張子なし)
generate_issue_filename() {
  local issue_num="$1"
  local title="$2"

  local issue_type=$(detect_issue_type "$title")
  local slug=$(generate_slug "$title")
  local timestamp=$(date '+%y%m%d-%H%M%S')

  echo "${issue_num}-${timestamp}-${issue_type}-${slug}"
}

# Issueメタデータ一括抽出
# 引数: なし (グローバル変数 $ISSUE_FILE を使用)
# 戻り値: グローバル変数 ISSUE_FILENAME, ISSUE_TITLE, ISSUE_TYPE, ISSUE_NUM を設定
extract_issue_metadata() {
  ISSUE_FILENAME=$(basename "$ISSUE_FILE" .md)
  ISSUE_TITLE=$(_extract_title "$ISSUE_FILE")
  ISSUE_TYPE=$(detect_issue_type "$ISSUE_TITLE")
  ISSUE_NUM=$(extract_issue_number "$ISSUE_FILENAME")
}

# ============================================================
# 4. GitHub連携関数
# ============================================================

# Issue番号検証
# 引数: $1 - Issue番号
validate_issue_number() {
  local ISSUE_NUM="$1"

  if [ -z "$ISSUE_NUM" ]; then
    error_print <<EOF
Issue number required.
Usage: /idd-issue load <issue-number>
EOF
    return 1
  fi

  if ! [[ "$ISSUE_NUM" =~ ^[0-9]+$ ]]; then
    error_print "Invalid issue number."
    return 1
  fi

  return 0
}

# GitHub Issue取得
# 引数: $1 - Issue番号
# 戻り値: グローバル変数 ISSUE_TITLE, ISSUE_BODY に取得内容を設定
fetch_github_issue() {
  local ISSUE_NUM="$1"

  echo "Loading issue #$ISSUE_NUM..."

  # Fetch issue using gh CLI
  if ! ISSUE_JSON=$(gh issue view "$ISSUE_NUM" --json 'title,body' 2>/dev/null); then
    error_print <<EOF
GitHub CLI error. Install/authenticate gh.
Run: gh auth login
EOF
    return 1
  fi

  # Extract title and body
  if command -v jq >/dev/null 2>&1; then
    ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title // "Untitled"')
    ISSUE_BODY=$(echo "$ISSUE_JSON" | jq -r '.body // ""')
  else
    ISSUE_TITLE=$(echo "$ISSUE_JSON" | grep '"title"' | cut -d'"' -f4)
    ISSUE_BODY=$(echo "$ISSUE_JSON" | grep '"body"' | cut -d'"' -f4)
  fi

  return 0
}

# GitHub IssueをImportしてファイル保存
# 引数: $1 - Issue番号
# 処理: GitHub取得 → ファイル名生成 → 保存 → セッション保存 → 完了メッセージ
import_github_issue() {
  local issue_num="$1"

  # GitHubからIssue取得
  if ! fetch_github_issue "$issue_num"; then
    return 1
  fi

  # ファイル名生成
  local filename=$(generate_issue_filename "$issue_num" "$ISSUE_TITLE")
  local issue_file="$ISSUES_DIR/${filename}.md"

  # ファイル保存
  save_issue_file "$issue_file" "$ISSUE_TITLE" "$ISSUE_BODY"

  # セッション保存
  local issue_type=$(detect_issue_type "$ISSUE_TITLE")
  save_issue_session "$filename" "$issue_num" "$ISSUE_TITLE" "$issue_type" "load"

  # 完了メッセージ
  echo "Issue imported: $filename"
  echo ""
  echo "view/edit/push $issue_num"

  return 0
}

# Issueの本文を一時ファイルに準備
# 引数: $1 - Issueファイルパス
# 戻り値: 標準出力に一時ファイルパス、グローバル変数 ISSUE_TITLE にタイトル設定
prepare_issue_body() {
  local issue_file="$1"

  # タイトル抽出
  ISSUE_TITLE=$(_extract_title "$issue_file")
  if [ -z "$ISSUE_TITLE" ]; then
    error_print "Could not extract title"
    return 1
  fi

  echo "Title: $ISSUE_TITLE"

  # H1見出しを除いた本文を一時ファイルに保存
  local temp_body=$(mktemp)
  tail -n +2 "$issue_file" > "$temp_body"

  echo "$temp_body"
  return 0
}

# IssueをGitHubにプッシュ (新規/既存自動判定)
# 引数: $1 - Issueファイルパス, $2 - 本文一時ファイルパス
# 処理: ファイル名判定 → 新規作成 or 既存更新 → セッション保存
push_issue_to_github() {
  local issue_file="$1"
  local temp_body="$2"
  local issue_name=$(basename "$issue_file" .md)

  # 新規Issue作成
  if [[ "$issue_name" =~ ^new- ]]; then
    if ! push_new_issue "$ISSUE_TITLE" "$temp_body" "$issue_name"; then
      return 1
    fi
    # ファイル名が変更されたので再設定
    ISSUE_FILE=$(ls "$ISSUES_DIR"/${ISSUE_NUM}-*.md 2>/dev/null | head -1)

  # 既存Issue更新
  elif [[ "$issue_name" =~ ^[0-9]+ ]]; then
    local issue_num=$(extract_issue_number "$issue_name")
    if ! push_existing_issue "$issue_num" "$ISSUE_TITLE" "$temp_body"; then
      return 1
    fi
    ISSUE_NUM="$issue_num"

  # 無効なファイル名形式
  else
    error_print "Invalid issue name format. Must start with 'new-' or number."
    return 1
  fi

  # セッション更新
  update_issue_session "push"
  return 0
}

# GitHub Issueプッシュ (新規作成)
# 引数: $1 - タイトル, $2 - 本文ファイル, $3 - 元のファイル名
push_new_issue() {
  local title="$1"
  local body_file="$2"
  local old_name="$3"

  # GitHub Issue作成
  if ! NEW_URL=$(_gh_issue_create "$title" "$body_file"); then
    return 1
  fi

  # Issue番号抽出
  ISSUE_NUM=$(_extract_issue_number_from_url "$NEW_URL")
  echo "URL: $NEW_URL"

  # Rename file: new-* → {issue-num}-*
  NEW_FILENAME=$(echo "$old_name" | sed "s/^new-/$ISSUE_NUM-/")
  mv "$ISSUE_FILE" "$ISSUES_DIR/$NEW_FILENAME.md"
  echo "Renamed: $NEW_FILENAME"
}

# GitHub Issueプッシュ (既存更新)
# 引数: $1 - Issue番号, $2 - タイトル, $3 - 本文ファイル
push_existing_issue() {
  _gh_issue_update "$1" "$2" "$3"
}

# ============================================================
# 5. ファイル操作関数
# ============================================================

# Issueファイル保存
# 引数: $1 - ファイルパス, $2 - タイトル, $3 - 本文
save_issue_file() {
  local file="$1"
  local title="$2"
  local body="$3"

  cat > "$file" << EOF
# $title

$body
EOF
}

# 一時ファイルのクリーンアップ
# 引数: $1 - 一時ファイルパス
cleanup_temp_files() {
  local temp_file="$1"
  [ -n "$temp_file" ] && rm -f "$temp_file"
}

# ============================================================
# 6. セッション管理関数
# ============================================================

# セッション情報保存
# 引数: $1 - ファイル名, $2 - Issue番号, $3 - タイトル, $4 - 種別, $5 - コマンド名, $6 - ブランチ名 (オプション)
save_issue_session() {
  local filename="$1"
  local issue_num="$2"
  local title="$3"
  local issue_type="$4"
  local command="$5"
  local branch_name="${6:-}"

  local -a kv_pairs=(
    LAST_ISSUE_FILE "$filename"
    LAST_ISSUE_NUMBER "$issue_num"
    LAST_ISSUE_TITLE "$title"
    LAST_ISSUE_TYPE "$issue_type"
    LAST_COMMAND "$command"
    LAST_BRANCH_NAME "$branch_name"
  )

  _save_session "$SESSION_FILE" "${kv_pairs[@]}"
}

# Issue処理後のセッション更新
# 引数: $1 - コマンド名, $2 - ブランチ名 (オプション)
# 処理: extract_issue_metadata() → save_issue_session() を実行
update_issue_session() {
  local command="$1"
  local branch_name="${2:-}"

  extract_issue_metadata
  save_issue_session "$ISSUE_FILENAME" "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_TYPE" "$command" "$branch_name"
}

# ============================================================
# 7. ブランチ管理関数
# ============================================================

# branchサブコマンドのオプション解析
# 引数: $@ - コマンドライン引数
# 戻り値: グローバル変数 CREATE_BRANCH にフラグ設定、OPTIND に解析位置設定
parse_branch_options() {
  CREATE_BRANCH=false  # Default: suggestion only (-n)

  while getopts "nc" opt; do
    case $opt in
      n) CREATE_BRANCH=false ;;
      c) CREATE_BRANCH=true ;;
      *) echo "Usage: /idd-issue branch [-n|-c] [issue-number]" && return 1 ;;
    esac
  done

  return 0
}

# ブランチ名の取得または生成
# 引数: $1 - Issueファイルパス
# 戻り値: 標準出力にブランチ名、セッション保存
get_or_generate_branch_name() {
  local issue_file="$1"

  # Issueコンテンツとメタデータ読み込み
  local issue_content=$(cat "$issue_file")
  extract_issue_metadata

  echo "Issue #$ISSUE_NUM: $ISSUE_TITLE"
  echo ""

  # セッションから保存済みブランチ名確認
  local suggested_branch=""
  if _load_session && [ -n "$LAST_BRANCH_NAME" ] && [ "$LAST_ISSUE_NUMBER" = "$ISSUE_NUM" ]; then
    echo "Saved: $LAST_BRANCH_NAME"
    echo ""
    read -p "Use saved? (Y/n): " USE_SAVED
    if [[ "$USE_SAVED" =~ ^[Yy]?$ ]]; then
      suggested_branch="$LAST_BRANCH_NAME"
      echo "Using saved branch"
    fi
  fi

  # Codex分析でブランチ名生成 (保存済みがない場合)
  if [ -z "$suggested_branch" ]; then
    analyze_issue_for_branch "$ISSUE_NUM" "$ISSUE_TITLE" "$issue_content"
    # Note: analyze_issue_for_branch() sets SUGGESTED_BRANCH via Claude
    suggested_branch="$SUGGESTED_BRANCH"

    # セッション保存
    save_issue_session "$ISSUE_FILENAME" "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_TYPE" "branch" "$suggested_branch"
  fi

  echo "$suggested_branch"
  return 0
}

# ============================================================
# 8. 出力・UI関数
# ============================================================

# Push完了後の次ステップ表示
show_next_steps_after_push() {
  echo ""
  echo "Push completed!"
  echo ""
  echo "Next: /idd-issue list"
}

# ブランチ名提案を表示 (作成なし)
# 引数: $1 - ブランチ名, $2 - Issue番号
show_branch_suggestion() {
  local branch_name="$1"
  local issue_num="$2"

  echo ""
  echo "Suggested: $branch_name"
  echo ""
  echo "Create: /idd-issue branch -c $issue_num"
}

# codex-mcpでIssue分析→ブランチ名提案
# 引数: $1 - Issue番号, $2 - タイトル, $3 - Issue内容
# 戻り値: グローバル変数 SUGGESTED_BRANCH に提案されたブランチ名を設定
analyze_issue_for_branch() {
  local issue_num="$1"
  local title="$2"
  local issue_content="$3"

  echo "Analyzing with codex-mcp..."
  echo ""

  # Note: Claude will use mcp__codex-mcp__codex tool with the following prompt:
  ANALYSIS_PROMPT="Analyze this GitHub Issue and suggest a branch name following these rules:

Issue #${issue_num}: ${title}

Content:
${issue_content}

Rules:
1. Determine the commitlint type (feat, fix, chore, docs, style, refactor, test, build, ci, perf)
2. Extract a scope (component/module name, e.g., 'claude-commands', 'logger-core', 'error-handling')
3. Create a slug from the title (lowercase, hyphenated, max 50 chars)
4. Format: <type>-${issue_num}/<scope>/<slug>

Examples:
- feat-42/user-auth/login-system
- fix-123/error-handling/null-pointer
- chore-42/claude-commands/idd-issue-branch-auto

Output ONLY the branch name, nothing else."

  # Claude will invoke mcp__codex-mcp__codex and set SUGGESTED_BRANCH
  # SUGGESTED_BRANCH="<result from codex-mcp>"
}

# 既存ブランチへの切り替え確認・実行
# 引数: $1 - ブランチ名
# 戻り値: 0=成功, 1=失敗またはキャンセル
switch_to_existing_branch() {
  local branch_name="$1"

  echo "Branch exists. Switch to it?"
  read -p "Switch? (Y/n): " SWITCH_CONFIRM

  # キャンセル確認 (早期リターン)
  if [[ ! "$SWITCH_CONFIRM" =~ ^[Yy]?$ ]]; then
    error_print "Operation cancelled"
    return 1
  fi

  # ブランチ切り替え失敗時は早期リターン
  if ! git switch "$branch_name"; then
    error_print "Failed to switch"
    return 1
  fi

  # 成功時の処理 (最終行は正常終了)
  echo "Switched to: $branch_name"
  return 0
}

# 新規ブランチ作成・切り替え
# 引数: $1 - ブランチ名
# 戻り値: 0=成功, 1=失敗
create_branch_from_suggestion() {
  local branch_name="$1"

  echo ""
  echo "Suggested: $branch_name"
  echo ""
  echo "Create and switch?"
  read -p "Proceed? (Y/n): " CONFIRM

  # キャンセル確認
  if [[ ! "$CONFIRM" =~ ^[Yy]?$ ]]; then
    error_print "Branch creation cancelled"
    return 1
  fi

  echo ""
  echo "Creating branch..."

  # 既存ブランチ確認
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    switch_to_existing_branch "$branch_name"
    return $?
  fi

  # ブランチ作成・切り替え
  if ! git switch -c "$branch_name"; then
    error_print "Failed to create branch"
    return 1
  fi

  echo "Created: $branch_name"
  echo ""
  echo "Next:"
  echo "  1. Make changes"
  echo "  2. git commit -m '<type>(<scope>): <description>'"
  echo "  3. git push -u origin $branch_name"
}
```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
