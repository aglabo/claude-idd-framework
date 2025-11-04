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

## インストールガイド

## 1. 前提条件

### 1.1 必須ツール

`claude-idd-framework` を利用するために、いくつかのツールを準備しておく必要があります。
これらのツールは、開発環境の自動化や GitHub 連携、構成ファイルの処理など、フレームワーク全体の動作において中核的な役割を果たします。

#### Claude Code

`claude-idd-framework` の動作基盤となる AI コーディングプラットフォームです。
`Claude Code` がインストール済みであり、正常に起動していることを確認してください。
最小バージョン: 2.0 以降。
確認コマンド:

```bash
claude --version
```

#### Git

ソースコードのバージョン管理用ツールです。`claude-idd-framework` は Git フローと密接に連携して動作します。
最小バージョン: 2.23 以降。
確認コマンド:

```bash
git --version
```

#### GitHub CLI (gh)

GitHub CLI は、Issue 作成や Pull Request の生成などを自動化するためのツールです。
`claude-idd-framework` の IDD コマンドはこの CLI を利用して GitHub API と通信するため、GitHub が認証済みである必要があります。

最小バージョン: 2.81 以降
確認コマンド:

```bash
gh --version
gh auth status
```

#### jq

`jq` は JSON データを整形・解析するためのツールです。
`claude-idd-framework` が返す各種データを加工・抽出する際に使用します。

最小バージョン: 1.6
確認コマンド:

```bash
jq --version
```

`claude-idd-framework`が動作するためには、上記のツールがコマンドラインから実行できることが必要です。

### 1.2 スキル要件

claude-idd-framework を効果的に活用するためには、いくつかの基本的なスキルが求められます。ただし、高度なプログラミング知識や AI モデル構築の専門知識は不要です。
以下に、利用開始前に習得しておくとよいスキルセットを整理します。

#### コマンドライン操作の理解

`claude-idd-framework` の操作は、主にターミナルまたは Claude Code の CLI 環境で行います。そのため、基本的なコマンドライン操作 (例: ディレクトリ移動、ファイル確認、コマンド実行) に慣れていることが望まれます。
特に、パス指定・環境変数・シェルスクリプトの基本的な扱いを理解していると、セットアップやトラブルシューティングが容易になります。

#### Git ワークフローの理解

このフレームワークは「Issue-Driven Development (IDD)」を前提に設計されています。したがって、以下の Git および GitHub の基本操作に精通しているとスムーズです。

- リポジトリのクローン・フェッチ・プル・プッシュ
- ブランチの作成と切り替え
- コミットとコミットメッセージの編集
- GitHub Issue と Pull Request の作成および管理

特に、`GitHub Cli (gh)' による GitHub 操作に慣れておくと、claude-idd-framework のコマンドフローを直感的に理解できます。

#### YAML・Markdown の基礎知識

Issue テンプレートや Pull Request テンプレートは YAML および Markdown 形式で定義されます。これらのフォーマットに対する基礎的な知識があると、テンプレートのカスタマイズやメンテナンスが容易です。

#### 結論

claude-idd-framework は、開発者の生産性を最大化するために設計されています。そのため、基本的なコマンドライン操作と Git ワークフローの理解さえあれば十分です。
導入初期の段階では、Claude Code のガイドやサンプルワークフローを併用しながら進めると、短時間で環境に慣れることができます。

### 1.3 mcpサーバの設定

`claude-idd-framework`のインストールすると、複数の `MCP` (`Model Control Protocol`) サーバーを設定します。
これにより、`Claude Code`は複雑な処理をツールに任せ、トークン効率のよいな IDD の開発フローを実現します。

#### `codex-mcp`

`codex-mcp` は、`codex` コマンドの MCP サーバーインターフェースです。

`codex` は自律型 AI コーディングエージェントツールであり、以下のような機能を提供します。

- 自然言語プロンプトからの複雑なコード生成
- 多段階ワークフローの自動実行 (探索・分析・実装を一連の流れで処理)
- トークン効率のよい反復処理 (独立したセッションで動作)

claude-idd-framework では、Issue サマリー生成、ブランチ名提案、コミットメッセージ下書きなど、複雑な文脈理解が必要なタスクで `codex-mcp` を活用しています。

**注:**
OpenAI の Codex API (廃止済み) とは無関係です。

#### `serena-mcp`

`serena-mcp` は、構造化コード解析とシンボルインデックスの管理を担当します。
特に、プロジェクト全体を対象とした静的解析や依存関係のマッピングを行う点が特徴です。

- 関数・クラス・変数のシンボル検索
- 依存関係グラフの生成
- 変更差分の影響範囲解析

`serena-mcp` は claude-idd-framework 内で、コード変更提案や PR レビュー補助機能に利用されます。

#### `lsmcp`

`lsmcp` (`Language Server MCP`) は、複数言語の LSP (Language Server Protocol) を Claude Code に統合する MCP サーバーです。
これにより、言語を問わず一貫した補完や診断が可能になります。

- TypeScript、Python、Go、Rust など主要言語に対応
- シンタックスエラーの即時検出
- コード補完・型情報の提示

claude-idd-framework の多言語対応はこの lsmcp によって実現されています。

**注:**
`lsmcp`は、デフォルトではインストールされません。
ユーザーが`.mcp.json`を書き替えて、`Claude Code`に組み込む必要があります。

#### 確認方法

以下のコマンドで、`Claude Code`に組み込まれた MCP サーバーを確認できます。

```bash
claude mcp list
```

出力例:

```bash
plugin:claude-idd-framework:serena-mcp: uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project . - ✓ Connected
plugin:claude-idd-framework:codex-mcp: codex mcp-server - ✓ Connected
```

上記のように、表示されれば MCP サーバーは正常にインストールされています。

## 2. プラグインのインストール

claude-idd-framework を導入するには、Claude Code のマーケットプレイス経由でプラグインを追加・インストールします。
以下の手順に従うことで、環境を安全かつ確実に構築できます。

### 2.1 マーケットプレイスの追加

最初に、インストールしたいプラグイン用に、マーケットプレイスを追加します。
マーケットプレイスは Claude Code が外部リポジトリを参照し、プラグインの依存関係や MCP サーバーを自動管理するための仕組みです。

以下のコマンドを Claude Code の CLI 環境で実行します。

```bash
/plugin marketplace add https://github.com/aglabo/claude-idd-framework.git
```

このコマンドによって、Claude Code の設定ファイルに claude-idd-framework のマーケットプレイスエントリが追加されます。
以下のコマンドで、登録されたマーケットプレイスを確認します。

```bash
/plugin marketplace list
  ⎿  Configured marketplaces:
       • claude-idd-framework-marketplace
```

上記のように、`claude-idd-framework-marketplace`が表示されればマーケットプレイスは正常に追加されています。

### 2.2 プラグインのインストール

マーケットプレイスを追加したら、次に `claude-idd-framework` プラグイン本体をインストールします。
このプラグインは、Claude Code 環境内で **Issue-Driven Development (IDD)** を自動化するための拡張モジュールであり、内部で複数の MCP サーバーを利用します。

インストールコマンドは以下の通りです。

```bash
/plugin install claude-idd-framework@claude-idd-framework-marketplace
```

このコマンドを実行すると、Claude Code は以下の処理を順に実行します。

1. claude-idd-framework のリポジトリをクローン
2. 依存する MCP サーバー (codex-mcp, serena-mcp) を自動設定
3. Claude Code の設定ファイルにプラグインを登録

完了後、次のような出力が表示されれば成功です。

```bash
⎿  ✓ Installed claude-idd-framework. Restart Claude Code to load new plugins.
```

> 補足:
> Claude Code のプラグインマネージャーは依存関係を自動的に解決するため、手動で npm や pip を使用する必要はありません。
> ただし、インストール時にネットワークが不安定な場合は、再実行が必要な場合があります。

### 2.3 Claude Code の再起動

`claude-idd-framework` のインストールが完了したら、Claude Code を再起動してプラグインを有効化します。
インストールによって内部設定（プラグイン登録、MCP サーバー構成、キャッシュの再生成など）が変更されるため、再起動しないと変更が反映されません。

再起動手順は以下の通りです。

1. Claude Code の終了:
   CLI 環境で、以下のコマンドを実行します。

   ```bash
   /exit
   ```

   このコマンドにより、現在のセッションが終了し、すべてのプラグインと MCP サーバーが停止します。

2. Claude Code の再起動:
   Claude Code を再起動します。

   ```bash
   claude
   ```

   これにより Claude Code が起動し、CLI ウィンドウが表示されます。

3. plugin の確認:
   `/plugin`コマンドでインストール済みのプラグインが、確認できます。
   `/plugin`コマンドを実行後、

   ```bash
   1. Browse and install plugins
   ```

   を選択し、`claude-idd-framework`プラグインが表示されれば、正常にインストールされています。

再起動が完了すれば、Claude Code 環境に `claude-idd-framework` が組み込まれます。
以降、プラグインコマンド`/claude-idd-framework:`コマンド群を使用できるようになります。

## 3. インストールの確認

`claude-idd-framework` のインストールが完了したら、プラグインと MCP サーバーが正しく動作しているかを確認します。
このセクションでは、基本的な動作確認とコマンド利用可能性を検証します。

### 3.1 ヘルプコマンドによる確認

Claude Code のヘルプコマンドで、`claude-idd-framework`がインストールされているか確認します。
Claude Code の CLI で、以下のコマンドを実行します。

```bash
/help
```

実行後、Claude Code の出力画面で `custom-commands` タブに切り替えます。
この一覧に `claude-idd-framework`コマンド群が表示されていれば、インストールは正常に完了しています。

出力例:

```bash
/claude-idd-framework:\idd\issue:branch             Issue選択からブランチ作成・コミットまでの統合ワークフロー
  /claude-idd-framework:\idd\issue:edit               選択済みIssueドラフトを対話的に編集する (-framework-marketplace)
  /claude-idd-framework:\idd\issue:list               Issueドラフト一覧表示し、選択 (claude-idd-framework-marketplace)
  /claude-idd-framework:\idd\issue:load               GitHub IssueをロードしてMarkdown形式で保存
  /claude-idd-framework:\idd\issue:new                新しくIssueを作成する　
❯ /claude-idd-framework:\idd\issue:push               Issue下書きをGitHubにPushする
                                                      (plugin:claude-idd-framework@claude-idd-framework-marketplace)
```

#### *表示されない場合の対処**

一覧に `claude-idd-framework` のコマンドが表示されない場合は、以下の手順を確認してください。

1. Claude Code の再起動:
   以下のコマンドで、Claude Code を終了します。

   ```bash
   /exit
   ```

   その後、Claude Code を起動し`/help`を実行します。

2. プラグインのインストール状態を確認:
   Claude Code にプラグインがインストールされているか確認します。

   ```bash
   /plugin list
   ```

   出力に `claude-idd-framework` が含まれているかを確認します。

3. MCP サーバー接続を確認:
   次のコマンドで、MCP の状態を確認します。

   ```bash
   /mcp
   ```

   `codex-mcp`, `serena-mcp`が `✓ Connected` と表示されていれば正常です。

4. プラグインの再インストール:
   ネットワークの問題により、プラグインが正常にインストールされていない場合が考えられます。
   コマンドラインで次のコマンドを実行し、プラグインを再インストールします。

   ```bash
   claude plugin remove claude-idd-framework
   claude plugin install claude-idd-framework
   ```

---

これらの確認を通じて、プラグインとコマンドが正しく登録されていれば、`claude-idd-framework` の環境は正常に構成されています。

### 3.2 利用可能なコマンド

正常にインストールされると、以下のコマンドが利用可能になります。

#### 1. IDD Issue管理コマンド

| コマンド            | サブコマンド | 引数                | 説明                                       |
| ------------------- | ------------ | ------------------- | ------------------------------------------ |
| `/idd:issue:new`    |              | `[title]`           | 新しくIssueを作成する                      |
| `/idd:issue:list`   |              | なし                | Issueドラフト一覧表示し、選択              |
| `/idd:issue:load`   |              | `<issue_number>`    | GitHub IssueをロードしてMarkdown形式で保存 |
| `/idd:issue:edit`   |              | なし                | 選択済みIssueドラフトを対話的に編集        |
| `/idd:issue:push`   |              | なし                | Issue下書きをGitHubにPush                  |
| `/idd:issue:branch` | `new`        | `[--base <branch>]` | ブランチ提案を生成                         |
|                     | `commit`     | なし                | 提案されたブランチを作成して切替           |

#### 2. 開発コマンド群

| コマンド              | サブコマンド | 引数                 | 説明                                      |
| --------------------- | ------------ | -------------------- | ----------------------------------------- |
| `/idd-commit-message` |              | なし                 | コミットメッセージ生成 (デフォルト: new)  |
|                       | `new`        | なし                 | コミットメッセージ生成して保存            |
|                       | `view`       | なし                 | 保存済みメッセージ表示                    |
|                       | `edit`       | なし                 | メッセージ編集                            |
|                       | `commit`     | なし                 | コミット実行                              |
| `/idd-pr`             |              | `[--output=file]`    | PRドラフト生成 (デフォルト: new)          |
|                       | `new`        | `[--output=file]`    | PRドラフト生成                            |
|                       | `view`       | なし                 | ドラフト表示                              |
|                       | `edit`       | なし                 | ドラフト編集                              |
|                       | `review`     | なし                 | ドラフト詳細分析                          |
|                       | `push`       | なし                 | GitHub にPR作成                           |
| `/sdd`                | `init`       | `<namespace/module>` | SDD セッション初期化                      |
|                       | `req`        | なし                 | 要件定義作成                              |
|                       | `spec`       | なし                 | 仕様書生成                                |
|                       | `tasks`      | なし                 | タスク分解                                |
|                       | `coding`     | `[task-group]`       | BDD実装                                   |
|                       | `commit`     | なし                 | 完了作業のコミット                        |
| `/validate-debug`     |              | なし                 | 6段階包括的品質検証・デバッグワークフロー |

#### 3. その他のコマンド

| コマンド  | サブコマンド | 引数                  | 説明                                            |
| --------- | ------------ | --------------------- | ----------------------------------------------- |
| `/serena` |              | `<problem> [options]` | serena-mcp を活用した構造化アプリ開発・問題解決 |

> 注意:
> すべてのコマンドは `/claude-idd-framework:` 接頭辞が必要です。

### 3.3 コマンドの使用例

ここでは、`claude-idd-framework` に含まれる代表的なコマンドの使用例を紹介します。
これらのコマンドはすべて、**Claude Code の対話的な CLI 環境** で実行できます。
各コマンドは GitHub CLI (`gh`) や MCP サーバーと連携し、Issue の作成からブランチ生成、コミット、PR 作成までの一連の開発フローを自動化します。

#### 新しい Issue ドラフトを作成する

```bash
/claude-idd-framework:\idd\issue:new "ユーザー認証の追加"
```

Claude Code が対話形式で質問を開始し、入力内容に基づいて Issue ドラフトを生成します。
生成されたドラフトは、以下のディレクトリに保存されます。

```bash
./temp/idd/issues/new-20251104-230715-feature-user-auth.md
```

#### Issue からブランチを作成する

次のコマンドを実行し、ブランチ名を提案させます。

```bash
/claude-idd-framework:idd:issue:branch new
```

出力例:

```bash
  Branch Proposal

  Issue: ユーザー認証の追加 (Issue #12)
  Current branch: main
  Suggested branch: feat-12/auth/add-user-auth
  Domain: auth
  Base branch: main
```

提案されたブランチでよければ、次のコマンドでブランチを作成します。

```bash
/claude-idd-framework:idd:issue:branch commit
```

## 4. プロジェクト設定

### 4.1 テンプレートのカスタマイズ

claude-idd-framework を実際のプロジェクトで活用するには、プロジェクト固有のテンプレートをカスタマイズすることを推奨します。

#### Issue テンプレートの設定

GitHub Issue のテンプレートは `.github/ISSUE_TEMPLATE/` ディレクトリに配置します。

テンプレートは YAML 形式で記述し、以下の構造を持ちます。

```yaml
name: ✨ Feature Request
description: Suggest a new idea or improvement.
title: "[Feature]"
labels: ["enhancement"]
assignees: ["atsushifx"]

body:
  - type: textarea
    attributes:
      label: 💡 What's the problem you're solving?
      description: Describe the background or problem that led to this request.
      placeholder: "I am always frustrated when I need to..."
```

主なカスタマイズポイント:

- `labels`: プロジェクト固有のラベル名に変更 (例: `["enhancement"]` → `["feature", "priority-high"]`)
- `assignees`: デフォルト担当者をチームメンバーに変更
- `body`: プロジェクトの要件に合わせてフィールドを追加・削除

参考実装として、このリポジトリの `.github/ISSUE_TEMPLATE/` ディレクトリに以下のテンプレートが用意されています。

- `feature_request.yml`: 機能追加リクエスト
- `bug_report.yml`: バグレポート
- `enhancement.yml`: 既存機能の改善
- `task.yml`: タスク管理用

これらをコピーして、プロジェクトのニーズに合わせてカスタマイズしてください。

#### PR テンプレートの設定

Pull Request のテンプレートは `.github/PULL_REQUEST_TEMPLATE.md` に配置します。

テンプレートは Markdown 形式で記述し、以下の構造を持ちます。

```markdown
## ✨ Overview

Briefly explain what this Pull Request changes and why.

---

## 🔧 Changes

List the key changes included in this PR:

- [ ] Added/updated files or modules
- [ ] Removed deprecated logic or configs
- [ ] Refactored for clarity/performance

---

## 📂 Related Issues

Link any issues this PR closes or relates to:

> Closes #123

---

## ✅ Checklist

- [ ] Code follows project coding standards
- [ ] Tests pass locally
- [ ] Documentation is updated (if applicable)
- [ ] PR title follows [Conventional Commits](https://www.conventionalcommits.org/)
```

主なカスタマイズポイント:

- `Changes` セクション: プロジェクト固有のチェック項目を追加
- `Checklist` セクション: コーディング規約や CI/CD 要件を反映
- セクションの追加: セキュリティレビュー、パフォーマンステストなど

参考実装として、このリポジトリの `.github/PULL_REQUEST_TEMPLATE.md` が利用可能です。

### 4.2 動作確認

テンプレート設定後、動作を確認します。

簡単なテストコマンドを実行してください。

```bash
/claude-idd-framework:\idd\issue:new "テスト用 Issue"
```

コマンドが正常に動作し、Issue ドラフト作成の対話が開始されれば、設定は完了です。

生成された Issue ドラフトは `temp/idd/issues/` ディレクトリに保存されます。ファイル名は `new-YYYYMMDD-HHMMSS-[type]-[title].md` 形式です。

## 5. トラブルシューティング

### 5.1 コマンドが表示されない場合

`/help` でコマンドが表示されない場合は、以下を確認してください。

1. Claude Code を再起動
2. プラグインが正しくインストールされているか確認 (`/plugin list`)
3. マーケットプレイスが正しく追加されているか確認

それでも解決しない場合は、プラグインを一度削除して再インストールしてください。

### 5.2 MCP サーバーエラーの対処

MCP サーバー (codex-mcp、serena-mcp、lsmcp) のエラーが発生する場合:

1. Claude Code のログを確認 (エラーメッセージの詳細を確認)
2. プラグインを再インストール
3. 必要に応じて、Claude Code の設定ファイルを初期化

詳細なトラブルシューティングは [基本的なワークフローガイド](03-basic-workflow.md) を参照してください。

### 5.3 テンプレートが反映されない場合

Issue/PR テンプレートが反映されない場合:

1. ファイル名と配置場所を確認 (`.github/ISSUE_TEMPLATE/*.yml`, `.github/PULL_REQUEST_TEMPLATE.md`)
2. YAML 構文エラーがないか確認 (オンライン YAML バリデーターを使用)
3. GitHub にコミット・プッシュ後、ブラウザでリポジトリを確認

テンプレートは GitHub 上でのみ有効化されるため、ローカルでは確認できません。

## 6. 次のステップ

### 6.1 基本的なワークフローの学習

インストールとセットアップが完了したら、[基本的なワークフローガイド](03-basic-workflow.md)で実際の操作方法を学びましょう。

基本的なワークフローガイドでは、Issue 作成、コミットメッセージ生成、Pull Request 作成などの基本操作と、Issue-Driven Development (IDD) や BDD 開発サイクルなどの推奨ワークフローについて詳しく説明しています。

## See Also

より詳細な情報や関連リソースについては、以下を参照してください。

- [クイックスタート](01-quickstart.md)
  5分でプラグインをインストールし、最初のコマンドを実行するための簡易ガイド。

- [基本的な開発ワークフロー](03-basic-workflow.md)
  Issue 作成から PR マージまでの一連の開発フローの詳細説明。

- [Claude Code 公式ドキュメント - Plugins](https://docs.claude.com/ja/docs/claude-code/plugins)
  プラグインの追加・削除方法や、カスタムコマンド、エージェント機能などの公式ガイド。

- [GitHub Issue テンプレート公式ドキュメント](https://docs.github.com/ja/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
  Issue テンプレートの詳細な作成方法と設定オプション。

- [GitHub PR テンプレート公式ドキュメント](https://docs.github.com/ja/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
  Pull Request テンプレートの作成と設定方法。

- [claude-idd-framework GitHub リポジトリ](https://github.com/aglabo/claude-idd-framework)
  プラグインのソースコードや実際のテンプレート実装を確認可能。

## License

Copyright (c) 2025 atsushifx
This software is released under the MIT License.
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)
