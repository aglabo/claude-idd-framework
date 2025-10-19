---
# Claude Code 必須要素
allowed-tools:
  Bash(
    cat:*, sed:*, head:*, source:*, git:*
  ),
  Read(*),
  mcp__serena-mcp__*,
  mcp__lsmcp__*
argument-hint: (no arguments)
description: 選択済みIssueドラフトの内容を表示

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  libs_dir: .claude/commands/_libs

# ag-logger プロジェクト要素
title: idd-issue-view
version: 1.0.0
created: 2025-10-19
authors:
  - atsushifx
changes:
  - 2025-10-19: 初版作成 - セッションから選択済みIssueの表示機能を実装
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd-issue view

セッションに保存されている選択済み Issue ドラフトの内容を表示するサブコマンドです。

## 概要

このコマンドは以下の処理を実行します:

1. セッションファイル `.last.session` から選択済み Issue を取得
2. Issue ファイルの存在を確認
3. ファイル名とタイトルを表示
4. Issue の内容を表示 (将来実装)

## Bash 初期設定

各サブコマンドは `.claude/commands/_libs/` のヘルパー関数を使用します。
詳細は `.claude/commands/_helpers/README.md` を参照。

```bash
#!/bin/bash
# Load helper libraries
REPO_ROOT=$(git rev-parse --show-toplevel)
LIBS_DIR="$REPO_ROOT/.claude/commands/_libs"

. "$LIBS_DIR/io-utils.lib.sh"
. "$LIBS_DIR/idd-env.lib.sh"
. "$LIBS_DIR/idd-session.lib.sh"

# Issue-specific environment setup
_setup_repo_env
ISSUES_DIR=$(_get_temp_dir "idd/issues")
SESSION_FILE="$ISSUES_DIR/.last.session"
```

## メインブロック

```bash
#!/bin/bash
# Main execution flow
issue_file=$(get_selected_issue) || exit 1
validate_issue_file "$issue_file" || exit 1

display_issue_info "$issue_file"
```

## 依存関係

### ヘルパーライブラリ

- `io-utils.lib.sh`: エラー出力 (`error_print`)
- `idd-env.lib.sh`: リポジトリ環境設定 (`_setup_repo_env`, `_get_temp_dir`)
- `idd-session.lib.sh`: セッション管理 (`_load_session`)

詳細は `.claude/commands/_helpers/README.md` を参照してください。

## 使用例

### 基本的な使用方法

```bash
# 1. まず Issue を選択
/idd-issue list

# 2. 選択した Issue の内容を表示
/idd-issue view

# 出力例:
# Selected Issue: 22-251016-150120-enhancement-idd-issue-rewrite
# Title: [Enhancement]idd-issueコマンドの全面的な書き直し
```

### Issue が未選択の場合

セッションファイルが存在しない、または Issue が選択されていない場合:

```bash
No issue selected. Run: /idd-issue list
```

### Issue ファイルが削除された場合

選択済み Issue のファイルが削除された場合:

```bash
Issue file not found: 22-251016-150120-enhancement-idd-issue-rewrite.md
Run: /idd-issue list
```

## Bash 関数ライブラリ

```bash
# ============================================================
# セッション管理関数
# ============================================================

# セッションファイルから選択済み Issue を取得
# 戻り値: 標準出力に Issue ファイル名、未選択時は exit 1
get_selected_issue() {
  if ! _load_session "$SESSION_FILE" || [ -z "$LAST_ISSUE_FILE" ]; then
    echo "No issue selected. Run: /idd-issue list"
    return 1
  fi

  echo "$LAST_ISSUE_FILE"
  return 0
}

# ============================================================
# 検証関数
# ============================================================

# Issue ファイルの存在を確認
# 引数: $1 - Issue ファイル名 (拡張子なし)
# 戻り値: 0=存在, 1=不在 (エラーメッセージ表示)
validate_issue_file() {
  local issue_file="$1"
  local full_path="$ISSUES_DIR/${issue_file}.md"

  if [ ! -f "$full_path" ]; then
    error_print <<EOF
Issue file not found: ${issue_file}.md
Run: /idd-issue list
EOF
    return 1
  fi

  return 0
}

# ============================================================
# 表示関数
# ============================================================

# Issue のファイル名とタイトルを表示
# 引数: $1 - Issue ファイル名 (拡張子なし)
display_issue_info() {
  local issue_file="$1"
  local full_path="$ISSUES_DIR/${issue_file}.md"

  # Extract title from first line (remove leading "# ")
  local title=$(head -1 "$full_path" | sed 's/^# //')

  echo ""
  echo "Selected Issue: $issue_file"
  echo "Title: $title"
  echo ""
  echo "Issue content will be displayed by Read tool:"
  echo "File: $full_path"
  echo ""
  echo "Claude Code will now read the full issue content..."
}
```

## 今後の拡張予定

### フル内容表示

Issue の全内容を表示する機能:

```bash
display_issue_content() {
  local issue_file="$1"
  local full_path="$ISSUES_DIR/${issue_file}.md"

  echo ""
  echo "=== Issue Content ==="
  cat "$full_path"
}
```

### メタデータ抽出

Issue のメタデータ (種別、作成日、slug) を表示する機能:

```bash
display_issue_metadata() {
  local issue_file="$1"

  # Parse filename: {issue_no}-{date}-{time}-{issue_type}-{slug}
  # Example: 22-251016-150120-enhancement-idd-issue-rewrite
  local issue_no=$(echo "$issue_file" | cut -d'-' -f1)
  local date=$(echo "$issue_file" | cut -d'-' -f2)
  local time=$(echo "$issue_file" | cut -d'-' -f3)
  local issue_type=$(echo "$issue_file" | cut -d'-' -f4)
  local slug=$(echo "$issue_file" | cut -d'-' -f5-)

  echo ""
  echo "Issue #$issue_no"
  echo "Type: $issue_type"
  echo "Created: 20${date:0:2}-${date:2:2}-${date:4:2} ${time:0:2}:${time:2:2}:${time:4:2}"
  echo "Slug: $slug"
}
```

## See Also

- `/idd-issue list`: Issue 一覧から選択
- `/idd-issue edit`: Issue を編集
- `/idd-issue push`: GitHub に Issue をプッシュ

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
