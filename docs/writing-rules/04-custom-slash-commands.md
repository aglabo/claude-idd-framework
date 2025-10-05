---
header:
  - src: 04-custom-slash-commands.md
  - @(#): Claude カスタムスラッシュコマンド記述ルール
title: agla-logger
description: Claude Code 向けカスタムスラッシュコマンド記述統一ルール - AI エージェント向けガイド
version: 1.0.0
created: 2025-01-15
authors:
  - atsushifx
changes:
  - 2025-10-03: 実際の /sdd, /idd-issue コマンドに合わせて全面更新 - Bash実装方式への変更
  - 2025-01-15: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

このドキュメントは、Claude Code 向けのカスタムスラッシュコマンドを記述するための統一ルールを定義します。
AI エージェントがコマンド構文を正確に理解し、一貫性のあるコマンドを作成することを目的とします。

## 統合フロントマター仕様

### 基本構成

Claude Code 公式要素と ag-logger プロジェクト要素を統合した統一フロントマター形式を使用します。

#### 標準テンプレート

```yaml
---
# Claude Code 必須要素
allowed-tools: Bash(*), Task(*)
argument-hint: [subcommand] [args]
description: [AI エージェント向けコマンド説明]

# 設定変数 (オプション)
config:
  base_dir: path/to/base
  temp_dir: temp/files
  session_file: .session

# サブコマンド定義 (オプション)
subcommands:
  init: "初期化"
  list: "一覧表示"
  view: "表示"

# ユーザー管理ヘッダー
title: command-name
version: 1.0.0
created: YYYY-MM-DD
authors:
  - atsushifx
changes:
  - YYYY-MM-DD: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

### Claude Code 必須要素

#### allowed-tools フィールド

**目的**: コマンドが使用できるツールのリスト指定。
**形式**: `[tool-name]([pattern])` 形式。

使用例:

- `Bash(*)`: すべての Bash コマンド許可
- `Task(*)`: すべての Task ツール許可
- `Read(*), Write(*)`: ファイル操作ツール許可

#### argument-hint フィールド

**目的**: スラッシュコマンドの引数ヒント表示 (自動補完機能用)。
**形式**: `[subcommand] [args]` 形式。

パターン例:

- `[subcommand] [args]`: 汎用パターン
- `init <namespace>/<module>`: 具体的引数指定
- `add [tagId] | remove [tagId] | list`: 複数選択肢

#### description フィールド

**目的**: AI エージェント向けコマンド説明。
**要件**: 日本語での簡潔な説明文 (50-100 文字程度)。

記述例:

- `Spec-Driven-Development主要コマンド - init/req/spec/task/code サブコマンドで要件定義から実装まで一貫した開発支援`
- `GitHub Issue 作成・管理システム - issue-generatorエージェントによる構造化Issue作成`

### 設定変数セクション (オプション)

#### config フィールド

**目的**: コマンド実行時に使用する設定値の定義。
**形式**: YAML オブジェクト形式。

使用例:

```yaml
config:
  base_dir: docs/.cc-sdd # 基本ディレクトリ
  temp_dir: temp/issues # 一時ファイルディレクトリ
  session_file: .lastSession # セッションファイル名
  subdirs: # サブディレクトリリスト
    - requirements
    - specifications
```

**活用方法**:

- Bash スクリプト内で環境変数として参照
- ファイルパス構築の基準値として使用
- セッション管理のファイル名指定

### サブコマンド定義セクション (オプション)

#### subcommands フィールド

**目的**: コマンドのサブコマンド一覧とその説明の定義。
**形式**: キー: 値のマッピング形式。

使用例:

```yaml
subcommands:
  init: "プロジェクト構造初期化"
  req: "要件定義フェーズ"
  new: "issue-generatorエージェントで新規Issue作成"
  list: "保存済みIssueドラフト一覧表示"
```

**活用方法**:

- ヘルプメッセージの自動生成
- サブコマンドの存在確認
- ドキュメント自動生成

### ユーザー管理ヘッダー

#### 統一要素

- title: コマンド名 (kebab-case)
- version: セマンティックバージョニング形式
- created: 初回作成日 (YYYY-MM-DD 形式)
- authors: 作成者リスト
- changes: 変更履歴
- copyright: MIT ライセンス表記

#### 要素分離ルール

必須: コメント区分により Claude Code 要素とユーザー管理要素を明確に分離。

```yaml
---
# Claude Code 必須要素
[claude-code-elements]

# 設定変数 (オプション)
[config-section]

# サブコマンド定義 (オプション)
[subcommands-section]

# ユーザー管理ヘッダー
[user-management-elements]

copyright:
  [copyright-notice]
---
```

## Bash 実装方式

### 基本実装パターン

カスタムスラッシュコマンドは Bash スクリプト形式で実装します。各サブコマンドは独立したスクリプトブロックとして記述します。

基本構造:

- 環境設定: Git リポジトリルート取得、ベースディレクトリ設定
- 処理実行: サブコマンド固有の処理
- 結果出力: 統一されたメッセージ形式

### 標準実装パターン

#### Pattern 1: 環境設定とセッション管理

Git リポジトリルートを基準にしたパス設定とセッション情報の保存・読み込みを行います。

主要機能:

- 環境変数設定: `REPO_ROOT`, `BASE_DIR`, `SESSION_FILE`
- セッション保存: キー・バリュー形式でファイル保存
- セッション読み込み: 保存されたセッション情報の復元

#### Pattern 2: ディレクトリ構造初期化

プロジェクト構造を一括で作成します。

主要機能:

- 複数サブディレクトリの一括作成
- Git リポジトリルートからの相対パス管理
- 作成結果の視覚的フィードバック

#### Pattern 3: エージェント起動

エージェント起動のための準備処理を行います。

主要機能:

- セッション情報の読み込みと確認
- エージェント起動メッセージの表示
- Claude による Task ツール起動への橋渡し

### Bash 実装の詳細

具体的な Bash スクリプト実装は [コマンド実装例](../writing-examples/command-implementation-examples.md) を参照してください。

提供される実装パターン:

- 環境設定・セッション管理の完全実装
- ディレクトリ構造初期化の実践例
- エージェント起動フローの実装
- GitHub CLI 連携パターン
- /sdd, /idd-issue の統合実装例

### 処理制約・要件

#### 技術制約

- Shell: Bash (Git Bash on Windows 対応)
- 依存関係: Git コマンドのみ必須
- 実行時間: 即座完了 (数秒以内)
- 処理複雑度: シンプルな処理のみ

#### エラーハンドリング

統一されたメッセージ形式を使用します:

- `❌ Error: [具体的なエラー内容]`
- `✅ Success: [成功メッセージ]`
- `✅ Created: [作成されたファイル/ディレクトリ]`
- `💾 Session saved: [セッション情報]`
- `🚀 Launching: [起動内容]`

## コマンド構造標準

### ファイル配置・命名

#### ディレクトリ構造

```bash
.claude/
└── commands/
    ├── [command-name].md
    ├── [command-name-2].md
    └── ...
```

#### 命名規則

**形式**: `[command-name].md`

**要件**:

- 小文字のみ使用
- ハイフン区切り (`command-name`)
- 拡張子は `.md`
- スペース・アンダースコア禁止

**パターン例**:

- `commit-message.md` (action-target)
- `validate-debug.md` (action-target)
- `project-init.md` (target-action)

### ドキュメント構造標準

#### 必須セクション構成

```markdown
---
[Frontmatter]
---

## Quick Reference

[使用方法概要]

## Help Display

'''python
[Help display code]
'''
```

## [Function] Handler

```python
[Implementation code]
```

## Examples

[使用例と期待される出力]。

### セクション階層ルール

- Level 1: `# [Command Name]` (通常省略、ファイル名で代替)
- Level 2: `## [Major Section]`
- Level 3: `### [Sub Section]` (必要時のみ)

#### セクション命名規約

**基本機能セクション**:

- `Help Display`: ヘルプ表示
- `Version Info`: バージョン情報表示
- `Quick Setup`: 初期設定

**処理機能セクション**:

- `[Command] Handler`: 各コマンド処理
- `Initialize [Target]`: 初期化処理
- `Create [Resource]`: リソース作成
- `Update [Configuration]`: 設定更新

**命名ルール**:

- 英語での記述 (Claude 認識確実性)
- 具体的で明確な表現
- 一貫した語順: `[Action] [Object]` または `[Object] [Action]`

## 品質検証ワークフロー

### 検証フェーズ概要

カスタムスラッシュコマンドの品質検証は 3 つのフェーズで構成されます。

#### Phase 1: 基本検証

コマンドファイルの存在確認とフロントマターの検出を行います。

検証項目:

- ファイル存在確認: `.claude/commands/[command-file].md` の存在
- フロントマター検出: ファイルが `---` で始まるか確認

#### Phase 2: フロントマター検証

YAML 構文の正確性と必須フィールドの存在を確認します。

検証項目:

- YAML 構文検証: フロントマター部分の YAML パース
- Claude Code 必須フィールド確認: `allowed-tools`, `argument-hint`, `description`
- プロジェクト必須フィールド確認: `title`, `version`, `created`, `authors`

#### Phase 3: 実装コード検証

Bash スクリプトや Python コードの構文正確性を確認します。

検証項目:

- 構文正確性確認: AST パースによる構文チェック
- 実行可能性テスト: 基本的な実行テスト
- エラーハンドリング確認: エラー処理の妥当性

### 検証実装の詳細

具体的な検証コード実装は [コマンド実装例](../writing-examples/command-implementation-examples.md) を参照してください。

Python による検証スクリプトの例:

- ファイル存在・フロントマター確認
- YAML 構文検証と必須フィールドチェック
- Bash/Python コード構文検証

### 品質基準

#### 検証レポート形式

```bash
=== Quality Validation Report ===
File: [command-file].md
Date: YYYY-MM-DD HH:MM:SS

[✓/✗] Frontmatter Validation
[✓/✗] Structure Validation
[✓/✗] Python Code Validation
[✓/✗] Integration Validation
[✓/✗] Project Compliance Validation

Overall Status: [PASS/FAIL]
Issues Found: [N]
Warnings: [N]
```

#### ag-logger 準拠チェック

- `pnpm run lint:text docs/writing-rules/custom-slash-commands.md` エラー 0 件
- `pnpm run lint:markdown docs/writing-rules/custom-slash-commands.md` エラー 0 件
- Claude Code 公式仕様との完全互換性確保

## 実践的活用例

### 例1: /sdd コマンド

Spec-Driven-Development (SDD) ワークフロー実装例。

主要機能:

- プロジェクト構造初期化 (init)
- 要件定義・設計・タスク分解フェーズ (req/spec/task)
- BDD 実装フェーズ (code)
- セッション管理による状態保持

フロントマター構成:

- allowed-tools: `Bash(*)`, `Read(*)`, `Write(*)`, `Task(*)`
- config セクション: `base_dir`, `session_file`, `subdirs`
- subcommands セクション: 各フェーズの定義

詳細な実装は [コマンド実装例](../writing-examples/command-implementation-examples.md#sdd-コマンド完全実装) を参照してください。

### 例2: /idd-issue コマンド

GitHub Issue 作成・管理システム実装例。

主要機能:

- 新規 Issue 作成 (new)
- Issue ドラフト一覧・表示 (list/view)
- GitHub への Push (push)
- GitHub からの Import (load)

フロントマター構成:

- allowed-tools: `Bash(git:*, gh:*)`, `Read(*)`, `Write(*)`, `Task(*)`
- config セクション: `temp_dir`, `issue_types`
- subcommands セクション: 各操作の定義

詳細な実装は [コマンド実装例](../writing-examples/command-implementation-examples.md#github-cli-連携) を参照してください。

## See Also

### ドキュメント作成ルール

- [カスタムエージェント](05-custom-agents.md): エージェント記述ルール
- [フロントマターガイド](02-frontmatter-guide.md): フロントマター統一ルール
- [執筆ルール](01-writing-rules.md): Claude 向け執筆禁則事項
- [ドキュメントテンプレート](03-document-template.md): 標準テンプレート

### 実装例

- [コマンド実装例](../writing-examples/command-implementation-examples.md): Bash/Python 実装パターン

### プロジェクト開発ルール

- [AI Development Standards](../for-ai-dev-standards/README.md): AI 開発標準ドキュメント

## 注意事項・制約

### 絶対遵守事項

1. **フロントマター統一**: Claude Code 公式要素の厳格遵守
2. **Bash 制約**: 標準コマンドのみ使用、Git 依存、シェル移植性確保
3. **セキュリティ**: 機密情報のコード記述・ログ出力禁止
4. **ファイル配置**: `.claude/commands/` 直下の配置厳守

### 品質保証要件

- textlint・markdownlint 準拠
- Claude Code 自動補完機能との互換性確保
- ag-logger プロジェクト体系との整合性維持
- 実際に動作するサンプルコードの提供

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx

---

このルールは AI エージェントによるコマンド作成の品質・一貫性・実用性確保のため必須遵守。
