---
header:
  - src: README.md
  - @(#): Documentation Writing Guidelines
title: agla-logger
description: ドキュメント作成・執筆ガイドライン集約ディレクトリ
version: 1.0.0
created: 2025-09-19
authors:
  - atsushifx
changes:
  - 2025-09-19: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

## ドキュメント作成ガイドライン

このディレクトリは agla-logger プロジェクトのドキュメント作成で使用するガイドライン・ルール・テンプレートを集約しています。
統一された品質基準により、プロジェクト全体のドキュメント品質を保証します。

### 必要要件

- 基本知識: Markdown 記法・YAML フロントマター
- プロジェクト品質基準: 統一されたスタイル・形式遵守

### ガイドライン一覧

#### 1. 執筆ルール (基本)

[執筆ルール](01-writing-rules.md) に従って、文章を記述します。

- 箇条書き+強調表現の禁止
- 括弧は半角使用
- あいまいな書き方の禁止

#### 2. フロントマターガイド

[フロントマターガイド](02-frontmatter-guide.md) では以下を説明します。

- `@(#)` 記法の詳細説明
- description・title の記入例
- プロジェクト固有ルール

#### 3. ドキュメントテンプレート

[ドキュメントテンプレート](03-document-template.md) では以下を提供します。

- 統一フォーマット・基本構造
- フロントマター・メインコンテンツ形式
- 実用的なサンプルコード

#### 4. カスタムスラッシュコマンド

[カスタムスラッシュコマンド](04-custom-slash-commands.md) では Claude Code 向けコマンド記述ルールを説明します。

#### 5. カスタムエージェント

[カスタムエージェント](05-custom-agents.md) では Claude Code 向けエージェント記述ルールを説明します。

### 使用ワークフロー

#### 新規ドキュメント作成時

1. [執筆ルール](01-writing-rules.md) で基本禁則事項を確認
2. [ドキュメントテンプレート](03-document-template.md) を参照
3. 目的に応じたテンプレートを選択・コピー
4. [フロントマターガイド](02-frontmatter-guide.md) でフロントマター記入

#### 既存ドキュメント改善時

1. [執筆ルール](01-writing-rules.md) で禁則事項を確認
2. フロントマター形式の標準化
3. プロジェクト品質基準との整合性確認

### ドキュメント分類・配置ルール

```bash
docs/
├── getting-started/     # 入門・導入ガイド
├── projects/           # プロジェクト概要・技術情報
├── rules/              # 開発ルール・ガイドライン
└── writing/            # ドキュメント作成ルール (このディレクトリ)
```

### 品質基準

- 統一された文書形式: 明確で理解しやすい構造
- プロジェクト統一: `@(#)` 記法・MIT ライセンス
- 読みやすさ: 適切な見出し階層・箇条書き
- 汎用性: ツール非依存の執筆ルール遵守

---

### See Also

- [プロジェクト概要](../projects/00-project-overview.md) - 全体アーキテクチャ
- [開発ワークフロー](../rules/01-development-workflow.md) - 開発手順
- [品質保証システム](../rules/03-quality-assurance.md) - 品質管理

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
