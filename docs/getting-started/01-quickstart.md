---
header:
  - src: docs/getting-started/01-quickstart.md
  - "@(#)": Quick start guide for claude-idd-framework plugin installation and first command execution
title: claude-idd-framework
description: 5-minute quick start guide for installing and using claude-idd-framework plugin
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

## クイックスタート

## 1. プラグインのインストール

### 1.1 インストール手順

claude-idd-framework 以下の手順で簡単にインストールできます。

Claude Code の CL I ウィンドウで以下の手順を実行してください。

1. `marketplace`の追加:

   ```bash
   /plugin add marketplace https://github.com/aglabo/claude-idd-framework.git
   ```

   として、`claude-idd-framework`のマーケットプレイスを追加します。

2. 'plugin`のインストール:

   ```bash
   /plugin install claude-idd-framework@claude-idd-framework-marketplace
   ```

   として、`claude-idd-framework`プラグインをインストールします。

3. `claude`の再起動:

   ```bash
   /exit
   ```

   として、`claude`を終了します。再度、`claude code`を起動すると、プラグインが反映されています。

インストールが完了すると、MCP サーバー (`codex-mcp`、`serena-mcp`) が自動的に設定されます。

詳細な手順については、[Claude Code 公式ドキュメント](https://docs.claude.com/ja/docs/claude-code/plugins)を参照してください。

### 1.2 インストールの確認

インストールが正常に完了したことを確認します。

Claude Code でヘルプコマンドを実行してください。

```bash
/help
```

`custom-commands`タブを選択し、以下のコマンドが表示されていれば、インストールは成功です。

- `/claude-idd-framework:\idd\issue:new`
- `/claude-idd-framework:\idd-commit-message`
- `/claude-idd-framework:\idd-pr`

これらのコマンドが表示されない場合は、Claude Code を再起動してください。

## 2. 最初のコマンド実行

### 2.1 Issue 作成コマンドの実行

インストールが完了したら、最初のコマンドを実行してみましょう。

Claude Code で以下のコマンドを実行してください。

```bash
/claude-idd-framework:\idd\issue:new <タイトル>
```

このコマンドは、入力したタイトルから`GitHub Issue`のドラフトを作成します。
タイトルとサマリーが表示されるので、問題なければ`y`を押して次に進んでください。

### 2.2 実行結果の確認

コマンド実行後、以下の結果が表示されます。

- AI が生成した Issue タイトル
- Issue のサマリー (概要説明)
- 自動判定された Issue タイプ (feature、bug、documentation など)

生成された Issue ドラフトは `temp/idd/issues/` ディレクトリに保存されます。ファイル名は `new-YYYYMMDD-HHMMSS-[type]-[title].md` 形式で自動生成されます。

次のステップとして、`/claude-idd-framework:idd:issue:edit` コマンドで内容を編集したり、`/claude-idd-framework:idd:issue:push` コマンドで GitHub にプッシュしたりできます。

## 3. 次のステップ

### 3.1 詳細なセットアップ

プラグインの詳細な設定や前提条件について知りたい場合は、[インストールガイド](02-installation.md)を参照してください。

インストールガイドでは、必須ツールの確認、スキル要件、プラグインの詳細なインストール手順、初期セットアップ方法について説明しています。

### 3.2 基本的なワークフロー

Issue 作成、コミットメッセージ生成、Pull Request 作成などの基本的な操作を学びたい場合は、[基本的なワークフロー](03-basic-workflow.md)を参照してください。

基本的なワークフローガイドでは、Issue-Driven Development (IDD)、BDD 開発サイクル、テスト実行、トラブルシューティングについて詳しく説明しています。

### 3.3 コマンドリファレンス

利用可能な全コマンドの詳細なリファレンスについては、[CLAUDE.md](../../CLAUDE.md)を参照してください。

CLAUDE.md には、カスタムスラッシュコマンド、カスタムエージェント、MCP ツールの使用方法、開発のベストプラクティスなどが記載されています。
