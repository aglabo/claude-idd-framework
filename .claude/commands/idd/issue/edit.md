---
# Claude Code 必須要素
allowed-tools:
  Bash(
    cat:*, sed:*, head:*, source:*, git:*
  ),
  Read(*),
  Write(*),
  AskUserQuestion(*),
  mcp__codex-mcp__codex(*),
  mcp__serena-mcp__*,
  mcp__lsmcp__*
argument-hint: ""
description: 選択済みIssueドラフトを対話的に編集 (codex-mcp AI支援)

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session
  libs_dir: .claude/commands/_libs

# プロジェクト要素
title: idd-issue-edit
version: 1.0.0
created: 2025-10-20
authors:
  - atsushifx
changes:
  - 2025-10-20: 初版作成 - セッションから選択済みIssueの対話的編集機能を実装
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## /idd:issue:edit

セッションに保存されている選択済み Issue ドラフトを対話的に編集するコマンドです。

## 概要

このコマンドは以下の処理を実行します:

1. セッションファイル `.last.session` から選択済み Issue を取得
2. Issue ファイルの存在を確認
3. Issue 内容を CLI 形式で表示
4. 編集指示を取得 (AskUserQuestion)
5. codex-mcp で AI 支援編集を実行
6. 編集結果を表示し、継続編集または確定を選択
7. セッション情報を更新

## 前提条件

このコマンドを実行する前に:

```bash
# Issue を選択しておく必要があります
/idd:issue:list
```

## Bash 初期設定

各サブコマンドは `.claude/commands/_libs/` のヘルパー関数を使用します。

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

# Phase 1: Selection - セッションから Issue 取得
issue_file=$(get_selected_issue) || exit 1
validate_issue_file "$issue_file" || exit 1

# Phase 2: Display - Issue 内容表示
display_issue_header "$issue_file"
display_issue_metadata "$issue_file"

# Note: Claude が Read tool を使用して Issue 内容を表示
echo ""
echo "📄 Issue content:"
echo "File: $ISSUES_DIR/${issue_file}.md"
echo ""
echo "Claude will read the full issue content..."
echo ""
```

## 依存関係

### ヘルパーライブラリ

- `io-utils.lib.sh`: エラー出力 (`error_print`)
- `idd-env.lib.sh`: リポジトリ環境設定 (`_setup_repo_env`, `_get_temp_dir`)
- `idd-session.lib.sh`: セッション管理 (`_load_session`, `update_issue_session`)

## 使用例

### 基本的な使用方法

```bash
# 1. Issue を選択
/idd:issue:list

# 2. 選択した Issue を編集
/idd:issue:edit

# 出力例:
# 📝 Editing Issue: new-251020-014451-feature-idd-issue-edit-reimpl
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Issue: new-251020-014451-feature-idd-issue-edit-reimpl
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# Type: feature (new draft)
# Created: 20251020 014451
#
# [Issue content displayed via Read tool]
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Issue が未選択の場合

セッションファイルが存在しない場合:

```bash
❌ No Issue selected. Please run:
  /idd:issue:list
to select an Issue first.
```

### Issue ファイルが削除された場合

```bash
❌ Issue file not found: new-251020-014451-feature-idd-issue-edit-reimpl.md
Run: /idd:issue:list
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
    error_print <<EOF
No Issue selected. Please run:
  /idd:issue:list
to select an Issue first.
EOF
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
Run: /idd:issue:list
EOF
    return 1
  fi

  return 0
}

# ============================================================
# 表示関数
# ============================================================

# Issue ヘッダーを表示
# 引数: $1 - Issue ファイル名 (拡張子なし)
display_issue_header() {
  local issue_file="$1"

  echo ""
  echo "📝 Editing Issue: $issue_file"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Issue: $issue_file"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# Issue メタデータを表示
# 引数: $1 - Issue ファイル名 (拡張子なし)
display_issue_metadata() {
  local issue_file="$1"

  # Parse filename patterns:
  # new-{date}-{time}-{type}-{slug}
  # {issue_no}-{date}-{time}-{type}-{slug}
  if [[ "$issue_file" =~ ^new-([0-9]{6})-([0-9]{6})-([a-z]+)- ]]; then
    local date="${BASH_REMATCH[1]}"
    local time="${BASH_REMATCH[2]}"
    local issue_type="${BASH_REMATCH[3]}"
    echo "Type: $issue_type (new draft)"
    echo "Created: 20${date:0:2}${date:2:2}${date:4:2} ${time:0:2}${time:2:2}${time:4:2}"
  elif [[ "$issue_file" =~ ^([0-9]+)-([0-9]{6})-([0-9]{6})-([a-z]+)- ]]; then
    local issue_no="${BASH_REMATCH[1]}"
    local date="${BASH_REMATCH[2]}"
    local time="${BASH_REMATCH[3]}"
    local issue_type="${BASH_REMATCH[4]}"
    echo "Type: $issue_type (issue #$issue_no)"
    echo "Created: 20${date:0:2}${date:2:2}${date:4:2} ${time:0:2}${time:2:2}${time:4:2}"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}
```

## 今後の実装予定

### Phase 3: Edit Input

編集指示の入力機能:

```bash
# Note: Claude が AskUserQuestion を使用
# Question: "このIssueを編集しますか？"
# Options:
#   - "y (確定)": 編集せずに終了
#   - "Other": 編集指示を自由記述
```

### Phase 4: AI Edit Execution

codex-mcp による編集実行:

```bash
# Note: Claude が codex-mcp を使用して Issue を編集
# 1. user_instruction を含むプロンプトを作成
# 2. codex-mcp に送信
# 3. 編集済み Markdown を取得
# 4. Write tool でファイル更新
```

### Phase 5: Confirmation Loop

編集結果の確認と継続編集:

```bash
# 1. 編集後の Issue 内容を再表示
# 2. AskUserQuestion で継続確認
# 3. "y (確定)": 編集完了
# 4. "Other": さらに編集指示入力 → Phase 3 に戻る
```

### Phase 6: Session Update

セッション更新:

```bash
update_issue_session "$issue_file" "edit"

echo ""
echo "✅ Issue editing completed"
echo ""
echo "Next steps:"
echo "  - /idd:issue:view  : View edited Issue"
echo "  - /idd-issue push  : Push to GitHub"
echo "  - /idd-issue branch: Create branch"
```

## See Also

- `/idd:issue:list`: Issue 一覧から選択
- `/idd:issue:view`: Issue を表示
- `/idd-issue push`: GitHub に Issue をプッシュ

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
