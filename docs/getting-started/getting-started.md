---
header:
  - src: getting-started.md
  - "@(#): claude-idd-framework クイックスタートガイド"
title: claude-idd-framework
description: claude-idd-frameworkの概要、Gitサブモジュールインストール、カスタムスラッシュコマンドの使用方法
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

# claude-idd-frameworkを始める

## claude-idd-frameworkとは

### フレームワークの概要

claude-idd-frameworkは、Claude Codeを使用したAI支援開発のための統一開発標準を提供するドキュメント中心のフレームワークです。プロジェクト全体で一貫した開発標準、執筆ルール、カスタムツールを適用することで、AI支援開発の品質と効率を向上させます。

従来のコードベースのフレームワークと異なり、本フレームワークはドキュメント、設定ファイル、カスタムツール定義を中心に構成されています。これにより、プロジェクトの特性に応じた柔軟なカスタマイズが可能です。

### 主要コンポーネント

claude-idd-frameworkは4つのカテゴリで構成されています。

カスタムスラッシュコマンド(`.claude/commands/`)は、Claude Codeで直接実行可能なコマンド群です。Conventional Commits準拠のコミットメッセージ生成(`/idd-commit-message`)、構造化されたGitHub Issue作成(`/idd-issue`)、Pull Requestドラフト生成(`/idd-pr`)、Spec-Driven Developmentワークフロー(`/sdd`)、6段階品質検証(`/validate-debug`)などが含まれます。

カスタムエージェント(`.claude/agents/`)は、特定タスクに特化したAIエージェントです。BDD厳格実装(`bdd-coder`)、コミットメッセージ生成(`commit-message-generator`)、Issue作成(`issue-generator`)、PR作成(`pr-generator`)が用意されています。

執筆ルール(`docs/writing-rules/`)は、すべてのドキュメントに適用される汎用的な執筆ガイドラインです。禁止パターン、プロジェクト固有表記法、フロントマター規則、ドキュメントテンプレート、カスタムツール作成ガイドが含まれます。

AI開発標準(`docs/for-AI-dev-standards/`)は、AI支援開発のプロジェクト固有標準です。環境セットアップ、MCPツール必須化、コード探索パターン、BDDワークフロー、コーディング規約、テスト実装、品質ゲート、ドキュメント品質基準、ソースコードテンプレートが定義されています。

### Gitサブモジュールとして使用する利点

Gitサブモジュールとして組み込むことで、以下の利点が得られます。

バージョン管理の観点では、フレームワーク本体の更新をプロジェクトから独立して管理できます。特定バージョンへの固定、段階的な更新適用、複数プロジェクト間での一貫性維持が可能です。

更新の容易さとしては、`git submodule update --remote`コマンドで最新版を取得できます。フレームワーク側の改善を即座に反映でき、手動ファイルコピーが不要です。

プロジェクト標準化では、チーム全体で同一のツールセット、執筆ルール、開発標準を共有できます。新規メンバーのオンボーディングが簡素化され、コードレビュー基準が統一されます。

設定の分離により、プロジェクト固有の設定とフレームワーク標準設定を明確に区別できます。`.mcp.json`、GitHubテンプレート、ワークフローをマージまたは選択的に適用可能です。

## インストール

### 前提条件

以下のツールとサービスが必要です。

| 項目 | 要件 | 確認方法 |
|------|------|---------|
| Git | 2.13以降(サブモジュール機能) | `git --version` |
| jq | 1.5以降(JSON処理) | `jq --version` |
| Node.js | 20以降 | `node --version` |
| pnpm | 10以降 | `pnpm --version` |
| Claude Code | インストール済み | `/help`で確認 |
| MCPサーバー | lsmcp, serena-mcp, codex-mcp | `.mcp.json`で確認 |

jqのインストールは以下のコマンドで実行できます。

```bash
# Windows (Chocolatey)
choco install jq

# macOS (Homebrew)
brew install jq

# Linux (Ubuntu/Debian)
sudo apt install jq
```

MCPサーバーのインストール方法については、各サーバーの公式ドキュメントを参照してください。

### Gitサブモジュールとして追加

プロジェクトルートで以下のコマンドを実行します。

```bash
# 1. サブモジュールとして追加
git submodule add https://github.com/atsushifx/claude-idd-framework.git .claude-idd

# 2. サブモジュール初期化
git submodule update --init --recursive

# 3. .gitmodulesファイル確認
cat .gitmodules
```

`.gitmodules`ファイルに以下の内容が追加されていることを確認します。

```ini
[submodule ".claude-idd"]
  path = .claude-idd
  url = https://github.com/atsushifx/claude-idd-framework.git
```

サブモジュールが正常に追加されたことを確認します。

```bash
# サブモジュールディレクトリの存在確認
ls -la .claude-idd

# サブモジュールステータス確認
git submodule status
```

### インストール後の設定

セットアップスクリプトを使用して自動設定を実行します。

```bash
# セットアップスクリプト実行
bash .claude-idd/scripts/setup-idd.sh
```

このスクリプトは以下の処理を自動実行します。

1. jq存在確認
2. `.mcp.json`のマージ(既存設定優先)
3. GitHubイシューテンプレートのコピー(`.github/ISSUE_TEMPLATE/*.yml`)
4. GitHubワークフローのコピー(`.github/workflows/ci-secrets-scan.yaml`)
5. 機密情報スキャン設定のコピー(`configs/gitleaks.toml`)

スクリプトが失敗した場合、以下の手動セットアップ手順を実行します。

```bash
# 1. .mcp.jsonマージ(既存設定がある場合)
bash .claude-idd/scripts/merge-mcp.sh

# または .mcp.jsonがない場合はコピー
cp .claude-idd/.mcp.json .mcp.json

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

`.mcp.json`が正しくマージされていることを確認します。

```bash
# MCPサーバー設定確認
jq '.mcpServers | keys' .mcp.json
```

出力に`"lsmcp"`, `"serena-mcp"`, `"codex-mcp"`が含まれていることを確認します。

### インストールの検証

Claude Codeでフレームワークのコマンドが認識されることを確認します。

```bash
# Claude Codeでヘルプ表示
/help
```

以下のコマンドが表示されることを確認します。

- `/idd-commit-message`: Gitコミットメッセージ自動生成
- `/idd-issue`: GitHub Issue作成
- `/idd-pr`: Pull Request作成
- `/sdd`: Spec-Driven Development
- `/validate-debug`: 6段階品質検証

サンプルコマンドを実行して動作確認します。

```bash
# コマンド実行例
/idd-commit-message help
```

MCPサーバーが正常に動作していることを確認します。

```bash
# プロジェクト概要取得(lsmcp)
"lsmcp でプロジェクト概要を取得して"

# シンボル検索(serena-mcp)
"serena-mcp でシンボル一覧を取得して"
```

### サブモジュールの更新

フレームワークの最新版を取得するには以下のコマンドを実行します。

```bash
# 最新版を取得
git submodule update --remote .claude-idd

# 更新内容を確認
cd .claude-idd
git log -1
cd ..

# 変更をコミット
git add .claude-idd
git commit -m "chore(deps): update claude-idd-framework"
```

特定バージョンに固定する場合は以下の手順を実行します。

```bash
cd .claude-idd
git checkout v1.0.0  # 固定したいバージョンタグ
cd ..
git add .claude-idd
git commit -m "chore(deps): pin claude-idd-framework to v1.0.0"
```

### トラブルシューティング

サブモジュールが空の場合、以下のコマンドで初期化します。

```bash
git submodule update --init --recursive
```

jqがインストールされていない場合、以下のエラーが表示されます。

```
❌ jq not found. Please install jq.
```

前提条件セクションのインストール手順に従ってjqをインストールします。

コマンドが認識されない場合、`.mcp.json`が正しく設定されているか確認します。

```bash
# MCPサーバー設定確認
jq '.mcpServers' .mcp.json

# Claude Code再起動
# Claude Codeを一度終了して再起動
```

MCPサーバーが動作しない場合、各サーバーのログを確認します。

```bash
# Claude Codeのログ確認
# 設定 → 開発者ツール → ログ
```

## カスタムスラッシュコマンド

### スラッシュコマンドとは

スラッシュコマンドは、Claude Codeで直接実行可能なカスタムコマンドです。`/`で始まるコマンド名を入力することで、定義済みのタスクを実行できます。

利用可能なコマンドは`/help`で確認できます。

```bash
/help
```

各コマンドは`.claude/commands/`ディレクトリにMarkdown形式で定義されています。コマンド実行時、Claudeはファイル内のプロンプトと実装ガイドラインに従ってタスクを実行します。

### コアコマンドリファレンス

#### /idd-commit-message

Conventional Commits準拠のコミットメッセージを自動生成します。

基本的な使用方法は以下の通りです。

```bash
# 1. ファイルをステージング
git add [files]

# 2. コミットメッセージ生成(日本語)
/idd-commit-message

# 3. 生成されたメッセージを確認・編集
/idd-commit-message view
/idd-commit-message edit

# 4. コミット実行
/idd-commit-message commit
```

サブコマンドは以下が利用可能です。

- `new`: 新規メッセージ生成(デフォルト)
- `view`: 現在のメッセージ表示
- `edit`: メッセージ編集
- `commit`: コミット実行

英語でメッセージを生成する場合は以下のオプションを使用します。

```bash
/idd-commit-message --lang=en
```

#### /idd-issue

構造化されたGitHub Issueドラフトを作成します。

基本的な使用方法は以下の通りです。

```bash
# Feature Issue作成
/idd-issue feature "ユーザー認証機能の追加"

# Bug Issue作成
/idd-issue bug "ログイン時のエラー"

# Enhancement Issue作成
/idd-issue enhancement "パフォーマンス改善"

# Task Issue作成
/idd-issue task "ドキュメント更新"
```

生成されたドラフトは`temp/issues/`ディレクトリに保存されます。内容を確認後、GitHub上でIssueを作成します。

#### /idd-pr

Pull Requestドラフトを自動生成します。

基本的な使用方法は以下の通りです。

```bash
# 現在のブランチ変更からPR作成
/idd-pr

# ベースブランチ指定
/idd-pr --base=develop
```

生成されたドラフトは`temp/pr/`ディレクトリに保存されます。内容を確認後、`gh pr create`コマンドまたはGitHub UIでPRを作成します。

#### /sdd

Spec-Driven Developmentワークフローを管理します。

基本的な開発フローは以下の通りです。

```bash
# 1. プロジェクト初期化
/sdd init [namespace]/[module]

# 2. 要件定義
/sdd req

# 3. 設計仕様作成
/sdd spec

# 4. タスク分解
/sdd tasks

# 5. 実装
/sdd coding

# 6. コミット
/sdd commit
```

各サブコマンドの詳細は以下の通りです。

- `init`: プロジェクト構造初期化(`docs/.cc-sdd/[namespace]/[module]/`配下に作業ディレクトリ作成)
- `req`: 要件定義フェーズ(対話的な要件収集、`requirements.md`作成)
- `spec`: 設計仕様フェーズ(MCPツール活用、`specification.md`作成)
- `tasks`: タスク分解フェーズ(BDD階層でのタスク分解、TodoWrite使用)
- `coding`: 実装フェーズ(BDDエージェント起動、Red-Green-Refactor)
- `commit`: コミットフェーズ(対話的ファイル選択、メッセージ生成、コミット実行)

#### /validate-debug

6段階の包括的品質検証を実行します。

基本的な使用方法は以下の通りです。

```bash
/validate-debug
```

検証項目は以下の通りです。

1. 静的解析(ESLint、型チェック)
2. ユニットテスト実行
3. 統合テスト実行
4. ビルド検証
5. ドキュメント品質検証
6. 機密情報スキャン

各段階で問題が検出された場合、詳細なレポートが生成されます。

### 一般的なワークフロー

新機能開発の標準フローは以下の通りです。

```bash
# 1. 要件定義と設計
/sdd init features/user-auth
/sdd req
/sdd spec

# 2. 実装
/sdd tasks
/sdd coding

# 3. コミットとPR作成
/sdd commit
/idd-pr
```

バグ修正の標準フローは以下の通りです。

```bash
# 1. Issue作成
/idd-issue bug "ログインエラーの修正"

# 2. 修正実装
# ... コード修正 ...

# 3. コミット
git add [files]
/idd-commit-message
/idd-commit-message commit
```

ドキュメント更新の標準フローは以下の通りです。

```bash
# 1. ドキュメント編集
# ... ドキュメント更新 ...

# 2. 品質検証
/validate-debug

# 3. コミット
git add docs/
/idd-commit-message
/idd-commit-message commit
```

### トラブルシューティング

コマンドが見つからない場合、以下を確認します。

```bash
# 1. .mcp.json設定確認
jq '.mcpServers' .mcp.json

# 2. Claude Code再起動

# 3. コマンド定義ファイル確認
ls -la .claude-idd/.claude/commands/
```

コマンド実行エラーが発生した場合、以下を確認します。

```bash
# 1. コマンドヘルプ確認
/[command-name] help

# 2. 必要な前提条件確認(Git状態、ステージングファイルなど)

# 3. Claude Codeのログ確認
```

エージェント起動エラーの場合、`.claude/agents/`ディレクトリの定義ファイルを確認します。

## 次のステップ

フレームワークの基本的な使用方法を習得したら、以下のトピックを学習することでさらに活用できます。

執筆ルールの学習では、`docs/writing-rules/`配下のドキュメントを参照します。特に`01-writing-rules.md`の禁止パターン、`02-frontmatter-guide.md`のメタデータ規則を理解することで、品質の高いドキュメントを作成できます。

AI開発標準の確認では、`docs/for-AI-dev-standards/`配下のドキュメントを参照します。`02-core-principles.md`のMCP必須化ルール、`05-bdd-workflow.md`のBDD実装詳細を理解することで、AI支援開発の効率が向上します。

カスタムエージェントの活用では、`.claude/agents/`配下の定義ファイルを参照します。`bdd-coder.md`の厳格BDD実装、`commit-message-generator.md`のメッセージ生成ロジックを理解することで、高度な自動化が実現できます。

チームでの活用方法では、複数メンバーでのフレームワーク共有、プロジェクト固有のカスタマイズ、CI/CDパイプラインへの統合を検討します。

カスタムツールの作成では、`docs/writing-rules/04-custom-slash-commands.md`と`docs/writing-rules/05-custom-agents.md`を参照して、プロジェクト固有のスラッシュコマンドやエージェントを作成できます。

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
