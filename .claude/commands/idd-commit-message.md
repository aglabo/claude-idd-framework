---
# Claude Code 必須要素
allowed-tools: Bash(git:*), Read(*), Write(*)
argument-hint: [subcommand] [--lang=ja|en]
description: Git コミットメッセージ自動生成 - Staged changes 分析による Conventional Commits 準拠メッセージ作成

# 設定変数
config:
  temp_dir: temp
  message_file: commit_message_current.md
  default_lang: ja
  editor: ${EDITOR:-code}

# サブコマンド定義
subcommands:
  new: "コミットメッセージ生成して保存"
  view: "現在のメッセージ表示"
  edit: "メッセージ編集"
  commit: "コミット実行"

# ag-logger プロジェクト要素
title: idd-commit-message
version: 0.5.0
created: 2025-09-30
authors:
  - atsushifx
changes:
  - 2025-10-02: Bash 版に簡略化、メタデータに設定を集約
  - 2025-09-30: サブコマンド機能付きで新規作成
---

## Quick Reference

### Usage

```bash
# Main command (generate and save to temp file)
/idd-commit-message [options]

# Subcommands
/idd-commit-message <subcommand> [options]
```

### Main Options

- `--lang=<code>`: メッセージ言語 (ja/en, default: ja)

### Subcommands

- `new`: コミットメッセージを生成して temp ファイルに保存
- `view`: 現在のコミットメッセージを表示
- `edit`: 現在のコミットメッセージをエディタで編集
- `commit`: 現在のコミットメッセージで実際にコミット実行

### Examples

```bash
# コミットメッセージ生成（tempファイルに自動保存）
/idd-commit-message

# サブコマンドで詳細操作
/idd-commit-message view      # 保存されたメッセージ確認
/idd-commit-message edit      # メッセージ編集
/idd-commit-message commit    # コミット実行

# 英語でメッセージ生成
/idd-commit-message --lang=en
```

<!-- markdownlint-disable no-duplicate-heading -->

## Implementation

このコマンドでは、Claude が以下の処理を実行::

1. **設定読み込み**: メタデータの `config` セクションから設定を取得
2. **パス構築**: `{git_root}/{temp_dir}/{message_file}` でメッセージファイルパスを構築
3. **サブコマンド実行**: 以下のいずれかを実行

### Subcommand: new (デフォルト)

```bash
#!/bin/bash
# Setup
REPO_ROOT=$(git rev-parse --show-toplevel)
MSG_FILE="$REPO_ROOT/temp/commit_message_current.md"
mkdir -p "$REPO_ROOT/temp"

# Git context collection
echo "📊 Collecting Git context..."
git log --oneline -10
git diff --cached --name-only
echo ""

# Claude generates commit message and saves to MSG_FILE
echo "🤖 Generating commit message..."
echo "Message will be saved to: $MSG_FILE"
```

### Subcommand: view

```bash
#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
MSG_FILE="$REPO_ROOT/temp/commit_message_current.md"

if [ ! -f "$MSG_FILE" ]; then
  echo "❌ No commit message found. Run '/idd-commit-message new' first."
  exit 1
fi

echo "📝 Current commit message:"
echo "========================================"
cat "$MSG_FILE"
echo "========================================"
echo "📊 Stats: $(wc -l < "$MSG_FILE") lines, $(wc -w < "$MSG_FILE") words"
```

### Subcommand: edit

```bash
#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
MSG_FILE="$REPO_ROOT/temp/commit_message_current.md"
EDITOR="${EDITOR:-code}"

if [ ! -f "$MSG_FILE" ]; then
  echo "❌ No commit message found. Run '/idd-commit-message new' first."
  exit 1
fi

echo "📝 Opening in editor: $EDITOR"
"$EDITOR" "$MSG_FILE"
echo "✅ Message edited: $MSG_FILE"
```

### Subcommand: commit

```bash
#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
MSG_FILE="$REPO_ROOT/temp/commit_message_current.md"

if [ ! -f "$MSG_FILE" ]; then
  echo "❌ No commit message found. Run '/idd-commit-message new' first."
  exit 1
fi

# Check staged files
if [ -z "$(git diff --cached --name-only)" ]; then
  echo "❌ No staged changes. Stage files with 'git add' first."
  exit 1
fi

echo "📝 Committing with message:"
echo "----------------------------------------"
cat "$MSG_FILE"
echo "----------------------------------------"

# Execute commit
git commit -F "$MSG_FILE" && {
  echo "🎉 Commit successful!"
  rm "$MSG_FILE"
  echo "✅ Message file cleaned up."
} || {
  echo "❌ Commit failed."
  exit 1
}
```

## Examples

### 使用例 1: コミットメッセージ生成と保存

**実行**: `/idd-commit-message` または `/idd-commit-message new`

**期待出力**:

```text
📊 Collecting Git context...
76767af config(cspell): cspell辞書の語彙を整理
04f972f chore(claude-commands): issue作成コマンドをバージョンアップ
...

.claude/commands/idd-commit-message.md

🤖 Generating commit message...
Message will be saved to: C:\path\to\repo\temp\commit_message_current.md

✅ Generated commit message:
docs(commands): commit-message コマンドを Bash 版に簡略化

- Python 実装から Bash 実装に変更
- メタデータに設定変数を集約
- サブコマンド処理を簡潔化

📝 Saved to: C:\path\to\repo\temp\commit_message_current.md

Next steps:
  /idd-commit-message view   - View message
  /idd-commit-message edit   - Edit message
  /idd-commit-message commit - Commit with message
```

### 使用例 2: 標準ワークフロー

```bash
# 1. ファイルをステージング
git add .claude/commands/idd-commit-message.md

# 2. コミットメッセージ生成
/idd-commit-message new

# 3. メッセージ確認
/idd-commit-message view

# 4. 必要に応じて編集
/idd-commit-message edit

# 5. コミット実行
/idd-commit-message commit
```

### 使用例 3: 英語でメッセージ生成

**実行**: `/idd-commit-message --lang=en`

**期待動作**: 英語で Conventional Commits 準拠のコミットメッセージを生成。

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
