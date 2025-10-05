---
header:
  - src: README.md
  - @(#): Writing Examples Directory
title: agla-logger
description: ドキュメント作成ルールの具体的実装例・サンプルコード集
version: 1.0.0
created: 2025-10-05
authors:
  - atsushifx
changes:
  - 2025-10-05: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## Writing Examples ディレクトリ

このディレクトリは、docs/writing-rules/ で定義されたドキュメント作成ルールの具体的な実装例とサンプルコードを集約しています。
ルールドキュメントは簡潔な説明に留め、詳細な実装例はこのディレクトリで提供することで、保守性と可読性を向上させます。

## ディレクトリの目的

### 設計思想

- ルールと実装の分離: writing-rules/ はルール定義、writing-examples/ は実装例
- 具体性の提供: 実際に動作するコード例を Markdown 内に埋め込み
- 参照性の向上: ルールドキュメントから examples への明確なリンク

### 対象読者

- Claude Code を使用してドキュメントを作成する AI エージェント
- カスタムエージェント・スラッシュコマンドを実装する開発者
- プロジェクト固有の検証ツールを作成する開発者

## ファイル一覧

### エージェント関連

- [agent-validation-examples.md](agent-validation-examples.md): カスタムエージェント検証実装例
  - Python によるフロントマター検証
  - ファイル存在確認・名前一致チェック
  - ag-logger 固有制約の検証

### コマンド関連

- [command-implementation-examples.md](command-implementation-examples.md): カスタムスラッシュコマンド実装例
  - Bash 環境設定・セッション管理パターン
  - Bash ディレクトリ管理パターン
  - Python フロントマター検証
  - 実践的コマンド実装 (/sdd, /idd-issue)

## 使用方法

### 1. ルールドキュメントから参照

writing-rules/ のドキュメントには、対応する examples へのリンクが記載されています。

```markdown
詳細な実装例は [エージェント検証実装例](../writing-examples/agent-validation-examples.md) を参照してください。
```text

### 2. 直接参照

具体的な実装方法を知りたい場合は、このディレクトリのファイルを直接参照できます。

### 3. コードの再利用

各 examples ファイルに記載されたコードは、プロジェクト固有のツール作成時にそのまま利用または改変可能です。

## ファイル構造標準

### 基本構成

各 examples ファイルは以下の構造に従います:

```markdown
---
[フロントマター]
---

## [機能名] 実装例

[機能の目的と概要説明]

### [パターン1名]

[パターンの説明]

```[language]
[サンプルコード]
```text

実行方法:
[実行手順]

期待される出力:
[出力例]

### [パターン2名]

...

```text

### セクション構成

- 機能概要: 実装例の目的と対象
- パターン別実装: 具体的なコード例
- 実行方法: コードの使用手順
- 期待される出力: 実行結果例
- 注意事項: 制約・前提条件

## 関連ドキュメント

### ルールドキュメント

- [カスタムエージェント](../writing-rules/custom-agents.md): エージェント記述ルール
- [カスタムスラッシュコマンド](../writing-rules/custom-slash-commands.md): スラッシュコマンド記述ルール
- [執筆ルール](../writing-rules/writing-rules.md): Claude 向け執筆禁則事項
- [ドキュメントテンプレート](../writing-rules/document-template.md): 標準テンプレート

### プロジェクトルール

- [開発ワークフロー](../rules/01-development-workflow.md): BDD 開発プロセス
- [品質保証システム](../rules/03-quality-assurance.md): 多層品質保証

## 品質基準

### コード品質

- 実際に動作するコード例のみ掲載
- 言語標準ライブラリのみ使用 (外部依存最小化)
- コメント付きで理解しやすいコード

### ドキュメント品質

- textlint 準拠: エラー 0 件必須
- markdownlint 準拠: 統一された形式
- プロジェクト統一: `@(#)` 記法・MIT ライセンス

## 注意事項

### 使用制約

- サンプルコードは説明目的のため、本番環境での使用前に適切なテスト・検証を実施してください
- プロジェクト固有の設定 (パス、ファイル名など) は環境に応じて調整が必要です

### セキュリティ

- 機密情報 (API キー、パスワード) のコード記述禁止
- サンプルコードでのログ出力時も機密情報を含めない

---

## See Also

- [Writing Rules](../writing-rules/README.md): ドキュメント作成ルール全体概要
- [AI Development Standards](../for-ai-dev-standards/README.md): AI 開発標準ドキュメント

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
