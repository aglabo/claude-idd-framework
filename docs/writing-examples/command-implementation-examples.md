---
header:
  - src: command-implementation-examples.md
  - @(#): Command Implementation Examples
title: agla-logger
description: カスタムスラッシュコマンド実装の具体例とサンプルコード
version: 1.0.0
created: 2025-10-05
authors:
  - atsushifx
changes:
  - 2025-10-05: 初版作成 - custom-slash-commands.md から実装コード移動
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## カスタムスラッシュコマンド実装例

このドキュメントは、Claude Code 向けカスタムスラッシュコマンドを実装するための具体的なコード例を提供します。
Bash スクリプトと Python による実装パターンを示し、実用的なコマンド例を含みます。

## 実装方式概要

カスタムスラッシュコマンドは主に Bash スクリプト形式で実装され、以下のパターンに分類されます:

1. 環境設定・セッション管理パターン
2. ディレクトリ管理パターン
3. エージェント起動パターン
4. GitHub CLI 連携パターン

また、品質検証には Python を使用します。

## Bash 実装パターン

### Pattern 1: 環境設定とセッション管理

#### 環境変数設定

Git リポジトリルートを基準にしたパス設定:

```bash
#!/bin/bash
# 環境変数設定

setup_env() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  BASE_DIR="$REPO_ROOT/[base-path]"
  SESSION_FILE="$BASE_DIR/.session"
}
```text

実行例:

```bash
#!/bin/bash
setup_env() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  BASE_DIR="$REPO_ROOT/docs/.cc-sdd"
  SESSION_FILE="$BASE_DIR/.session"
}

setup_env
echo "REPO_ROOT: $REPO_ROOT"
echo "BASE_DIR: $BASE_DIR"
echo "SESSION_FILE: $SESSION_FILE"
```text

期待される出力:

```text
REPO_ROOT: /path/to/repository
BASE_DIR: /path/to/repository/docs/.cc-sdd
SESSION_FILE: /path/to/repository/docs/.cc-sdd/.session
```text

#### セッション保存

セッション情報をファイルに保存:

```bash
#!/bin/bash
# セッション保存

save_session() {
  local key="$1"
  local value="$2"

  mkdir -p "$BASE_DIR"
  cat > "$SESSION_FILE" << EOF
${key}=${value}
timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
EOF

  echo "💾 Session saved: $key=$value"
}
```text

実行例:

```bash
#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
BASE_DIR="$REPO_ROOT/docs/.cc-sdd"
SESSION_FILE="$BASE_DIR/.session"

save_session() {
  local key="$1"
  local value="$2"

  mkdir -p "$BASE_DIR"
  cat > "$SESSION_FILE" << EOF
${key}=${value}
timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
EOF

  echo "💾 Session saved: $key=$value"
}

# 使用例
save_session "namespace" "core"
save_session "module" "logger"

# セッションファイル内容確認
cat "$SESSION_FILE"
```text

期待される出力:

```text
💾 Session saved: namespace=core
💾 Session saved: module=logger
module=logger
timestamp=2025-10-05T10:30:00
```text

#### セッション読み込み

保存されたセッション情報を読み込み:

```bash
#!/bin/bash
# セッション読み込み

load_session() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "❌ No active session found."
    return 1
  fi

  source "$SESSION_FILE"
  echo "📂 Session: loaded"
  return 0
}
```text

実行例:

```bash
#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
BASE_DIR="$REPO_ROOT/docs/.cc-sdd"
SESSION_FILE="$BASE_DIR/.session"

load_session() {
  if [ ! -f "$SESSION_FILE" ]; then
    echo "❌ No active session found."
    return 1
  fi

  source "$SESSION_FILE"
  echo "📂 Session: loaded"
  return 0
}

# 使用例
if load_session; then
  echo "Namespace: $namespace"
  echo "Module: $module"
  echo "Timestamp: $timestamp"
fi
```text

期待される出力:

```text
📂 Session: loaded
Namespace: core
Module: logger
Timestamp: 2025-10-05T10:30:00
```text

### Pattern 2: ディレクトリ構造初期化

複数のサブディレクトリを一括作成:

```bash
#!/bin/bash
# ディレクトリ構造初期化

REPO_ROOT=$(git rev-parse --show-toplevel)
BASE_PATH="$REPO_ROOT/[base-path]"

for subdir in [subdir1] [subdir2] [subdir3]; do
  FULL_PATH="$BASE_PATH/$subdir"
  mkdir -p "$FULL_PATH"
  echo "✅ Created: $FULL_PATH"
done

echo ""
echo "🎉 Structure initialized"
```text

実行例 (/sdd init パターン):

```bash
#!/bin/bash
# /sdd init コマンド実装例

NAMESPACE_MODULE="$1"
NAMESPACE="${NAMESPACE_MODULE%%/*}"
MODULE="${NAMESPACE_MODULE##*/}"

REPO_ROOT=$(git rev-parse --show-toplevel)
SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
BASE_PATH="$SDD_BASE/$NAMESPACE/$MODULE"

for subdir in requirements specifications tasks implementation; do
  FULL_PATH="$BASE_PATH/$subdir"
  mkdir -p "$FULL_PATH"
  echo "✅ Created: $FULL_PATH"
done

# セッション保存
SESSION_FILE="$SDD_BASE/.session"
cat > "$SESSION_FILE" << EOF
namespace=$NAMESPACE
module=$MODULE
timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
EOF

echo ""
echo "🎉 SDD structure initialized for $NAMESPACE/$MODULE"
```text

実行方法:

```bash
bash sdd_init.sh core/logger
```text

期待される出力:

```text
✅ Created: /path/to/repository/docs/.cc-sdd/core/logger/requirements
✅ Created: /path/to/repository/docs/.cc-sdd/core/logger/specifications
✅ Created: /path/to/repository/docs/.cc-sdd/core/logger/tasks
✅ Created: /path/to/repository/docs/.cc-sdd/core/logger/implementation

🎉 SDD structure initialized for core/logger
```text

### Pattern 3: エージェント起動

エージェント起動のための準備処理:

```bash
#!/bin/bash
# エージェント起動フロー

echo "🚀 Launching [agent-name] agent..."
echo ""
echo "📝 Agent will:"
echo "  - [処理内容1]"
echo "  - [処理内容2]"
echo ""

# Note: Claude will invoke Task tool with [agent-name] agent
```text

実行例 (/sdd code パターン):

```bash
#!/bin/bash
# /sdd code コマンド実装例

REPO_ROOT=$(git rev-parse --show-toplevel)
SESSION_FILE="$REPO_ROOT/docs/.cc-sdd/.session"

# セッション読み込み
if [ ! -f "$SESSION_FILE" ]; then
  echo "❌ No active session found. Run '/sdd init' first."
  exit 1
fi

source "$SESSION_FILE"
echo "📂 Session: $namespace/$module"
echo ""
echo "💻 BDD Implementation Phase"
echo "🚀 Launching BDD coder agent..."
echo ""
echo "📝 Agent will:"
echo "  - Read task definitions from tasks/ directory"
echo "  - Implement features using Red-Green-Refactor cycle"
echo "  - Update todo.md with progress"
echo ""

# Note: Claude will invoke Task tool with bdd-coder agent
```text

期待される出力:

```text
📂 Session: core/logger

💻 BDD Implementation Phase
🚀 Launching BDD coder agent...

📝 Agent will:
  - Read task definitions from tasks/ directory
  - Implement features using Red-Green-Refactor cycle
  - Update todo.md with progress
```text

### Pattern 4: GitHub CLI 連携

GitHub Issue 操作の実装例:

```bash
#!/bin/bash
# GitHub CLI 連携パターン

setup_issue_env() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  ISSUES_DIR="$REPO_ROOT/temp/issues"
  mkdir -p "$ISSUES_DIR"
}

find_issue_file() {
  local issue_identifier="$1"

  # Issue 番号またはファイル名で検索
  if [[ "$issue_identifier" =~ ^[0-9]+$ ]]; then
    ISSUE_FILE="$ISSUES_DIR/${issue_identifier}-*.md"
  else
    ISSUE_FILE="$ISSUES_DIR/${issue_identifier}.md"
  fi

  if [ ! -f $ISSUE_FILE ]; then
    echo "❌ Issue file not found: $issue_identifier"
    exit 1
  fi
}

extract_title() {
  local file="$1"
  head -n 1 "$file" | sed 's/^# //'
}
```text

実行例 (/idd-issue push パターン):

```bash
#!/bin/bash
# /idd-issue push コマンド実装例

setup_issue_env() {
  REPO_ROOT=$(git rev-parse --show-toplevel)
  ISSUES_DIR="$REPO_ROOT/temp/issues"
}

find_issue_file() {
  local issue_name="$1"
  ISSUE_FILE=$(ls "$ISSUES_DIR"/*"$issue_name"*.md 2>/dev/null | head -n 1)

  if [ -z "$ISSUE_FILE" ]; then
    echo "❌ Issue file not found: $issue_name"
    exit 1
  fi

  ISSUE_NAME=$(basename "$ISSUE_FILE" .md)
}

extract_title() {
  local file="$1"
  head -n 1 "$file" | sed 's/^# //'
}

extract_issue_number() {
  local name="$1"
  echo "$name" | grep -oP '^\d+' || echo ""
}

# メイン処理
setup_issue_env
find_issue_file "$1"

TITLE=$(extract_title "$ISSUE_FILE")
TEMP_BODY=$(mktemp)
tail -n +2 "$ISSUE_FILE" > "$TEMP_BODY"

# 新規 Issue か既存 Issue の更新か判定
if [[ "$ISSUE_NAME" =~ ^new- ]]; then
  echo "🚀 Creating new issue..."
  gh issue create --title "$TITLE" --body-file "$TEMP_BODY"
else
  ISSUE_NUM=$(extract_issue_number "$ISSUE_NAME")
  if [ -n "$ISSUE_NUM" ]; then
    echo "🔄 Updating issue #$ISSUE_NUM..."
    gh issue edit "$ISSUE_NUM" --title "$TITLE" --body-file "$TEMP_BODY"
  else
    echo "❌ Cannot determine issue number from filename"
    rm -f "$TEMP_BODY"
    exit 1
  fi
fi

rm -f "$TEMP_BODY"
echo "✅ Issue operation completed"
```text

期待される出力 (新規作成時):

```text
🚀 Creating new issue...
https://github.com/user/repo/issues/123
✅ Issue operation completed
```text

期待される出力 (更新時):

```text
🔄 Updating issue #123...
✅ Issue operation completed
```text

## Python 検証パターン

### Phase 1: ファイル存在確認

```python
import os

file_path = ".claude/commands/[command-file].md"
if not os.path.exists(file_path):
    print("Error: Command file not found")
    exit(1)

print(f"✓ Command file found: {file_path}")
```text

### Phase 2: YAML フロントマター検証

```python
import yaml

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# フロントマター抽出
frontmatter_content = content.split('---')[1]

try:
    frontmatter = yaml.safe_load(frontmatter_content)
    print("✓ YAML syntax valid")
except yaml.YAMLError as e:
    print(f"Error: Invalid YAML syntax - {e}")
    exit(1)

# 必須フィールド確認
required_claude_fields = ['allowed-tools', 'argument-hint', 'description']
required_project_fields = ['title', 'version', 'created', 'authors']

for field in required_claude_fields:
    if field not in frontmatter:
        print(f"Error: Missing Claude Code field: {field}")
        exit(1)
    print(f"✓ Claude Code field found: {field}")

for field in required_project_fields:
    if field not in frontmatter:
        print(f"Error: Missing project field: {field}")
        exit(1)
    print(f"✓ Project field found: {field}")
```text

実行方法:

```bash
python << 'EOF'
import yaml

file_path = '.claude/commands/sdd.md'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

frontmatter_content = content.split('---')[1]
frontmatter = yaml.safe_load(frontmatter_content)

required_claude_fields = ['allowed-tools', 'argument-hint', 'description']
required_project_fields = ['title', 'version', 'created', 'authors']

for field in required_claude_fields:
    if field not in frontmatter:
        print(f"Error: Missing Claude Code field: {field}")
    else:
        print(f"✓ Claude Code field found: {field}")

for field in required_project_fields:
    if field not in frontmatter:
        print(f"Error: Missing project field: {field}")
    else:
        print(f"✓ Project field found: {field}")
EOF
```text

期待される出力:

```text
✓ Claude Code field found: allowed-tools
✓ Claude Code field found: argument-hint
✓ Claude Code field found: description
✓ Project field found: title
✓ Project field found: version
✓ Project field found: created
✓ Project field found: authors
```text

## 統合実装例

### /sdd コマンド完全実装

```bash
#!/bin/bash
# /sdd コマンド統合実装

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
  init)
    # プロジェクト構造初期化
    NAMESPACE_MODULE="$1"
    NAMESPACE="${NAMESPACE_MODULE%%/*}"
    MODULE="${NAMESPACE_MODULE##*/}"

    REPO_ROOT=$(git rev-parse --show-toplevel)
    SDD_BASE="$REPO_ROOT/docs/.cc-sdd"
    BASE_PATH="$SDD_BASE/$NAMESPACE/$MODULE"

    for subdir in requirements specifications tasks implementation; do
      FULL_PATH="$BASE_PATH/$subdir"
      mkdir -p "$FULL_PATH"
      echo "✅ Created: $FULL_PATH"
    done

    # セッション保存
    SESSION_FILE="$SDD_BASE/.session"
    cat > "$SESSION_FILE" << EOF
namespace=$NAMESPACE
module=$MODULE
timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)
EOF

    echo ""
    echo "🎉 SDD structure initialized for $NAMESPACE/$MODULE"
    ;;

  req|spec|task)
    # 各フェーズ処理
    REPO_ROOT=$(git rev-parse --show-toplevel)
    SESSION_FILE="$REPO_ROOT/docs/.cc-sdd/.session"

    if [ ! -f "$SESSION_FILE" ]; then
      echo "❌ No active session. Run '/sdd init' first."
      exit 1
    fi

    source "$SESSION_FILE"
    echo "📂 Session: $namespace/$module"
    echo "🚀 Launching $SUBCOMMAND phase..."
    ;;

  code)
    # BDD 実装フェーズ
    REPO_ROOT=$(git rev-parse --show-toplevel)
    SESSION_FILE="$REPO_ROOT/docs/.cc-sdd/.session"

    source "$SESSION_FILE"
    echo "📂 Session: $namespace/$module"
    echo ""
    echo "💻 BDD Implementation Phase"
    echo "🚀 Launching BDD coder agent..."
    ;;

  *)
    echo "Unknown subcommand: $SUBCOMMAND"
    echo "Available: init, req, spec, task, code"
    exit 1
    ;;
esac
```text

## エラーハンドリングパターン

### 基本パターン

```bash
if [ -z "$REQUIRED_VAR" ]; then
  echo "❌ Error: Required variable not set"
  exit 1
fi

echo "✅ Success: 処理完了"
```text

### メッセージ形式標準

```bash
# エラー
echo "❌ Error: [Specific error description]"

# 成功
echo "✅ Success: [成功メッセージ]"
echo "✅ Created: [作成されたファイル/ディレクトリ]"

# 情報
echo "💾 Session saved: [セッション情報]"
echo "🚀 Launching: [起動内容]"
echo "📂 Session: [セッション情報]"
```text

## 技術制約・要件

### 対応環境

- Shell: Bash (Git Bash on Windows 対応)
- 依存関係: Git コマンドのみ必須
- オプション依存: GitHub CLI (gh コマンド) - Issue 連携時のみ

### パフォーマンス

- 実行時間: 即座完了 (数秒以内)
- 処理複雑度: シンプルな処理のみ

### セキュリティ

- 機密情報のコード記述禁止
- ログ出力時も機密情報を含めない
- セッションファイルは `.gitignore` に追加推奨

## 注意事項

### 前提条件

- Git リポジトリ内での実行を前提
- Bash 4.0 以上推奨 (パラメーター展開機能使用)
- Windows では Git Bash または WSL 環境を使用

### カスタマイズポイント

- BASE_DIR: プロジェクト構造に応じて調整
- SESSION_FILE: セッション管理の必要性に応じて実装
- サブディレクトリ: プロジェクト要件に応じて変更

### デバッグ

Bash スクリプトのデバッグ:

```bash
# デバッグモード有効化
set -x

# 処理実行
[commands]

# デバッグモード無効化
set +x
```text

## See Also

- [カスタムスラッシュコマンド記述ルール](../writing-rules/custom-slash-commands.md): コマンド作成の基本ルール
- [エージェント検証実装例](agent-validation-examples.md): Python 検証パターン詳細
- [Writing Examples README](README.md): Examples ディレクトリ全体概要

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
