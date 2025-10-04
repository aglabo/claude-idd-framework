# ag-logger モノレポ開発ガイド

このファイルは、Claude Code (claude.ai/code) が ag-logger モノレポでの作業時に参照する総合ガイドです。

## 目次・ドキュメント構成

すべての詳細情報は目的別に整理された 2 つのディレクトリに分類されています。

### プロジェクト関連ドキュメント (`docs/projects/`)

- [00-project-overview.md](docs/projects/00-project-overview.md): プロジェクト全体概要・パッケージ構造
- [01-architecture.md](docs/projects/01-architecture.md): 技術アーキテクチャ・設計パターン
- [02-roadmap.md](docs/projects/02-roadmap.md): プロジェクトロードマップ・未了タスク
- [03-plugin-system.md](docs/projects/03-plugin-system.md): プラグインシステム詳細ガイド
- [04-type-system.md](docs/projects/04-type-system.md): TypeScript 型システムリファレンス
- [05-symbol-navigation.md](docs/projects/05-symbol-navigation.md): シンボルマップ・コードナビゲーション
- [06-utility-functions.md](docs/projects/06-utility-functions.md): ユーティリティ関数カタログ
- [07-command-reference.md](docs/projects/07-command-reference.md): 開発コマンド完全リファレンス

### 開発ルール・ガイドライン (`docs/rules/`)

- [01-development-workflow.md](docs/rules/01-development-workflow.md): BDD 開発フロー・実装手順
- [02-coding-conventions.md](docs/rules/02-coding-conventions.md): コーディング規約・ベストプラクティス
- [03-quality-assurance.md](docs/rules/03-quality-assurance.md): 多層品質保証システム
- [04-mcp-tools-mandatory.md](docs/rules/04-mcp-tools-mandatory.md): 🔴必須 MCP ツール使用要件
- [05-code-navigation-commands.md](docs/rules/05-code-navigation-commands.md): コードナビゲーション・MCP コマンド
- [06-source-code-template.md](docs/rules/06-source-code-template.md): ソースコードテンプレート統一ルール
- [07-bdd-test-hierarchy.md](docs/rules/07-bdd-test-hierarchy.md): BDD 階層構造統一ルール
- [08-jsdoc-describe-blocks.md](docs/rules/08-jsdoc-describe-blocks.md): JSDoc describe ブロック統一ルール
- [09-todo-task-management.md](docs/rules/09-todo-task-management.md): タスク管理統一ルール

## クイックスタート

### 最重要情報 (開発開始前必読)

1. [MCPツール必須使用](docs/rules/04-mcp-tools-mandatory.md) 🔴
   - すべての開発作業で lsmcp・serena-mcp の使用が必須
   - コード理解・実装・テスト・デバッグの全段階で活用

2. [BDD開発プロセス](docs/rules/01-development-workflow.md)
   - Red-Green-Refactor サイクルの厳格遵守
   - 1 message = 1 test の原則

3. [品質ゲート](docs/rules/03-quality-assurance.md)
   - コミット前の必須チェック 5 項目
   - lefthook による自動品質保証

### 必須コマンドセット

```bash
# 型チェック (最優先)
pnpm run check:types

# 4層テストシステム
pnpm run test:develop      # Unit tests (27ファイル)
pnpm run test:functional   # Functional tests (4ファイル)
pnpm run test:ci           # Integration tests (14ファイル)
pnpm run test:e2e          # E2E tests (8ファイル)

# コード品質
pnpm run lint:all

# フォーマット
pnpm run check:dprint

# ビルド確認
pnpm run build
```

## プロジェクト概要 (要約)

### 基本情報

- プロジェクト: ag-logger - TypeScript 用軽量・プラガブルロガー
- アーキテクチャ: pnpm ワークスペース使用のモノレポ
- 現在フォーカス: AglaError フレームワークへの移行

### パッケージ構成

```bash
packages/
└── @aglabo/             # メインパッケージ群
    ├── agla-logger-core/     # 構造化ロガーパッケージ
    └── agla-error-core/      # エラーハンドリングフレームワーク
```

### 技術スタック

- ESM-first + CommonJS 互換性
- デュアルビルド: `lib/` (CJS), `module/` (ESM)
- TypeScript 厳格モード + 包括的型定義
- 4層テスト戦略: Unit/Functional/Integration/E2E

## 重要な開発ルール

### ファイル編集制限

<!-- textlint-disable ja-technical-writing/max-comma -->

- 編集禁止: `lib/`, `module/`, `maps/`, `.cache/`, `node_modules/`
- 編集対象: `src/`, `configs/`, `__tests__/`, `tests/`

<!-- textlint-enable -->

### セキュリティ必須事項

- 機密情報 (API キー・パスワード) のコード記述禁止
- 機密情報のログ出力禁止
- secretlint・gitleaks による自動検出

### 文書作成ルール

<!-- markdownlint-disable line-length -->
<!-- textlint-disable ja-technical-writing/sentence-length -->

ドキュメントを新規作成または更新する前に、必ず `docs/writing/README.md`, `docs/writing/writing-rules.md`, `docs/writing/document-template.md`, `docs/writing/frontmatter-guide.md` を精読し、記載された禁則事項とテンプレートを厳守する。

- 括弧は半角使用: 日本語文書内でも括弧は半角 `()` を使用する
- 括弧前のスペース: 日本語文章内で括弧を使用する際は括弧の前に半角スペースを入れる
- 箇条書きの形式: `**項目名**:` ではなく `項目名:` の形式を使用する
- 絵文字使用制限: 必要最低限の使用に留める (重要度表示 🔴、状態表示のみ)
- 例: `特殊ロガー (フィルタリング無視)`, `項目名: 説明内容`

<!-- textlint-enable -->
<!-- markdownlint-enable -->

### MCPツール必須活用

- 🔴 **必須**: すべての開発段階で MCP ツール使用
- 🔴 **必須**: コード理解・パターン調査・影響範囲確認
- 🔴 **必須**: 実装前の既存パターン研究

## 現在の状況・優先事項

### 最高優先度 (Critical)

1. AglaError 型システム完成: 型安全性・整合性向上
2. テスト最適化: 実行時間短縮・カバレッジ向上

### 完了済み主要マイルストーン ✅

- AglaError 基本実装完了 (@aglabo/agla-error-core v0.1.0)
- 4 層テストアーキテクチャ確立 (53 テストファイル)
- ドキュメント体系化完了 (13 ファイル作成)
- 品質保証システム確立 (lefthook + 5 項目チェック)
- パッケージ構造の最適化 (@aglabo 統一: agla-logger-core, agla-error-core)

## 詳細情報へのアクセス

各トピックの詳細は対応するドキュメントファイルを参照してください。

### プロジェクト理解・概要

- プロジェクト全体を理解したい → [プロジェクト概要](docs/projects/00-project-overview.md)
- 技術アーキテクチャを知りたい → [アーキテクチャ](docs/projects/01-architecture.md)
- タスク・ロードマップを確認したい → [プロジェクトロードマップ](docs/projects/02-roadmap.md)
- コマンドを確認したい → [コマンドリファレンス](docs/projects/07-command-reference.md)

### 高度な機能・技術情報

- プラグインシステムを使いたい → [プラグインシステム](docs/projects/03-plugin-system.md)
- 型システムを理解したい → [型システムリファレンス](docs/projects/04-type-system.md)
- 効率的にナビゲートしたい → [シンボルナビゲーション](docs/projects/05-symbol-navigation.md)
- ユーティリティ関数を知りたい → [ユーティリティ関数](docs/projects/06-utility-functions.md)

### 開発ルール・ガイドライン

- 開発を始める前 → [MCPツール必須要件](docs/rules/04-mcp-tools-mandatory.md)
- 実装を始める → [開発ワークフロー](docs/rules/01-development-workflow.md)
- コード規約を確認したい → [コーディング規約](docs/rules/02-coding-conventions.md)
- 品質を確保したい → [品質保証システム](docs/rules/03-quality-assurance.md)
- ソースコードテンプレートを確認したい → [ソースコードテンプレート](docs/rules/06-source-code-template.md)
- BDD テストルールを確認したい → [BDD階層構造ルール](docs/rules/07-bdd-test-hierarchy.md)
- JSDoc ルールを確認したい → [JSDoc describeブロックルール](docs/rules/08-jsdoc-describe-blocks.md)
- タスク管理ルールを確認したい → [タスク管理統一ルール](docs/rules/09-todo-task-management.md)

---

開発成功の鍵: MCP ツールの活用 + 体系化されたドキュメントの参照 + 品質ゲートの遵守。
