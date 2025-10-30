---
header:
  - src: docs/getting-started/02-installation.md
  - "@(#)": Comprehensive installation guide for claude-idd-framework plugin with prerequisites and setup
title: claude-idd-framework
description: Complete installation guide covering prerequisites, plugin installation, and initial configuration for claude-idd-framework
version: 1.0.0
created: 2025-10-30
authors:
  - atsushifx
changes:
  - 2025-10-30: Initial skeleton creation with heading structure
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

# インストールガイド

## 1. 前提条件

### 1.1 必須ツール

claude-idd-framework を使用するには、以下のツールが必要です。各ツールの最小バージョン要件と確認方法を記載します。

#### Claude Code

AI コーディングエージェントプラットフォームです。最小バージョン: 最新安定版。Claude Code が正常に起動していることを確認してください。

#### Git

バージョン管理システムです。最小バージョン: 2.23 以降。確認コマンド: `git --version`

#### GitHub CLI (gh)

GitHub 操作自動化ツールです。最小バージョン: 最新安定版。確認コマンド: `gh --version` および `gh auth status` で認証状態を確認してください。

#### jq

JSON プロセッサです。最小バージョン: 1.6 以降。確認コマンド: `jq --version`

### 1.2 スキル要件

claude-idd-framework を使用するには、基本的なコマンドライン操作と Git ワークフローの理解が必要です。Issue 作成、コミット、プルリクエストなどの GitHub 基本操作に慣れていることを推奨します。高度なプログラミングスキルは不要です。

### 1.3 自動設定される項目

プラグインのインストール時に、以下の MCP サーバーが自動的に設定されます。

- codex-mcp: 自律型コーディングエージェント
- serena-mcp: 構造化コード分析とシンボルインデックス
- lsmcp: 言語サーバープロトコル統合

これらのサーバーは手動設定不要で、インストール完了後すぐに使用できます。

## 2. プラグインのインストール

### 2.1 公式ドキュメントの参照

Claude Code の公式ドキュメント ([プラグインガイド](https://docs.claude.com/ja/docs/claude-code/plugins)) に従ってプラグインをインストールします。公式ドキュメントには最新のインストール手順とトラブルシューティング情報が記載されています。

### 2.2 マーケットプレイスからのインストール

claude-idd-framework のマーケットプレイス URL は以下の通りです。

```
https://github.com/aglabo/claude-idd-framework.git
```

この URL を Claude Code のプラグイン管理画面に入力してインストールします。

### 2.3 インストール手順

Claude Code でプラグインをインストールする手順は以下の通りです。

1. Claude Code のプラグイン管理画面を開きます
2. "Install from GitHub" を選択します
3. マーケットプレイス URL `https://github.com/aglabo/claude-idd-framework.git` を入力します
4. インストールボタンをクリックします
5. インストール完了を待ちます (約 2-3 分)
6. Claude Code を再起動します

再起動後、プラグインが正常にロードされ、カスタムコマンドが利用可能になります。

## 3. 初期セットアップ

### 3.1 カスタムコマンドの確認

インストールが完了したら、カスタムコマンドが正常にロードされているか確認します。Claude Code で `/help` コマンドを実行すると、利用可能なカスタムコマンド一覧が表示されます。以下のコマンドが表示されていれば、セットアップは成功です。

- `/claude-idd-framework:idd:issue:new`
- `/claude-idd-framework:idd:issue:list`
- `/claude-idd-framework:idd:issue:edit`
- `/claude-idd-framework:idd-commit-message`
- `/claude-idd-framework:idd-pr`

### 3.2 コマンド形式の理解

claude-idd-framework のコマンドには 2 つの形式があります。

完全修飾形式 (`/claude-idd-framework:idd:issue:new`) は推奨される形式で、すべての環境で確実に動作します。短縮形式 (`/idd:issue:new`) は開発環境でのみ使用できる簡易形式です。

本ドキュメントでは、一貫性と明確性を重視して完全修飾形式を使用します。実際の使用では、好みに応じて短縮形式を使用できますが、環境によって動作しない場合は完全修飾形式を使用してください。

### 3.3 動作確認

インストールとセットアップが正常に完了したか確認するため、簡単なテストコマンドを実行します。

`/claude-idd-framework:idd:issue:new` コマンドを実行してください。コマンドが正常に動作し、Issue ドラフト作成の対話が開始されれば、セットアップは完了です。

エラーが発生する場合は、Claude Code を再起動してから再度試してください。それでも問題が解決しない場合は、[基本的なワークフローガイド](03-basic-workflow.md)のトラブルシューティングセクションを参照してください。

## 4. 次のステップ

### 4.1 基本的なワークフローの学習

インストールとセットアップが完了したら、[基本的なワークフローガイド](03-basic-workflow.md)で実際の操作方法を学びましょう。

基本的なワークフローガイドでは、Issue 作成、コミットメッセージ生成、Pull Request 作成などの基本操作と、Issue-Driven Development (IDD) や BDD 開発サイクルなどの推奨ワークフローについて詳しく説明しています。
