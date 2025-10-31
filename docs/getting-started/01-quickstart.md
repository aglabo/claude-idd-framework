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

このセクションでは、`claude-idd-framework` を Claude Code に導入し、基本的なワークフローを実行するまでの手順を説明します。
初めて使用するかたでも、以下のステップを順番に実行すれば約 5分でセットアップできます。

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

生成された Issue ドラフトは `temp/idd/issues/` ディレクトリに保存されます。ファイル名は `new-YYYYMMDD-HHMMSS-[type]-[title].md` 形式です。
以後、作成した Issue にしたがって、ソフトウェアを開発します。

## 基本的な開発ワークフロー

ここまでで `claude-idd-framework` プラグインのインストールと、最初の Issue 作成コマンドの実行が完了しました。
ここからは、`IDD` の基本的な開発フローに従って、ソフトウェアを開発します。

1. ブランチの作成:
   生成された Issue に対応する開発用の Git ブランチを作成します。ブランチ名は Issue 番号やタイトルをもとに決定すると管理がしやすくなります。

2. 実装とコミット:
   Issue に対応するコードを実装します。実装したコードは Git リポジトリにコミットします。

3. `Pull Request` の作成:
   開発が終了したら、PR (`Pull Request`) を作成します。

4. レビューとマージ:
   作成した PR についてレビューし、問題なければ GitHub の main ブランチ (または、Issue 作成元のブランチ)にマージします。

このように、Issue を起点として一貫した開発ワークフロー (Issue → 実装 → Commit → PR) サイクルを回してソフトウェアを開発していきます。
このためのコマンドを一括して提供しているのが、`claude-idd-framework`です。

## See Also

より詳細な使い方や高度な設定については、以下のリソースを参照してください。

- [基本的な開発ワークフロー](03-basic-workflow.md)
  `calude-idd-framework`による基本的な開発ワークフローの説明。

- [Claude Code 公式ドキュメント - Overview](https://docs.anthropic.com/ja/docs/claude-code/overview)
  Claude Code の全体像、基本操作、機能概要を理解するための公式ガイド。

- [Claude Code Plugins ガイド](https://anthropic.mintlify.app/ja/docs/claude-code/plugins)
  プラグインの追加・削除方法や、カスタムコマンド、エージェント機能などの解説。

- [claude-idd-framework GitHub リポジトリ](https://github.com/aglabo/claude-idd-framework)
  プラグインのソースコードや Issue テンプレート、カスタム設定の詳細を確認可能。

- [GitHub Flow の基本](https://docs.github.com/ja/get-started/quickstart/github-flow)
  Claude Code の IDD フローと密接に関係する GitHub のワークフローを理解するために役立つ。

## License

Copyright (c) 2025 atsushifx
This software is released under the MIT License.
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)
