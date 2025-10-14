---
# Claude Code 必須要素
allowed-tools:
  - Bash(git:*, gh:*, mkdir:*, jq:*, tail:*, mktemp:*, mv:*)
  - Read(temp/idd/issues/**)
  - Write(temp/idd/issues/**)
argument-hint: [issue-number or filename]
description: Issue下書きをGitHubにPushする

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session

# ag-logger プロジェクト要素
title: /idd:issue:push
version: 1.6.2
created: 2025-10-21
authors:
  - atsushifx
changes:
  - 2025-10-21: v1.0.0 - 初版作成 (/idd-issue pushから分離)
  - 2025-10-21: T1実装完了 (Environment and Session Management)
  - 2025-10-21: T2実装完了 (Issue File Identification and Validation)
  - 2025-10-22: T3実装完了 (GitHub CLI Integration - New Issue Creation)
  - 2025-10-22: v1.1.0 - bashスクリプトをリファクタリング (関数化)
  - 2025-10-22: v1.1.1 - _load_issue_session()をライブラリに移設
  - 2025-10-22: v1.1.2 - _validate_issue_file(), _extract_issue_content()をライブラリに移設
  - 2025-10-22: v1.1.3 - 関数のエラーハンドリング改善 (exit → return)
  - 2025-10-22: v1.2.0 - ドキュメント構造を改善（スクリプトライブラリセクション追加）
  - 2025-10-22: v1.2.1 - check_prerequisites()のエラーハンドリング改善
  - 2025-10-22: v1.3.0 - T4実装完了 (既存Issue更新機能) - push_existing_issue()実装
  - 2025-10-22: v1.4.0 - ドキュメント構成再編成 (初期設定→前提条件→使い方→メインルーチンの順に変更)
  - 2025-10-22: v1.5.0 - T5実装完了 (ファイルリネームとセッション更新) - rename_new_issue_file(), update_session_after_push()実装
  - 2025-10-22: v1.6.0 - セッション管理改善 (変数命名規則の統一、_save_issue_session実装、title→TITLE)
  - 2025-10-22: v1.6.1 - 関数命名規則の統一 (save_issue_session→_save_issue_session、関数配置の最適化)
  - 2025-10-23: v1.6.2 - Windows互換性修正 (grep -P → sed による URL 抽出)
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd:issue:push - Issue下書きをGitHubにPush

Issue下書きファイルをGitHubにプッシュします。
新規Issue作成または既存Issue更新を自動判定します。

## 初期設定

### bash 初期化

```bash
#!/bin/bash
set -euo pipefail

# Environment setup
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

# Load helper libraries
. "$LIBS_DIR/idd-session.lib.sh"
. "$LIBS_DIR/prereq-check.lib.sh"

# Issue-specific environment
ISSUES_DIR="$REPO_ROOT/temp/idd/issues"
SESSION_FILE="$ISSUES_DIR/.last.session"
```

### 前提条件

```bash
# Step 1: Check prerequisites (GitHub CLI)
validate_github_full || exit 1
```

## 使い方

このコマンドは以下のステップを実行します:

1. **前提条件チェック** (`validate_github_full`)
   - `gh` コマンドの存在確認
   - GitHub CLI認証状態の確認
   - ※ `.claude/commands/_libs/prereq-check.lib.sh` の関数を使用

2. **セッション読み込み** (`_load_issue_session`)
   - セッションファイルからIssue情報を読み込み
   - エラーハンドリング

3. **Issueファイル検証** (`_validate_issue_file`)
   - セッションファイルから取得したIssueファイルの存在確認

4. **Issue内容抽出** (`_extract_issue_content`)
   - H1見出し (1行目) をタイトルとして抽出
   - 2行目以降を本文として抽出

5. **GitHub操作** (`push_new_issue` / `push_existing_issue`)
   - ファイル名が `new-` で始まる場合: 新規Issue作成
   - ファイル名が数字で始まる場合: 既存Issue更新

6. **次のステップ提案**
   - Issue表示、ブランチ作成、一覧表示の提案

## メインルーチン

このセクションでは、コマンドの実行フローを示します。
(前提条件まで実行しているはずなので、Step2から実行)

```bash
# Step 2: Load session
if ! _load_issue_session "$SESSION_FILE"; then
  exit 1
fi

# Step 3: Validate issue file
if ! _validate_issue_file "$ISSUES_DIR" "$filename"; then
  exit 1
fi

# Step 4: Extract issue content
if ! _extract_issue_content "$issue_file"; then
  exit 1
fi

# Step 5: Push to GitHub (detect new vs existing)
if [[ "$filename" =~ ^new- ]]; then
  if ! push_new_issue "$title" "$body"; then
    exit $?
  fi

  # T5: Rename file for new issue
  if ! rename_new_issue_file "$filename" "$issue_number"; then
    exit $?
  fi

  # T5: Update session with new filename
  update_session_after_push "$new_filename" "$issue_number"
else
  if ! push_existing_issue "$filename" "$title" "$body"; then
    exit $?
  fi

  # T5: Update session (no rename needed)
  update_session_after_push "$filename" "$issue_number"
fi

# Step 6: Display next steps
echo ""
echo "💡 Next steps:"
echo "   - '/idd:issue:view' to view the issue"
echo "   - '/idd:issue:branch' to create a branch for this issue"
echo "   - '/idd:issue:list' to see all issues"

exit 0
```

## Exit Codes

このコマンドは以下の終了コードを返します:

- `0`: 成功
- `1`: gh CLI 未インストール、セッションまたはファイル検証エラー
- `2`: GitHub認証必要
- `5`: GitHub CLI エラー（新規Issue作成時）
- `6`: Issue番号パースエラー
- `7`: 無効なファイル名フォーマット
- `8`: GitHub CLI エラー（既存Issue更新時）
- `9`: ファイルリネームエラー（ファイル不存在、リネーム失敗）
- `10`: ファイル衝突（リネーム先ファイルが既に存在）

## スクリプトライブラリ

このセクションでは、`/idd:issue:push`コマンドの完全な実装を提供します。

```bash
##
# Note: GitHub CLI チェックは .claude/commands/_libs/prereq-check.lib.sh の
#       validate_github_full() 関数を使用します。
##

##
# @description Parse issue number from GitHub URL using Perl regex
# @arg $1 string GitHub CLI output containing URL (https://github.com/.../issues/NUMBER)
# @set issue_number Extracted issue number from URL
# @example
#   gh_output="https://github.com/user/repo/issues/42"
#   if parse_issue_number_from_url "$gh_output"; then
#     echo "Issue number: $issue_number"
#   fi
# @exitcode 0 If issue number successfully parsed and set
# @exitcode 1 If URL parsing failed or issue number not found
# @see push_new_issue
parse_issue_number_from_url() {
  local gh_output="$1"

  # Extract issue number from URL using sed (portable)
  issue_number=$(echo "$gh_output" | \
    sed -n 's|.*https://github.com/[^/]*/[^/]*/issues/\([0-9]*\).*|\1|p' | head -n 1)

  if [[ -z "$issue_number" ]]; then
    echo "❌ Failed to parse issue number from GitHub response."
    echo "   Response: $gh_output"
    return 1
  fi

  return 0
}

##
# @description Create new issue on GitHub using gh CLI
# @arg $1 string Issue title
# @arg $2 string Issue body (Markdown content)
# @set issue_number Issue number assigned by GitHub
# @set issue_url Full URL to the created issue
# @example
#   if push_new_issue "Bug: Login fails" "Detailed description..."; then
#     echo "Created issue #$issue_number at $issue_url"
#   fi
# @exitcode 0 If issue created successfully
# @exitcode 5 If gh CLI command failed (network/permission error)
# @exitcode 6 If issue number parsing from response failed
# @see parse_issue_number_from_url
# @see rename_new_issue_file
push_new_issue() {
  local title="$1"
  local body="$2"
  local gh_output
  local gh_exit_code=0

  echo "🆕 Detected new issue (will create on GitHub)"
  echo "📤 Creating new issue on GitHub..."

  # Create issue with gh CLI
  gh_output=$(gh issue create --title "$title" --body "$body" 2>&1) || gh_exit_code=$?

  # Handle errors
  if [[ $gh_exit_code -ne 0 ]]; then
    echo "❌ Failed to create issue on GitHub."
    echo "   Error: $gh_output"
    echo "💡 Check your network connection and repository permissions."
    return 5
  fi

  # Parse issue number from URL
  if ! parse_issue_number_from_url "$gh_output"; then
    return 6
  fi

  # Extract full URL using sed (portable)
  issue_url=$(echo "$gh_output" | \
    sed -n 's|.*\(https://github.com/[^/]*/[^/]*/issues/[0-9]*\).*|\1|p' | \
    head -n 1)

  echo "✅ Issue created: #$issue_number"
  echo "   URL: $issue_url"

  return 0
}

##
# @description Update existing issue on GitHub by extracting number from filename
# @arg $1 string Filename without extension (format: {number}-{suffix})
# @arg $2 string Updated issue title
# @arg $3 string Updated issue body (Markdown content)
# @set issue_number Issue number extracted from filename
# @example
#   if push_existing_issue "42-bug-fix" "Updated title" "New description..."; then
#     echo "Updated issue #$issue_number"
#   fi
# @exitcode 0 If issue updated successfully
# @exitcode 7 If filename format invalid (must match ^[0-9]+-)
# @exitcode 8 If gh CLI command failed (issue not found/permission error)
# @see _validate_issue_file
push_existing_issue() {
  local filename="$1"
  local title="$2"
  local body="$3"
  local gh_output
  local gh_exit_code=0

  # Extract issue number from filename
  if [[ "$filename" =~ ^([0-9]+)- ]]; then
    issue_number="${BASH_REMATCH[1]}"
    echo "📝 Detected existing issue #$issue_number (will update on GitHub)"
  else
    echo "❌ Invalid filename format: $filename"
    echo "💡 Expected format: 'new-*' or '{number}-*'"
    echo "   Run '/idd:issue:list' to see available issues."
    return 7
  fi

  echo "📤 Updating issue #$issue_number on GitHub..."

  # Update issue with gh CLI
  gh_output=$(gh issue edit "$issue_number" \
    --title "$title" --body "$body" 2>&1) || gh_exit_code=$?

  # Handle errors
  if [[ $gh_exit_code -ne 0 ]]; then
    echo "❌ Failed to update issue #$issue_number"
    echo "   Error: $gh_output"
    echo "💡 Check that issue #$issue_number exists and you have"
    echo "   permission to edit it."
    return 8
  fi

  echo "✅ Issue updated: #$issue_number"
  echo "   URL: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/issues/$issue_number"

  return 0
}

##
# @description Rename new issue file from new-{suffix} to {number}-{suffix} format
# @arg $1 string Old filename without .md extension (format: new-{suffix})
# @arg $2 string Issue number assigned by GitHub
# @set new_filename New filename after rename ({number}-{suffix})
# @example
#   if rename_new_issue_file "new-bug-login-20251022" "42"; then
#     echo "Renamed to: $new_filename.md"
#   fi
# @exitcode 0 If file renamed successfully
# @exitcode 9 If source file not found or mv command failed
# @exitcode 10 If target filename already exists (conflict)
# @see push_new_issue
# @see update_session_after_push
rename_new_issue_file() {
  local old_filename="$1"
  local issue_number="$2"
  local suffix

  # Extract suffix from new-* filename
  if [[ "$old_filename" =~ ^new-(.+)$ ]]; then
    suffix="${BASH_REMATCH[1]}"
    new_filename="${issue_number}-${suffix}"
  else
    echo "❌ Invalid filename format: $old_filename"
    echo "💡 Expected format: new-*"
    return 9
  fi

  # Construct file paths
  local old_file="$ISSUES_DIR/${old_filename}.md"
  local new_file="$ISSUES_DIR/${new_filename}.md"

  # Check source file exists
  if [[ ! -f "$old_file" ]]; then
    echo "❌ Source file not found: $old_file"
    return 9
  fi

  # Check for filename conflict (T5-5)
  if [[ -f "$new_file" ]]; then
    echo "❌ Target file already exists: $new_file"
    echo "💡 Please resolve the conflict manually or delete the existing file."
    return 10
  fi

  # Perform rename
  if ! mv "$old_file" "$new_file"; then
    echo "❌ Failed to rename file"
    return 9
  fi

  echo "✅ Renamed: $old_filename.md → $new_filename.md"
  return 0
}

##
# @description Update session file after successful push operation
# @arg $1 string Filename without .md extension (post-rename if new issue)
# @arg $2 string Issue number (from GitHub)
# @global TITLE Issue title (read-only, passed to _save_issue_session)
# @global ISSUE_TYPE Issue type (read-only, passed to _save_issue_session)
# @global COMMIT_TYPE Commit type (read-only, passed to _save_issue_session)
# @global BRANCH_TYPE Branch type (read-only, passed to _save_issue_session)
# @example
#   if update_session_after_push "42-bug-fix" "42"; then
#     echo "Session saved"
#   fi
# @exitcode 0 If session file updated successfully
# @exitcode 1 If _save_issue_session failed
# @see _save_issue_session
# @see rename_new_issue_file
update_session_after_push() {
  local new_filename="$1"
  local new_issue_number="$2"

  # _save_issue_session は内部でグローバル変数（TITLE, ISSUE_TYPE等）を参照
  if ! _save_issue_session "$SESSION_FILE" "$new_filename" "$new_issue_number" "push"; then
    echo "⚠️ Warning: Failed to update session"
    return 1
  fi

  echo "💾 Session updated: $new_filename (#$new_issue_number)"
  return 0
}
```

## See Also

- `/idd:issue:new`: 新しいIssue作成
- `/idd:issue:list`: Issue一覧表示
- `/idd:issue:load`: GitHub IssueをImport
- `.claude/commands/_libs/idd-session.lib.sh`: セッション管理ライブラリ

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
