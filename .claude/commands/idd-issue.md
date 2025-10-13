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
  list: "保存済みIssueドラフト一覧表示"
  view: "特定のIssueドラフト表示"
  edit: "Issueドラフト編集"
  load: "GitHub IssueをローカルにImport"
  push: "ドラフトをGitHubにPush (新規作成または更新)"
  branch: "Issueからブランチ名を提案・作成 (デフォルト: 提案のみ, -c: 作成)"

# ag-logger プロジェクト要素
title: idd-issue
version: 2.2.1
created: 2025-09-30
authors:
  - atsushifx
changes:
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

## Bashヘルパーライブラリ

以下のヘルパー関数は各サブコマンドが使用:

```bash
#!/bin/bash
# Issue管理コマンド用ヘルパー関数集

# 設定初期化
setup_issue_env() {
  export REPO_ROOT=$(git rev-parse --show-toplevel)
  export ISSUES_DIR="$REPO_ROOT/temp/idd/issues"
  export SESSION_FILE="$ISSUES_DIR/.last-session"
  export PAGER="${PAGER:-less}"
  export EDITOR="${EDITOR:-code}"
}

# Issue ディレクトリ作成
ensure_issues_dir() {
  mkdir -p "$ISSUES_DIR"
}

# Issue ファイル検索
# 引数: $1 - Issue番号またはファイル名 (省略時はセッションファイル優先、次に最新ファイル)
# 戻り値: グローバル変数 ISSUE_FILE に見つかったファイルパスを設定
find_issue_file() {
  local ISSUE_INPUT="$1"
  ISSUE_FILE=""

  if [ -z "$ISSUE_INPUT" ]; then
    # 引数なし: セッションファイル優先、次に最新ファイル
    if load_session && [ -f "$ISSUES_DIR/$LAST_ISSUE_FILE" ]; then
      ISSUE_FILE="$ISSUES_DIR/$LAST_ISSUE_FILE"
      echo "📄 Using session: $(basename "$ISSUE_FILE" .md)"
      return 0
    fi

    # フォールバック: 最新ファイルを使用
    ISSUE_FILE=$(ls -t "$ISSUES_DIR"/*.md 2>/dev/null | head -1)
    if [ -z "$ISSUE_FILE" ]; then
      echo "❌ No issue drafts found."
      echo "💡 Run '/idd-issue new' to create one."
      return 1
    fi
    echo "📄 Using latest draft: $(basename "$ISSUE_FILE" .md)"
    return 0

  elif [[ "$ISSUE_INPUT" =~ ^[0-9]+$ ]]; then
    # Issue番号: マッチするファイルを検索
    ISSUE_FILE=$(ls "$ISSUES_DIR"/${ISSUE_INPUT}-*.md 2>/dev/null | head -1)
    if [ -z "$ISSUE_FILE" ]; then
      echo "❌ No draft found for issue #$ISSUE_INPUT"
      return 1
    fi
    echo "📄 Found: $(basename "$ISSUE_FILE" .md)"
    return 0

  else
    # ファイル名直接指定
    ISSUE_FILE="$ISSUES_DIR/$ISSUE_INPUT.md"
    if [ ! -f "$ISSUE_FILE" ]; then
      echo "❌ Issue not found: $ISSUE_INPUT"
      return 1
    fi
    return 0
  fi
}

# Issue ファイル一覧表示
list_issue_files() {
  if [ ! -d "$ISSUES_DIR" ] || [ -z "$(ls -A "$ISSUES_DIR"/*.md 2>/dev/null)" ]; then
    echo "📋 No issue drafts found."
    echo "💡 Create one with: /idd-issue new"
    return 0
  fi

  echo "📋 Issue drafts:"
  echo "=================================================="
  echo ""

  for file in "$ISSUES_DIR"/*.md; do
    [ -f "$file" ] || continue

    local filename=$(basename "$file" .md)
    local title=$(extract_title "$file")
    local modified=$(get_modified_time "$file")

    echo "📄 $filename"
    echo "   Title: $title"
    echo "   Modified: $modified"
    echo ""
  done

  echo "Commands:"
  echo "  /idd-issue view <issue-name>  # View issue"
  echo "  /idd-issue edit <issue-name>  # Edit issue"
  echo "  /idd-issue push <issue-name>  # Push to GitHub"
}

# タイトル抽出
# 引数: $1 - ファイルパス
extract_title() {
  local file="$1"
  head -1 "$file" | sed 's/^#[[:space:]]*//'
}

# 修正日時取得
# 引数: $1 - ファイルパス
get_modified_time() {
  local file="$1"
  stat -c %y "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d: -f1,2 || \
    date -r "$file" '+%Y-%m-%d %H:%M' 2>/dev/null
}

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

# Issue種別一覧表示
show_issue_types() {
  cat << 'EOF'
Available issue types:
  1. [Feature] - 新機能追加要求
  2. [Bug] - バグレポート
  3. [Enhancement] - 既存機能改善
  4. [Task] - 開発・メンテナンスタスク
EOF
}

# GitHub Issue取得
# 引数: $1 - Issue番号
# 戻り値: グローバル変数 ISSUE_TITLE, ISSUE_BODY に取得内容を設定
fetch_github_issue() {
  local ISSUE_NUM="$1"

  echo "🔗 Loading issue #$ISSUE_NUM from GitHub..."

  # Fetch issue using gh CLI
  if ! ISSUE_JSON=$(gh issue view "$ISSUE_NUM" --json 'title,body' 2>/dev/null); then
    echo "❌ GitHub CLI error. Make sure 'gh' is installed and authenticated."
    echo "💡 Run: gh auth login"
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

# Issue番号検証
# 引数: $1 - Issue番号
validate_issue_number() {
  local ISSUE_NUM="$1"

  if [ -z "$ISSUE_NUM" ]; then
    echo "❌ GitHub issue number is required."
    echo "Usage: /idd-issue load <issue-number>"
    return 1
  fi

  if ! [[ "$ISSUE_NUM" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid issue number. Must be a number."
    return 1
  fi

  return 0
}

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

# GitHub Issueプッシュ (新規作成)
# 引数: $1 - タイトル, $2 - 本文ファイル, $3 - 元のファイル名
push_new_issue() {
  local title="$1"
  local body_file="$2"
  local old_name="$3"

  echo "🆕 Creating new issue..."

  if NEW_URL=$(gh issue create --title "$title" --body-file "$body_file"); then
    ISSUE_NUM=$(echo "$NEW_URL" | sed 's/.*\/issues\///')

    echo "✅ New issue #$ISSUE_NUM created successfully!"
    echo "🔗 URL: $NEW_URL"

    # Rename file: new-* → {issue-num}-*
    NEW_FILENAME=$(echo "$old_name" | sed "s/^new-/$ISSUE_NUM-/")
    mv "$ISSUE_FILE" "$ISSUES_DIR/$NEW_FILENAME.md"
    echo "📝 Issue file renamed: $NEW_FILENAME"
    return 0
  else
    echo "❌ Failed to create issue"
    return 1
  fi
}

# GitHub Issueプッシュ (既存更新)
# 引数: $1 - Issue番号, $2 - タイトル, $3 - 本文ファイル
push_existing_issue() {
  local issue_num="$1"
  local title="$2"
  local body_file="$3"

  echo "🔄 Updating existing issue #$issue_num..."

  if gh issue edit "$issue_num" --title "$title" --body-file "$body_file"; then
    echo "✅ Issue #$issue_num updated successfully!"
    return 0
  else
    echo "❌ Failed to update issue"
    return 1
  fi
}

# セッションファイル存在確認
has_session() {
  [ -f "$SESSION_FILE" ]
}

# セッション情報読み込み
# グローバル変数にLAST_*変数を設定
load_session() {
  if has_session; then
    source "$SESSION_FILE"
    return 0
  fi
  return 1
}

# セッション情報保存
# 引数: $1 - ファイル名, $2 - Issue番号, $3 - タイトル, $4 - 種別, $5 - コマンド名, $6 - ブランチ名 (オプション)
save_session() {
  local filename="$1"
  local issue_num="$2"
  local title="$3"
  local issue_type="$4"
  local command="$5"
  local branch_name="${6:-}"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  cat > "$SESSION_FILE" << EOF
# Last issue session
LAST_ISSUE_FILE="$filename"
LAST_ISSUE_NUMBER="$issue_num"
LAST_ISSUE_TITLE="$title"
LAST_ISSUE_TYPE="$issue_type"
LAST_TIMESTAMP="$timestamp"
LAST_COMMAND="$command"
LAST_BRANCH_NAME="$branch_name"
EOF
}

# codex-mcpでIssue分析→ブランチ名提案
# 引数: $1 - Issue番号, $2 - タイトル, $3 - Issue内容
# 戻り値: グローバル変数 SUGGESTED_BRANCH に提案されたブランチ名を設定
analyze_issue_for_branch() {
  local issue_num="$1"
  local title="$2"
  local issue_content="$3"

  echo "🤖 Analyzing issue content with codex-mcp..."
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

  echo "⚠️  Branch already exists. Switch to it?"
  read -p "Switch? (Y/n): " SWITCH_CONFIRM

  if [[ "$SWITCH_CONFIRM" =~ ^[Yy]?$ ]]; then
    if git switch "$branch_name"; then
      echo "✅ Switched to existing branch: $branch_name"
      return 0
    else
      echo "❌ Failed to switch to branch"
      return 1
    fi
  else
    echo "❌ Operation cancelled"
    return 1
  fi
}

# 新規ブランチ作成・切り替え
# 引数: $1 - ブランチ名
# 戻り値: 0=成功, 1=失敗
create_branch_from_suggestion() {
  local branch_name="$1"

  echo ""
  echo "📌 Suggested branch name:"
  echo "   $branch_name"
  echo ""
  echo "🌿 Create and switch to this branch?"
  read -p "Proceed? (Y/n): " CONFIRM

  if [[ ! "$CONFIRM" =~ ^[Yy]?$ ]]; then
    echo "❌ Branch creation cancelled"
    return 1
  fi

  echo ""
  echo "🔧 Creating branch..."

  # Check if branch already exists
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    switch_to_existing_branch "$branch_name"
    return $?
  fi

  # Create and switch to new branch
  if git switch -c "$branch_name"; then
    echo "✅ Branch created and checked out: $branch_name"
    echo ""
    echo "Next steps:"
    echo "  1. Make your changes"
    echo "  2. Commit with: git commit -m '<type>(<scope>): <description>'"
    echo "  3. Push with: git push -u origin $branch_name"
    return 0
  else
    echo "❌ Failed to create branch"
    return 1
  fi
}

# Issueメタデータ一括抽出
# 引数: なし (グローバル変数 $ISSUE_FILE を使用)
# 戻り値: グローバル変数 ISSUE_FILENAME, ISSUE_TITLE, ISSUE_TYPE, ISSUE_NUM を設定
extract_issue_metadata() {
  ISSUE_FILENAME=$(basename "$ISSUE_FILE" .md)
  ISSUE_TITLE=$(extract_title "$ISSUE_FILE")
  ISSUE_TYPE=$(detect_issue_type "$ISSUE_TITLE")
  ISSUE_NUM=$(extract_issue_number "$ISSUE_FILENAME")
}

# Issue処理後のセッション更新
# 引数: $1 - コマンド名, $2 - ブランチ名 (オプション)
# 処理: extract_issue_metadata() → save_session() を実行
update_issue_session() {
  local command="$1"
  local branch_name="${2:-}"

  extract_issue_metadata
  save_session "$ISSUE_FILENAME" "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_TYPE" "$command" "$branch_name"
}
```

## 実行フロー

1. **設定読み込み**: メタデータの `config` セクションから設定を取得
2. **パス構築**: `{git_root}/{temp_dir}` で Issue ドラフトディレクトリパスを構築
3. **サブコマンド実行**: 以下のいずれかを実行

### Subcommand: new (デフォルト)

```bash
#!/bin/bash
setup_issue_env
ensure_issues_dir

echo "🚀 Launching issue-generator agent..."
echo ""
show_issue_types
echo ""

# Note: Claude will invoke issue-generator agent via Task tool
# Agent supports two modes:
#   - Codex mode (default): mcp__codex-mcp__codex で処理
#   - Claude mode: --use-claude フラグで Claude が直接処理
# Agent will guide the user through issue creation interactively
# After issue creation, the agent must save session using:
#   save_session "$FILENAME" "$ISSUE_NUM" "$TITLE" "$ISSUE_TYPE" "new"
```

### Subcommand: list

```bash
#!/bin/bash
setup_issue_env
list_issue_files
```

### Subcommand: view

```bash
#!/bin/bash
setup_issue_env

# Get issue name from argument or use latest
if ! find_issue_file "$1"; then
  exit 1
fi

echo "=================================================="
$PAGER "$ISSUE_FILE"
echo "=================================================="
echo "📊 $(wc -l < "$ISSUE_FILE") lines, $(wc -w < "$ISSUE_FILE") words"

# Update session
update_issue_session "view"

echo ""
echo "Commands:"
echo "  /idd-issue edit $(basename "$ISSUE_FILE" .md)  # Edit this issue"
echo "  /idd-issue push $(basename "$ISSUE_FILE" .md)  # Push to GitHub"
```

### Subcommand: edit

```bash
#!/bin/bash
setup_issue_env

# Get issue name from argument or use latest
if ! find_issue_file "$1"; then
  exit 1
fi

echo "📝 Opening in $EDITOR..."
$EDITOR "$ISSUE_FILE"
echo "✅ Issue edited"

# Update session
update_issue_session "edit"
```

### Subcommand: load

```bash
#!/bin/bash
setup_issue_env
ensure_issues_dir

# Validate issue number
if ! validate_issue_number "$1"; then
  exit 1
fi

ISSUE_NUM="$1"

# Fetch from GitHub
if ! fetch_github_issue "$ISSUE_NUM"; then
  exit 1
fi

# Generate filename
ISSUE_TYPE=$(detect_issue_type "$ISSUE_TITLE")
SLUG=$(generate_slug "$ISSUE_TITLE")
TIMESTAMP=$(date '+%y%m%d-%H%M%S')
FILENAME="${ISSUE_NUM}-${TIMESTAMP}-${ISSUE_TYPE}-${SLUG}.md"
ISSUE_FILE="$ISSUES_DIR/$FILENAME"

# Save issue file
save_issue_file "$ISSUE_FILE" "$ISSUE_TITLE" "$ISSUE_BODY"

# Save session
save_session "$FILENAME" "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_TYPE" "load"

echo "✅ Issue imported successfully!"
echo "📝 Saved as: $FILENAME"
echo ""
echo "Next steps:"
echo "  /idd-issue view $ISSUE_NUM   # View imported issue"
echo "  /idd-issue edit $ISSUE_NUM   # Edit imported issue"
echo "  /idd-issue push $ISSUE_NUM   # Push changes back to GitHub"
```

### Subcommand: push

```bash
#!/bin/bash
setup_issue_env

# Find issue file
if ! find_issue_file "$1"; then
  exit 1
fi

ISSUE_NAME=$(basename "$ISSUE_FILE" .md)

# Extract title
TITLE=$(extract_title "$ISSUE_FILE")
if [ -z "$TITLE" ]; then
  echo "❌ Could not extract title from issue"
  exit 1
fi

echo "📝 Title: $TITLE"

# Create temporary body file without H1 heading
TEMP_BODY=$(mktemp)
tail -n +2 "$ISSUE_FILE" > "$TEMP_BODY"

# Push to GitHub: Create new or update existing
if [[ "$ISSUE_NAME" =~ ^new- ]]; then
  push_new_issue "$TITLE" "$TEMP_BODY" "$ISSUE_NAME"
  RESULT=$?
  # After successful push, update ISSUE_NAME and ISSUE_FILE for session save
  if [ $RESULT -eq 0 ]; then
    ISSUE_NAME=$(basename "$ISSUE_FILE" .md)
  fi
elif [[ "$ISSUE_NAME" =~ ^[0-9]+ ]]; then
  ISSUE_NUM=$(extract_issue_number "$ISSUE_NAME")
  push_existing_issue "$ISSUE_NUM" "$TITLE" "$TEMP_BODY"
  RESULT=$?
else
  echo "❌ Invalid issue name format. Must start with 'new-' or a number."
  RESULT=1
fi

# Cleanup
rm -f "$TEMP_BODY"

if [ $RESULT -ne 0 ]; then
  exit 1
fi

# Update session after successful push
extract_issue_metadata
save_session "$ISSUE_FILENAME" "$ISSUE_NUM" "$TITLE" "$ISSUE_TYPE" "push"

echo ""
echo "🎉 Push completed!"
echo ""
echo "Next steps:"
echo "  /idd-issue list  # List all issues"
```

### Subcommand: branch

```bash
#!/bin/bash
setup_issue_env

# Parse options
CREATE_BRANCH=false  # Default: suggestion only (-n)

while getopts "nc" opt; do
  case $opt in
    n) CREATE_BRANCH=false ;;
    c) CREATE_BRANCH=true ;;
    *) echo "Usage: /idd-issue branch [-n|-c] [issue-number]" && exit 1 ;;
  esac
done
shift $((OPTIND-1))

# Get issue file
if ! find_issue_file "$1"; then
  exit 1
fi

# Load issue content and metadata
ISSUE_CONTENT=$(cat "$ISSUE_FILE")
extract_issue_metadata

echo "📋 Issue #$ISSUE_NUM: $ISSUE_TITLE"
echo ""

# Check session for saved branch name
SUGGESTED_BRANCH=""
if load_session && [ -n "$LAST_BRANCH_NAME" ] && [ "$LAST_ISSUE_NUMBER" = "$ISSUE_NUM" ]; then
  echo "💡 Found saved branch name: $LAST_BRANCH_NAME"
  echo ""
  read -p "Use this branch name? (Y/n): " USE_SAVED
  if [[ "$USE_SAVED" =~ ^[Yy]?$ ]]; then
    SUGGESTED_BRANCH="$LAST_BRANCH_NAME"
    echo "✅ Using saved branch name"
  fi
fi

# Analyze with codex-mcp if no saved branch
if [ -z "$SUGGESTED_BRANCH" ]; then
  analyze_issue_for_branch "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_CONTENT"
  # Note: Claude will call analyze_issue_for_branch() which sets SUGGESTED_BRANCH
  # Then save to session:
  save_session "$ISSUE_FILENAME" "$ISSUE_NUM" "$ISSUE_TITLE" "$ISSUE_TYPE" "branch" "$SUGGESTED_BRANCH"
fi

# Execute based on mode
if [ "$CREATE_BRANCH" = false ]; then
  # Suggestion mode: Display only
  echo ""
  echo "📌 Suggested branch name:"
  echo "   $SUGGESTED_BRANCH"
  echo ""
  echo "💡 To create this branch, run:"
  echo "   /idd-issue branch -c $ISSUE_NUM"
else
  # Create mode: Create and switch
  create_branch_from_suggestion "$SUGGESTED_BRANCH"
fi
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
   - セッション保存: `save_session()` でセッション情報を保存
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

## 使用例

### 新規Issue作成

```bash
/idd-issue new
# → issue-generatorエージェントが起動し、対話的にIssue作成
```

### Issue一覧表示

```bash
/idd-issue list
# → temp/idd/issues/ 内のすべてのIssueドラフトを表示
```

### Issue表示・編集

```bash
/idd-issue view 123           # Issue番号で検索
/idd-issue view new-251002-*  # ファイル名で指定
/idd-issue view               # 最新のIssueを表示

/idd-issue edit 123           # Issue番号で検索して編集
/idd-issue edit               # 最新のIssueを編集
```

### GitHub連携

```bash
/idd-issue load 123           # GitHubからIssue #123をImport
/idd-issue push new-251002-*  # 新規Issueを作成
/idd-issue push 123           # 既存Issue #123を更新
```

### ブランチ名提案・作成

```bash
/idd-issue branch             # セッションのIssueからブランチ名を提案 (作成しない)
/idd-issue branch 42          # Issue #42からブランチ名を提案
/idd-issue branch -c          # セッションのIssueからブランチ作成
/idd-issue branch -c 42       # Issue #42からブランチ作成

# 動作例: Issue #42 の場合 (初回)
# → codex-mcpが内容を分析
# → 提案: type=chore, scope=claude-commands
# → ブランチ名: chore-42/claude-commands/idd-issue-branch-auto
# → セッションに保存
# → -c オプションでブランチ作成・切り替え

# 2回目以降の実行
# → セッションから保存済みブランチ名を取得
# → 確認プロンプト表示: "Use this branch name? (Y/n)"
# → Y で保存済みブランチ名を再利用
# → n で codex-mcp による再分析
```

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
