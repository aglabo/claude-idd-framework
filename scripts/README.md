---
header:
  - src: README.md
  - "@(#): claude-idd-framework セットアップスクリプト"
title: claude-idd-framework
description: セットアップスクリプトの使用方法とトラブルシューティング
version: 1.0.0
created: 2025-10-06
authors:
  - atsushifx
changes:
  - 2025-10-06: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

# セットアップスクリプト

claude-idd-frameworkのセットアップを自動化するスクリプト群です。

## スクリプト一覧

### setup-idd.sh

メインセットアップスクリプト。claude-idd-frameworkの初期設定を自動実行します。

使用方法は以下の通りです。

```bash
bash .claude-idd/scripts/setup-idd.sh
```

実行内容は以下の通りです。

1. jq存在確認
2. `.mcp.json`マージ(merge-mcp.sh呼び出し)
3. GitHubイシューテンプレートコピー
4. GitHubワークフローコピー
5. 機密情報スキャン設定コピー

前提条件として、jq 1.5以降が必要です。

### merge-mcp.sh

`.mcp.json`設定ファイルのマージスクリプト。既存設定を優先してフレームワーク設定をマージします。

使用方法は以下の通りです。

```bash
bash .claude-idd/scripts/merge-mcp.sh
```

実行内容は以下の通りです。

1. 既存`.mcp.json`のバックアップ作成
2. jqによる設定マージ(既存設定優先)
3. `mcpServers`セクションのマージ
4. JSON検証
5. マージ結果の表示

前提条件として、jq 1.5以降が必要です。

## トラブルシューティング

### jqがインストールされていない

エラーメッセージは以下の通りです。

```
❌ jq not found. Please install jq.
```

解決方法は以下の通りです。

```bash
# Windows (Scoop)
scoop install jq

# macOS (Homebrew)
brew install jq

# Linux (Ubuntu/Debian)
sudo apt install jq
```

### .mcp.jsonマージエラー

エラーメッセージは以下の通りです。

```
❌ Generated JSON is invalid. Restoring backup...
```

原因として、既存の`.mcp.json`が不正なJSON形式の可能性があります。

解決方法は以下の通りです。

```bash
# JSON検証
jq empty .mcp.json

# 構文エラー修正後、再実行
bash .claude-idd/scripts/merge-mcp.sh
```

バックアップファイル(`.mcp.json.bak`)から復元することもできます。

```bash
# バックアップから復元
mv .mcp.json.bak .mcp.json
```

### セットアップスクリプト実行エラー

エラーメッセージは以下の通りです。

```
❌ Failed to merge .mcp.json
```

解決方法は以下の通りです。

```bash
# 1. merge-mcp.shを個別実行
bash .claude-idd/scripts/merge-mcp.sh

# 2. エラー内容確認

# 3. 手動でファイルコピー
cp .claude-idd/.mcp.json .mcp.json
```

### 既存ファイルとの競合

メッセージは以下の通りです。

```
ℹ️ .github/ISSUE_TEMPLATE already exists, skipping...
```

既存ファイルがある場合、スクリプトはスキップします。手動マージが必要な場合は以下を実行します。

```bash
# 既存ファイルと新規ファイルの差分確認
diff .github/ISSUE_TEMPLATE/ .claude-idd/.github/ISSUE_TEMPLATE/

# 必要に応じて手動マージ
```

## 手動セットアップ

スクリプトが使用できない環境では、以下の手順で手動セットアップを実行します。

```bash
# 1. .mcp.jsonコピー(既存ファイルがない場合)
cp .claude-idd/.mcp.json .mcp.json

# または既存ファイルがある場合はマージ
# (jqを使用した手動マージ)

# 2. GitHubテンプレートコピー
mkdir -p .github/ISSUE_TEMPLATE
cp .claude-idd/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/

# 3. GitHubワークフローコピー
mkdir -p .github/workflows
cp .claude-idd/.github/workflows/ci-secrets-scan.yaml .github/workflows/

# 4. 機密情報スキャン設定コピー
mkdir -p configs
cp .claude-idd/configs/gitleaks.toml configs/
```

## 関連ドキュメント

- [getting-started.md](../docs/getting-started/getting-started.md): インストールガイド全般
- [CLAUDE.md](../CLAUDE.md): フレームワーク概要

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
