---
header:
  - src: 01-setup-and-onboarding.md
  - @(#): AI Development Environment Setup
title: claude-idd-framework
description: AI コーディングエージェント向け開発環境セットアップ・オンボーディング
version: 1.0.0
created: 2025-09-27
authors:
  - atsushifx
changes:
  - 2025-09-27: 初版作成
  - 2025-10-05: claude-idd-framework 用に更新
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## AI 開発環境セットアップ

このドキュメントは AI コーディングエージェントがプロジェクトで開発を開始する際のセットアップとオンボーディング手順を定義します。
効率的で一貫した開発環境の構築を目的とします。

## プロジェクト理解の必須事項

### 基本情報

claude-idd-framework は AI コーディングエージェント (Claude Code) 向けの汎用的な開発フレームワークです。

- プロジェクト: claude-idd-framework
- 目的: AI コーディングエージェント向け統一開発標準の提供
- アーキテクチャ: ドキュメントベース・汎用フレームワーク

### フレームワーク構成

```bash
claude-idd-framework/
├── .claude/                  # Claude Code 拡張機能
│   ├── commands/            # カスタムスラッシュコマンド定義
│   └── agents/              # カスタムエージェント定義
├── docs/
│   ├── writing-rules/       # 汎用執筆ルール・ガイドライン
│   ├── for-AI-dev-standards/ # AI 開発標準 (プロジェクト適用)
│   └── writing-examples/    # 実装例・サンプル
├── configs/                 # 各種ツール設定 (textlint, markdownlint, dprint)
├── scripts/                 # ユーティリティスクリプト
└── temp/                    # 一時ファイル (gitignored)
```

## 必須セットアップ手順

### 1 .プロジェクトのオンボーディング

MCPツールおよび、`Claude`のメモリを最新の状態に更新します。
`Claude`上で、以下のプロンプトを実行:

```bash
lsmcpのメモリを、現在のコードベース/ドキュメントを読んで更新して
serena-mcpのメモリを、現在のコードベース／ドキュメントを読んで更新して
現在のコードベース／ドキュメントをもとにclaudeのメモリを更新して
```

以上で、`claude`および`MCPツール`のメモリが最新の情報に更新されます。

### 1. プロジェクト概要把握

🔴 必須: 開発開始前のプロジェクト理解。

MCP ツールを使用したプロジェクト構造の把握と既存知識の読み込み:

**自然言語プロンプト例**:

- "lsmcp でプロジェクトの概要を確認して"
- "serena-mcp でプロジェクト構造を分析して"
- "プロジェクトのメモリを一覧表示して"
- "重要なメモリを読み込んで"

### 2. ドキュメント理解

claude-idd-framework の主要ドキュメントを確認:

**自然言語プロンプト例**:

- "docs/writing-rules/README.md を読んで執筆ルールを確認して"
- "docs/for-AI-dev-standards/README.md を読んで AI 開発標準を確認して"
- "docs/writing-rules/01-writing-rules.md で禁則事項を確認して"
- "docs/for-AI-dev-standards/02-core-principles.md で核心原則を確認して"

### 3. カスタムツール確認

利用可能なカスタムコマンドとエージェントの確認:

**自然言語プロンプト例**:

- "利用可能なカスタムコマンドを教えて"
- "カスタムエージェントの一覧を表示して"
- ".claude/commands/ のコマンドを確認して"
- ".claude/agents/ のエージェントを確認して"

#### IDD (Issue-Driven Development) ワークフロー

開発の流れに沿ったコマンド群:

1. **Issue 作成**: `/idd-issue [type] "title"` - 開発タスクの Issue 化
2. **実装・コミット**: `commit-message-generator` エージェント - 実装後のコミット
3. **PR 作成**: `/idd-pr` - レビュー用 PR ドラフト生成

#### SDD (Spec-Driven Development) ワークフロー

要件定義から実装までの統合ワークフロー:

1. **初期化**: `/sdd init namespace/module` - プロジェクト構造初期化
2. **要件定義**: `/sdd req` - 要件ドキュメント作成
3. **仕様作成**: `/sdd spec` - 技術仕様書作成
4. **タスク生成**: `/sdd tasks` - 実装タスクリスト生成
5. **実装**: `/sdd coding [task-group]` - タスクベース実装
6. **コミット**: `/sdd commit` - 実装完了後のコミット

#### その他のカスタムツール

- `/validate-debug`: 6 段階品質検証・デバッグ
- `/serena <problem>`: Serena MCP 統合コマンド
- `bdd-coder` エージェント: BDD 厳格プロセス実装

## 開発ルール理解

### 必須ルール確認

🔴 必須: 以下のルールを開発前に確認。

1. **MCP ツール必須使用**: 全開発段階で lsmcp・serena-mcp 活用
2. **執筆ルール遵守**: `docs/writing-rules/` のガイドライン厳守
3. **品質基準遵守**: `docs/for-AI-dev-standards/09-document-quality-assurance.md` の基準遵守
4. **ツール非依存**: 汎用性維持のため特定ツールへの依存を避ける

### 開発フロー理解

claude-idd-framework を使用した開発の基本的な流れ:

```bash
# 基本開発フロー
1. ドキュメント確認 → docs/writing-rules/, docs/for-AI-dev-standards/
2. カスタムツール活用 → .claude/commands/, .claude/agents/
3. MCP ツール活用 → 既存コード理解・パターン分析
4. 品質確認 → 09-document-quality-assurance.md の基準遵守
```

## プロジェクト構造理解

### 主要ディレクトリ

claude-idd-framework のディレクトリ構造と役割:

```bash
claude-idd-framework/
├── .claude/                  # Claude Code 拡張機能
│   ├── commands/            # カスタムスラッシュコマンド定義
│   └── agents/              # カスタムエージェント定義
├── docs/
│   ├── writing-rules/       # 汎用執筆ルール・ガイドライン
│   ├── for-AI-dev-standards/ # AI 開発標準 (プロジェクト適用)
│   └── writing-examples/    # 実装例・サンプル
├── configs/                 # 各種ツール設定 (textlint, markdownlint, dprint)
├── scripts/                 # ユーティリティスクリプト (Git hooks など)
└── temp/                    # 一時ファイル・ドラフト (gitignored)
```

### ディレクトリ役割詳細

#### `.claude/` - Claude Code 拡張機能

- `commands/`: カスタムスラッシュコマンド定義 (IDD/SDD ワークフロー)
- `agents/`: カスタムエージェント定義 (BDD 実装、コミットメッセージ生成など)

#### `docs/` - ドキュメント

- `writing-rules/`: 汎用執筆ルール (他プロジェクトでも使用可能)
- `for-AI-dev-standards/`: AI 開発標準 (プロジェクト固有)
- `writing-examples/`: 実装例・サンプル

#### `configs/` - 各種ツール設定

- `textlint/`: テキスト品質チェック設定
- `markdownlint/`: Markdown 構文チェック設定
- `dprint/`: フォーマット設定

#### `scripts/` - ユーティリティスクリプト

- Git hooks 用スクリプト (prepare-commit-msg.sh など)

#### `temp/` - 一時ファイル

- Issue/PR ドラフト保存場所 (gitignored)
```

### 重要ファイル

開発に必要な主要ドキュメント:

```bash
# プロジェクトルート
CLAUDE.md                 # 総合開発ガイド (プロジェクト固有)
README.md                 # プロジェクト概要

# AI 開発ガイド
docs/for-AI-dev-standards/README.md     # AI 開発標準の索引
docs/writing-rules/README.md            # 執筆ルールの索引
```

## カスタムツール活用

### IDD (Issue-Driven Development) ワークフロー

Issue を起点とした開発フロー:

#### ステップ 1: Issue 作成

```bash
# Feature Request
/idd-issue feature "ユーザー認証機能"

# Bug Report
/idd-issue bug "フォーム送信エラー"

# Enhancement
/idd-issue enhancement "パフォーマンス改善"

# Task
/idd-issue task "ドキュメント更新"
```

または `issue-generator` エージェントで構造化 Issue 作成:

- Feature/Bug/Enhancement/Task の構造化フォーマット
- プロジェクト品質基準に準拠

#### ステップ 2: 実装・コミット

実装後、`commit-message-generator` エージェントでコミット:

```bash
# staged changes から自動生成
git add .
# Task ツールで commit-message-generator エージェント起動
```

または `/idd-commit-message` コマンド:

```bash
/idd-commit-message
/idd-commit-message --lang=en  # 英語メッセージ
```

#### ステップ 3: PR 作成

```bash
# 基本的な使用方法
/idd-pr

# カスタム出力ファイル指定
/idd-pr --output=temp/pr/my-feature.md
```

または `pr-generator` エージェントでコミット履歴分析・テスト計画自動生成

### SDD (Spec-Driven Development) ワークフロー

要件定義から実装までの統合ワークフロー:

#### ステップ 1: 初期化

```bash
/sdd init namespace/module
```

プロジェクト構造と SDD 作業ディレクトリを初期化

#### ステップ 2: 要件定義

```bash
/sdd req
```

要件ドキュメントを作成 (ビジネス要件、機能要件)

#### ステップ 3: 仕様作成

```bash
/sdd spec
```

技術仕様書を作成 (アーキテクチャ、API 設計)

#### ステップ 4: タスク生成

```bash
/sdd tasks
```

実装タスクリストを自動生成

#### ステップ 5: 実装

```bash
/sdd coding [task-group]
```

タスクベースで段階的実装 (BDD ワークフローと統合可能)

#### ステップ 6: コミット

```bash
/sdd commit
```

実装完了後の統合コミット

### その他のカスタムツール

#### `/validate-debug` - 品質検証

6 段階の包括的品質検証ワークフロー:

```bash
/validate-debug
```

#### `/serena` - Serena MCP 統合

```bash
/serena <problem> [options]
```

#### `bdd-coder` エージェント - BDD 実装

Red-Green-Refactor サイクルによる厳格な BDD 実装:

- 使用タイミング: 新機能実装時・テスト駆動開発時
- 特徴: 1 message = 1 test の原則、段階的実装

## MCP ツール基本操作

### プロジェクト理解

プロジェクト全体の構造把握とシンボル検索:

**自然言語プロンプト例**:

- "lsmcp でプロジェクト概要を確認して"
- "serena-mcp でディレクトリ構造を確認して"
- "docs ディレクトリ内で <keyword> を検索して"
- "プロジェクトルートから再帰的にディレクトリ一覧を取得して"

### ドキュメント調査

ドキュメントの詳細確認とパターン検索:

**自然言語プロンプト例**:

- "docs ディレクトリ内で <pattern> パターンを検索して"
- "docs ディレクトリから *.md ファイルを検索して"
- "writing-rules ディレクトリの構造を確認して"
- "特定のドキュメントで <keyword> を含む箇所を検索して"

### メモリ管理

学習した内容の保存と既存メモリの確認:

**自然言語プロンプト例**:

- "プロジェクトのメモリ一覧を表示して"
- "<memory-name> メモリを読み込んで"
- "<memory-name> という名前で <content> をメモリに保存して"
- "学習した内容をメモリに保存して"

## 実践的オンボーディング

### MCP ツール初回オンボーディング

lsmcp と serena-mcp の初回セットアップ手順:

**自然言語プロンプト例**:

- "lsmcp でオンボーディングを実行して"
- "serena-mcp でオンボーディングを実行して"
- "serena-mcp のオンボーディング状態を確認して"
- "プロジェクトのシンボルインデックスを初期化して"

### 初回ドキュメント作成例

初めてドキュメントを作成する際の段階的な作業手順:

**自然言語プロンプト例**:

1. "docs/writing-rules/01-writing-rules.md を読んで執筆ルールを確認して"
2. "docs/writing-rules/03-document-template.md を読んでテンプレートを確認して"
3. "docs/writing-rules/02-frontmatter-guide.md を読んでフロントマターの書き方を確認して"
4. "テンプレートに従って <new-document>.md を作成して"
5. "docs/for-AI-dev-standards/09-document-quality-assurance.md の基準に従って品質をチェックして"

### カスタムツール初回使用例

カスタムコマンド・エージェントの初回使用手順:

```bash
# 1. カスタムコマンド一覧確認
/help

# 2. コミットメッセージ生成テスト
git add <files>
/idd-commit-message

# 3. Issue 作成テスト
/idd-issue feature "テスト機能"

# 4. BDD エージェント使用テスト
# Task tool で bdd-coder エージェントを起動
```

### 品質確認習慣

ドキュメント作成後に必ず実行する品質確認:

```bash
# ドキュメント品質確認
1. 見出し階層確認 (h1→h2→h3)
2. 文章品質確認 (適切な長さ、明確な表現)
3. Markdown 構文確認 (コードブロック言語指定、リスト統一)
4. フロントマター確認 (必須要素、形式遵守)
5. プロジェクト固有ルール確認 (括弧、技術用語、リンク)
```

## トラブルシューティング

### ドキュメント品質問題

ドキュメント品質基準未達時の対応:

```bash
# 1. 品質基準確認
Read docs/for-AI-dev-standards/09-document-quality-assurance.md

# 2. 執筆ルール確認
Read docs/writing-rules/01-writing-rules.md

# 3. 手動チェック項目実施
# 09-document-quality-assurance.md の「手動チェック項目」参照
```

### カスタムツールエラー

カスタムコマンド・エージェントのエラー対応:

```bash
# 1. ヘルプ確認
/<command-name> help

# 2. ドキュメント確認
Read .claude/commands/<command-name>.md
Read .claude/agents/<agent-name>.md

# 3. フロントマター確認
# allowed-tools, argument-hint などの設定確認
```

### MCP ツールエラー

MCP ツールの設定確認とインデックス再構築:

**自然言語プロンプト例**:

- "プロジェクトルートのパスを確認して"
- "lsmcp でシンボルインデックスを再構築して"
- "serena-mcp でオンボーディングを再実行して"
- "MCP ツールの設定を確認して"

## 継続的学習

### プロジェクト知識の蓄積

学習した内容のメモリ保存と既存メモリの確認:

**自然言語プロンプト例**:

- "<memory-name> という名前で学習内容をメモリに保存して"
- "プロジェクトのメモリ一覧を表示して更新を確認して"
- "<memory-name> メモリの内容を確認して"
- "今回学習した内容を適切な名前でメモリに保存して"

### 改善提案

- 効率的だったカスタムツール使用パターンの記録
- 失敗事例からの学習・改善
- 新しいカスタムコマンド・エージェントの提案
- ドキュメント構造・内容の改善提案

---

### See Also

- [02-core-principles.md](02-core-principles.md) - AI 開発核心原則
- [03-mcp-tools-usage.md](03-mcp-tools-usage.md) - MCP ツール完全ガイド
- [../writing-rules/README.md](../writing-rules/README.md) - 執筆ルール索引
- [../writing-rules/04-custom-slash-commands.md](../writing-rules/04-custom-slash-commands.md) - カスタムスラッシュコマンド
- [../writing-rules/05-custom-agents.md](../writing-rules/05-custom-agents.md) - カスタムエージェント

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
