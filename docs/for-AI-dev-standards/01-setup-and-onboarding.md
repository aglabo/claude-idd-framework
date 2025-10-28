---
header:
  - src: 01-setup-and-onboarding.md
  - @(#): AI Development Environment Setup and Onboarding
title: claude-idd-framework
description: AIコーディングエージェント向けプラグイン初回セットアップ・オンボーディングガイド
version: 2.0.0
created: 2025-09-27
authors:
  - atsushifx
changes:
  - 2025-09-27: 初版作成
  - 2025-10-05: claude-idd-framework用に更新
  - 2025-10-28: プラグイン利用者向けに全面改訂、README.md構成に準拠
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## AI開発環境セットアップ・オンボーディング

このドキュメントは、claude-idd-frameworkプラグインを利用するAIコーディングエージェント(Claude Code)向けの初回セットアップガイドです。
プラグインの構成理解と初回起動時の必須手順を明確にし、効率的な開発開始を支援します。

## プラグイン概要

### claude-idd-frameworkとは

claude-idd-frameworkは、AIコーディングエージェント(Claude Code)向けの統一開発標準を提供するプラグインです。
以下の4つの主要コンポーネントで構成されています。

### 提供コンポーネント

#### 1. カスタムスラッシュコマンド

`.claude/commands/` - Claude Codeで直接実行可能なコマンド群

- IDD(Issue-Driven Development)ワークフロー
- SDD(Spec-Driven Development)ワークフロー
- コミットメッセージ生成
- Pull Request生成
- 品質検証

#### 2. 専門エージェント

`.claude/agents/` - 特定タスクに特化した自律エージェント

- bdd-coder: BDD厳格実装(Red-Green-Refactor)
- commit-message-generator: Conventional Commits生成
- issue-generator: GitHub Issue構造化ドラフト作成
- pr-generator: Pull Requestドラフト生成

#### 3. 汎用執筆ルール

`docs/writing-rules/` - 他プロジェクトでも使用可能な執筆ガイドライン

- 禁則事項と表記ルール
- フロントマター規約
- ドキュメントテンプレート
- カスタムツール作成ガイド

#### 4. AI開発標準

`docs/for-AI-dev-standards/` - プロジェクト固有のAI開発ルール(本ディレクトリ)

- MCP必須使用ルール
- BDD開発プロセス
- コーディング規約
- 品質基準

## 前提条件

### 必須環境

このプラグインを使用するには、以下の環境が必要です。

#### Claude Code

- Claude Code(claude.ai/code)で動作すること
- プラグインがインストール済みであること

#### MCPツール

以下のMCPツールが設定済みであること

- serena-mcp: セマンティックコード分析、シンボル検索
- codex-mcp: 自律コーディングエージェント

### 推奨知識

- Markdown記法の基本
- Git操作の基本
- Conventional Commits形式の理解

## プラグイン環境での注意事項

このプラグインは `~/.claude/plugins/marketplaces/claude-idd-framework-marketplace/plugins/claude-idd-framework` にインストールされていますが、ドキュメントファイルには直接アクセスできません。

### ドキュメント内容の確認方法

ドキュメント内容を確認したい場合は、AIに直接質問してください。

AIへの質問例:

- "プロジェクトの禁則事項を教えて"
- "MCP必須使用ルールを説明して"
- "BDDワークフローの手順を教えて"

AIはプラグイン内のドキュメント内容を理解しているため、直接質問することで必要な情報を得られます。

### カスタムツールの使用

スラッシュコマンドとエージェントは通常通り使用できます:

- `/idd:issue:new` - Issue作成
- `/idd-pr` - Pull Request生成
- `/validate-debug` - 品質検証
- `bdd-coder` エージェント - BDD実装支援

詳細は「カスタムツール一覧」セクションを参照してください。

## 初回起動時の必須手順

プラグイン利用開始時に必ず実行すべき手順を示します。

### ステップ1: MCPツールメモリの更新

MCPツールおよびClaudeのメモリを最新の状態に更新します。
以下のプロンプトをClaude Code上で実行してください。

```plaintext
serena-mcpのメモリを、現在のコードベース/ドキュメントを読んで更新して
現在のコードベース/ドキュメントをもとにclaudeのメモリを更新して
```

この手順により、MCPツールとClaudeが現在のプロジェクト構造を正しく認識します。

### ステップ2: プラグイン構成の確認

プラグインが組み込まれているかを確認します。

1. プラグインコマンドを実行:
   ```bash
   /plugin
   ```

2. `Manage plugins`を選択:
   ```bash
   1. Browse and install plugins
   ```

3. `Marketplace`を選択:
   ```bash
   claude-idd-framework-marketplace
   ```

4. `plugin`を確認:
   ```bash
   ❯ ◉ claude-idd-framework
   ```

5. `/plugin`メニューを終了:
   [ESC]キーを入力し、`claude`のCLIウィンドウまで戻る

### ステップ3: 記述ルールの確認

必須: 開発作業開始前に記述ルールを確認してください。

AIに以下を質問してください:

```plaintext
プロジェクトの禁則事項を教えて(writing-rules/01-writing-rules.mdの内容)
MCP必須使用ルールと核心原則を教えて(for-AI-dev-standards/02-core-principles.mdの内容)
```

この確認を怠ると、プロジェクトの品質基準に違反するドキュメントやコードを作成する可能性があります。

## ディレクトリ構成

このプラグインは2つのディレクトリツリーで構成されます。

### 1. プラグインインストール先 (読み取り専用)

プラグインファイルは以下のパスに配置されています:

`~/.claude/plugins/marketplaces/claude-idd-framework-marketplace/plugins/claude-idd-framework/`

```bash
claude-idd-framework/              # プラグインインストール先
├── commands/                      # カスタムスラッシュコマンド定義
│   ├── idd-commit-message.md
│   ├── idd-pr.md
│   ├── sdd.md
│   ├── serena.md
│   ├── validate-debug.md
│   ├── idd/issue/                 # IDD Issueサブコマンド
│   │   ├── new.md                 # Issue作成
│   │   ├── list.md                # Issue一覧・選択
│   │   ├── load.md                # GitHub Issueインポート
│   │   ├── edit.md                # Issue編集
│   │   ├── push.md                # GitHubプッシュ
│   │   └── branch.md              # ブランチ作成
│   ├── _helpers/                  # ヘルパーコマンド
│   └── _libs/                     # 共有ライブラリ
├── agents/                        # カスタムエージェント定義
│   ├── bdd-coder.md
│   ├── commit-message-generator.md
│   ├── issue-generator.md
│   └── pr-generator.md
└── docs/                          # ドキュメント
    ├── writing-rules/             # 汎用執筆ルール
    │   ├── 01-writing-rules.md
    │   ├── 02-frontmatter-guide.md
    │   ├── 03-document-template.md
    │   ├── 04-custom-slash-commands.md
    │   └── 05-custom-agents.md
    └── for-AI-dev-standards/      # AI開発標準
        ├── 01-setup-and-onboarding.md (本ドキュメント)
        ├── 02-core-principles.md
        ├── ... (以下、12まで)
        └── 12-shell-script-development.md
```

#### プラグインディレクトリの役割

##### `commands/` - カスタムスラッシュコマンド

Claude Codeで `/コマンド名` 形式で直接実行できるコマンド群です。

- トップレベルコマンド: `/idd-commit-message`, `/idd-pr`, `/sdd`, `/validate-debug`
- サブコマンド: `/idd:issue:new`, `/idd:issue:branch` など階層的なコマンド
- ヘルパー: `_helpers/` 内の内部使用コマンド
- ライブラリ: `_libs/` 内のシェルスクリプトライブラリ

##### `agents/` - 専門エージェント

Taskツールで起動する自律エージェントです。

- 特定タスクに特化した実装パターン
- 複数ステップの自動実行
- プロジェクト品質基準への準拠保証

##### `docs/writing-rules/` - 汎用執筆ルール

プロジェクト非依存の執筆ガイドラインです。

- 他のプロジェクトでも使用可能
- Markdown文書の品質基準
- カスタムツール作成方法

##### `docs/for-AI-dev-standards/` - AI開発標準

このプラグインを使用するプロジェクト固有の開発ルールです。

- MCP必須使用ルール
- BDD開発プロセス
- プロジェクト固有のコーディング規約

### 2. プロジェクトルート (作業ディレクトリ)

カスタムコマンド実行時に、プロジェクトルートに以下のディレクトリが作成されます:

```bash
(プロジェクトルート)/             # ユーザーの作業ディレクトリ
├── docs/
│   └── .cc-sdd/                  # SDD(Spec-Driven Development)作業ディレクトリ
│       └── [namespace]/[module]/
│           ├── requirements/     # 要件定義
│           ├── specs/            # 技術仕様書
│           └── tasks/            # タスクリスト
└── temp/                         # 一時ファイル(gitignored)
    └── idd/                      # IDD(Issue-Driven Development)作業ディレクトリ
        ├── issues/               # Issueドラフト
        │   └── *.md              # Issue Markdown files
        └── pr/                   # PRドラフト
            └── *.md              # PR Markdown files
```

#### プロジェクトルートディレクトリの役割

##### `docs/.cc-sdd/` - SDD作業ディレクトリ

`/sdd` コマンド実行時に作成されるSpec-Driven Development用ディレクトリです。

- `requirements/`: 機能要件・非機能要件ドキュメント
- `specs/`: 技術仕様書・設計ドキュメント
- `tasks/`: タスクリスト・実装進捗管理

##### `temp/idd/` - IDD作業ディレクトリ

`/idd:issue:*` コマンド実行時に作成されるIssue-Driven Development用ディレクトリです。

- `issues/`: Issueドラフト(Markdown形式)
- `pr/`: Pull Requestドラフト(Markdown形式)
- gitignore対象(バージョン管理されない)

## for-AI-dev-standards 全体像

このディレクトリ(docs/for-AI-dev-standards/)は12のドキュメントで構成されています。
README.mdの構成に準拠した4つのカテゴリに分類されます。

### カテゴリ1: 環境準備・基本原則

#### 01. AI開発環境セットアップ・オンボーディング(本ドキュメント)

- 初回起動時の必須手順
- プラグイン構成の理解
- 全体像の把握

#### 02. AI開発の核心原則・MCP必須ルール

- MCP必須使用の理由
- トークン効率化の原則
- 品質第一主義

### カテゴリ2: ツール活用

#### 03. MCPツール完全活用ガイド

- serena-mcp使用方法
- codex-mcp使用方法
- メモリ管理

#### 04. プロジェクトナビゲーション・コード検索

- プロジェクト構造理解
- シンボル検索
- パターン検索

### カテゴリ3: 開発プロセス

#### 05. BDD開発フロー・Red-Green-Refactorサイクル

- BDDサイクルの実践
- 1 message = 1 testの原則
- RED-GREEN-REFACTORの厳格遵守

#### 06. コーディング規約・MCP活用パターン

- コーディングスタイル
- MCP活用パターン
- ベストプラクティス

#### 07. テスト実装・BDD階層構造

- Given/When/Then構造
- タグ付けルール([正常], [異常], [エッジケース])
- テスト命名規則

### カテゴリ4: 品質保証・高度なガイド

#### 08. AI用品質ゲート・自動チェック

- コード品質ゲート
- 自動チェック項目
- 品質基準

#### 09. ドキュメント品質チェック

- ドキュメント品質基準
- 手動チェック項目
- 品質確認手順

#### 10. ソースコードテンプレート・JSDocルール

- ソースコードテンプレート
- JSDoc記法
- コメント規約

#### 11. atsushifx式BDD実装ガイド詳細

- atsushifx式BDDの詳細
- 実装パターン
- アンチパターン

#### 12. シェルスクリプト開発

- shellspecによるBDD
- シェルスクリプト規約
- テスト戦略

## カスタムツール一覧

### IDD(Issue-Driven Development)コマンド群

Issue起点の開発ワークフローを支援するコマンドです。

#### Issue管理サブコマンド

- `/idd:issue:new [title]` - 新規Issue作成(AI要約生成付き)
- `/idd:issue:list` - Issueドラフト一覧表示・選択
- `/idd:issue:load <issue_number>` - GitHub Issueインポート
- `/idd:issue:edit` - Issueドラフト編集(codex-mcp統合)
- `/idd:issue:push [issue-number]` - GitHubへプッシュ
- `/idd:issue:branch new [--domain domain] [--base branch]` - ブランチ提案生成
- `/idd:issue:branch commit` - ブランチ作成・切り替え

#### その他IDDコマンド

- `/idd-commit-message [--lang=ja|en]` - Conventional Commits生成
- `/idd-pr [--output=file]` - Pull Requestドラフト生成

### SDD(Spec-Driven Development)ワークフロー

要件定義から実装までの統合ワークフローです。

- `/sdd init <namespace>/<module>` - プロジェクト構造初期化
- `/sdd req` - 要件ドキュメント作成
- `/sdd spec` - 技術仕様書作成
- `/sdd tasks` - 実装タスクリスト生成
- `/sdd coding [task-group]` - タスクベース実装
- `/sdd commit` - 実装完了後のコミット

### その他のコマンド

- `/validate-debug` - 6段階包括的品質検証ワークフロー
- `/serena <problem> [options]` - serena-mcp統合コマンド

### 専門エージェント

Taskツールで起動する自律エージェントです。

#### bdd-coder

- 用途: BDD厳格実装(Red-Green-Refactor)
- 特徴: 1 message = 1 testの原則、段階的実装
- 起動: Taskツールで `subagent_type="bdd-coder"` 指定

#### commit-message-generator

- 用途: Conventional Commits形式のコミットメッセージ生成
- 特徴: staged changes分析、プロジェクト慣例分析
- 起動: Taskツールで `subagent_type="commit-message-generator"` 指定

#### issue-generator

- 用途: GitHub Issue構造化ドラフト作成
- 特徴: Feature/Bug/Enhancement/Task対応、AI型判定
- 起動: Taskツールで `subagent_type="issue-generator"` 指定

#### pr-generator

- 用途: Pull Requestドラフト生成
- 特徴: コミット履歴分析、テスト計画自動生成
- 起動: Taskツールで `subagent_type="pr-generator"` 指定

## 記述ルールの理解

必須: 開発作業開始前に必ず確認してください。

### 禁則事項

以下のパターンは使用禁止です。

#### 太字箇条書き

```markdown
<!-- 禁止 -->

- **項目1**: 説明文
- **項目2**: 説明文

<!-- 正しい書き方 -->

### 項目1

説明文

### 項目2

説明文
```

#### 全角括弧

```markdown
<!-- 禁止 -->

機能（feature）を実装

<!-- 正しい書き方 -->

機能(feature)を実装
```

#### 絵文字

```markdown
<!-- 禁止 -->

🔴 必須事項

<!-- 正しい書き方 -->

### 必須事項
```

### フロントマター必須

全てのMarkdownファイルには、以下のフロントマターが必要です。

```yaml
---
header:
  - src: [filename]
  - @(#): [brief description]
title: claude-idd-framework
description: [document purpose]
version: 1.0.0
created: YYYY-MM-DD
authors:
  - atsushifx
changes:
  - YYYY-MM-DD: [change description]
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

### 見出し階層ルール

見出しは階層を飛ばさず、順番に使用してください。

```markdown
<!-- 禁止 -->

# 見出し1

### 見出し3 (h2を飛ばしている)

<!-- 正しい書き方 -->

# 見出し1

## 見出し2

### 見出し3
```

### 詳細情報

完全な記述ルールについては、AIに以下を質問してください:

- 禁則事項詳細: "writing-rules/01-writing-rules.mdの内容を教えて"
- フロントマター規約: "writing-rules/02-frontmatter-guide.mdの内容を教えて"
- ドキュメント品質基準: "for-AI-dev-standards/09-document-quality-assurance.mdの内容を教えて"

(参考: [writing-rules/01-writing-rules.md](../writing-rules/01-writing-rules.md), [writing-rules/02-frontmatter-guide.md](../writing-rules/02-frontmatter-guide.md), [for-AI-dev-standards/09-document-quality-assurance.md](09-document-quality-assurance.md))

## MCP連携の基本

このプラグインは、MCPツール(serena-mcp, codex-mcp)との連携を前提としています。

### serena-mcp

セマンティックコード分析とシンボル検索を提供します。

#### 主要機能

- `find_symbol`: シンボル名からコード検索
- `search_for_pattern`: 正規表現パターン検索
- `get_symbols_overview`: ファイルのシンボル概要取得
- `write_memory`, `read_memory`: プロジェクト知識の保存・読み込み

#### 使用例

```plaintext
serena-mcpを使って、docsディレクトリ内で「MCP」パターンを検索して
serena-mcpでプロジェクトメモリ一覧を表示して
```

### codex-mcp

複雑なタスクを自律的に実行するコーディングエージェントです。

#### 主要機能

- 複数ステップのタスク自動実行
- コードベース分析と実装
- テスト駆動開発支援

#### 使用例

```plaintext
codex-mcpを使って、Issueの要約を生成して編集して
```

### 詳細情報

MCP連携の詳細については、AIに以下を質問してください:

- MCP必須使用の理由: "for-AI-dev-standards/02-core-principles.mdの内容を教えて"
- MCP完全活用ガイド: "for-AI-dev-standards/03-mcp-tools-usage.mdの内容を教えて"

(参考: [02-core-principles.md](02-core-principles.md), [03-mcp-tools-usage.md](03-mcp-tools-usage.md))

## 次のステップ

初回セットアップ完了後、以下の順序でドキュメントを読み進めてください。

### 開発開始前

#### ステップ1: 核心原則の理解

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/02-core-principles.mdの内容を教えて
```

確認すべき内容:

- MCP必須使用ルール
- トークン効率化の原則
- 品質第一主義

#### ステップ2: MCPツール使用法の習得

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/03-mcp-tools-usage.mdの内容を教えて
```

確認すべき内容:

- serena-mcp完全ガイド
- codex-mcp完全ガイド
- メモリ管理方法

#### ステップ3: プロジェクトナビゲーション

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/04-code-navigation.mdの内容を教えて
```

確認すべき内容:

- プロジェクト構造理解
- コード検索方法

### 実装時

#### BDD開発フロー

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/05-bdd-workflow.mdの内容を教えて
for-AI-dev-standards/11-bdd-implementation-details.mdの内容を教えて
```

確認すべき内容:

- Red-Green-Refactorサイクル
- atsushifx式BDD詳細

#### コーディング規約

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/06-coding-conventions.mdの内容を教えて
```

確認すべき内容:

- コーディングスタイル
- MCP活用パターン

#### テスト実装

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/07-test-implementation.mdの内容を教えて
```

確認すべき内容:

- Given/When/Then構造
- テスト命名規則

### 品質確認時

#### コード品質

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/08-quality-assurance.mdの内容を教えて
```

確認すべき内容:

- 品質ゲート実行
- 自動チェック

#### ドキュメント品質

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/09-document-quality-assurance.mdの内容を教えて
```

確認すべき内容:

- ドキュメント品質基準
- 手動チェック項目

## 実践例

### 初回ドキュメント作成

初めてドキュメントを作成する際の手順を示します。

#### ステップ1: 記述ルール確認

AIに以下を質問してください:

```plaintext
writing-rules/01-writing-rules.mdの禁則事項を教えて
```

禁則パターン(太字箇条書き、半角括弧、絵文字など)を理解します。

#### ステップ2: テンプレート確認

AIに以下を質問してください:

```plaintext
writing-rules/03-document-template.mdのテンプレートを教えて
```

ドキュメント構造とフロントマターの書き方を理解します。

#### ステップ3: フロントマター準備

AIに以下を質問してください:

```plaintext
writing-rules/02-frontmatter-guide.mdの内容を教えて
```

必須フィールドを理解し、適切な値を設定します。

#### ステップ4: ドキュメント作成

テンプレートに従ってドキュメントを作成します。

#### ステップ5: 品質確認

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/09-document-quality-assurance.mdの品質基準を教えて
```

その基準に従って以下を確認:

- 見出し階層(h1→h2→h3)
- 文章品質(適切な長さ、明確な表現)
- Markdown構文(コードブロック言語指定、リスト統一)
- フロントマター(必須要素、形式遵守)
- プロジェクト固有ルール(括弧、技術用語、リンク)

### IDD Issueワークフロー

Issue作成からブランチ作成までの完全なワークフローを示します。

#### ステップ1: Issue作成

```bash
/idd:issue:new
```

タイトルを入力すると、AI要約が自動生成されます。
型判定(feature/bug/enhancement/task)も自動で行われます。

出力例: `temp/idd/issues/new-20251028-120000-feature-user-login.md`

#### ステップ2: Issue編集(オプション)

```bash
/idd:issue:edit
```

codex-mcpを使用した対話的編集が可能です。

#### ステップ3: GitHubへプッシュ

```bash
/idd:issue:push
```

GitHub Issue #42として作成されると、ファイル名が更新されます。
更新例: `42-20251028-120000-feature-user-login.md`

#### ステップ4: ブランチ提案生成

```bash
/idd:issue:branch new
```

タイトルからドメインを自動検出し、ブランチ名を提案します。
提案例: `feat-42/auth/user-login`

オプション:

- `--domain <domain>`: ドメインを手動指定
- `--base <branch>`: ベースブランチを指定(デフォルト: main/master)

#### ステップ5: ブランチ作成・切り替え

```bash
/idd:issue:branch commit
```

提案されたブランチを作成し、切り替えます。
これで実装準備が完了します。

## トラブルシューティング

### MCPツールエラー

#### 症状

- serena-mcpが応答しない
- メモリが読み込めない
- シンボル検索が失敗する

#### 対処方法

##### プロジェクトルート確認

```plaintext
プロジェクトルートのパスを確認して
```

正しいディレクトリで作業していることを確認します。

##### オンボーディング再実行

```plaintext
serena-mcpでオンボーディングを再実行して
```

プロジェクトのシンボルインデックスを再構築します。

##### メモリ再読み込み

```plaintext
serena-mcpのメモリを、現在のコードベース/ドキュメントを読んで更新して
```

最新の状態にメモリを更新します。

### カスタムツールエラー

#### 症状

- コマンドが見つからない
- エージェントが起動しない
- 予期しないエラーが発生する

#### 対処方法

##### ヘルプ確認

```bash
/<command-name> help
```

コマンドの使用方法を確認します。

##### ドキュメント確認

AIに以下を質問してください:

```plaintext
コマンド <command-name> の使い方を教えて
エージェント <agent-name> の使い方を教えて
```

正しい使用方法とパラメータを確認します。

##### フロントマター確認

コマンド定義ファイルの以下を確認:

- `allowed-tools`: 使用可能なツール
- `argument-hint`: 引数の形式
- `description`: コマンドの説明

### ドキュメント品質問題

#### 症状

- 品質基準を満たさない
- 禁則パターンを使用している
- フロントマターが不正

#### 対処方法

##### 品質基準確認

AIに以下を質問してください:

```plaintext
for-AI-dev-standards/09-document-quality-assurance.mdの品質基準を教えて
```

ドキュメント品質基準を確認します。

##### 執筆ルール確認

AIに以下を質問してください:

```plaintext
writing-rules/01-writing-rules.mdの禁則事項を教えて
```

禁則パターンを再確認します。

##### 手動チェック実施

09-document-quality-assurance.mdの「手動チェック項目」に従い、以下を確認:

1. 見出し階層確認(h1→h2→h3)
2. 文章品質確認(適切な長さ、明確な表現)
3. Markdown構文確認(コードブロック言語指定、リスト統一)
4. フロントマター確認(必須要素、形式遵守)
5. プロジェクト固有ルール確認(括弧、技術用語、リンク)

---

## See Also

**注記**: プラグイン環境ではドキュメントファイルに直接アクセスできません。以下のリンクは参照用です。ドキュメント内容を確認したい場合は、AIに質問してください。

例: "for-AI-dev-standards/02-core-principles.mdの内容を教えて"

### 環境準備・基本原則

- [02-core-principles.md](02-core-principles.md) - AI開発核心原則・MCP必須ルール

### ツール活用

- [03-mcp-tools-usage.md](03-mcp-tools-usage.md) - MCPツール完全活用ガイド
- [04-code-navigation.md](04-code-navigation.md) - プロジェクトナビゲーション・コード検索

### 開発プロセス

- [05-bdd-workflow.md](05-bdd-workflow.md) - BDD開発フロー・Red-Green-Refactorサイクル
- [11-bdd-implementation-details.md](11-bdd-implementation-details.md) - atsushifx式BDD実装ガイド詳細

### 品質保証

- [09-document-quality-assurance.md](09-document-quality-assurance.md) - ドキュメント品質チェック

### 汎用執筆ルール

- [../writing-rules/README.md](../writing-rules/README.md) - 執筆ルール索引
- [../writing-rules/01-writing-rules.md](../writing-rules/01-writing-rules.md) - 禁則事項と表記ルール
- [../writing-rules/04-custom-slash-commands.md](../writing-rules/04-custom-slash-commands.md) - カスタムスラッシュコマンド作成ガイド
- [../writing-rules/05-custom-agents.md](../writing-rules/05-custom-agents.md) - カスタムエージェント作成ガイド

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
