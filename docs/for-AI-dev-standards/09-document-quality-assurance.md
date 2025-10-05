---
header:
  - src: 09-document-quality-assurance.md
  - @(#): Document Quality Assurance
title: agla-logger
description: AI コーディングエージェント用ドキュメント品質チェックシステム
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

## ドキュメント品質チェック

このドキュメントは AI コーディングエージェントが agla-logger プロジェクトでドキュメント作成・更新時に実行すべき品質チェックシステムを定義します。
ドキュメント品質の統一と信頼性確保を目的とします。

## 必須品質チェック

### 文書品質ツール設定

🔴 必須: ドキュメント作成・更新時は品質チェックツールでエラー 0 件を確認する。

```bash
# ドキュメント品質チェック (必須)
textlint --config configs/textlint/.textlintrc.yml docs/**/*.md
markdownlint-cli2 --config configs/markdownlint/.markdownlint-cli2.jsonc docs/**/*.md
dprint check

# ドキュメント修正
dprint fmt
```

### 品質ゲート実行原則

- エラー・警告が解決されるまで次のステップに進まない
- 自動修正可能な問題は修正コマンドを実行
- 修正不可能な問題は詳細分析・手動対応

## 詳細チェック手順

### textlint チェック

実行コマンド:

```bash
# 全 Markdown ファイルのチェック
textlint --config configs/textlint/.textlintrc.yml docs/**/*.md

# 特定ファイルのチェック
textlint --config configs/textlint/.textlintrc.yml docs/writing-rules/01-writing-rules.md

# 自動修正 (一部ルールのみ対応)
textlint --config configs/textlint/.textlintrc.yml --fix docs/**/*.md
```

よくあるエラーと対応方法:

| エラータイプ                                      | 説明               | 対応方法                 |
| ------------------------------------------------- | ------------------ | ------------------------ |
| `ja-technical-writing/sentence-length`            | 文章が長すぎる     | 句点で文章を分割する     |
| `ja-technical-writing/max-comma`                  | カンマが多すぎる   | 箇条書きや文章分割で対応 |
| `ja-spacing/ja-space-between-half-and-full-width` | 全角半角間スペース | スペースを適切に調整     |
| `ja-technical-writing/ja-no-weak-phrase`          | 弱い表現の使用     | 断定的な表現に変更       |

#### textlint エラー解決戦略

- 文章構造の見直し (長文の分割)
- 箇条書きの活用 (カンマ多用回避)
- スペース調整 (全角半角間の適切なスペース)
- 表現の断定化 (弱い表現の排除)

### markdownlint チェック

実行コマンド:

```bash
# 全 Markdown ファイルのチェック
markdownlint-cli2 --config configs/markdownlint/.markdownlint-cli2.jsonc docs/**/*.md

# 特定ファイルのチェック
markdownlint-cli2 --config configs/markdownlint/.markdownlint-cli2.jsonc docs/writing-rules/01-writing-rules.md

# 自動修正
markdownlint-cli2 --config configs/markdownlint/.markdownlint-cli2.jsonc --fix docs/**/*.md
```

よくあるエラーと対応方法:

| エラーコード | 説明                   | 対応方法                       |
| ------------ | ---------------------- | ------------------------------ |
| `MD001`      | 見出しレベルの順序違反 | 見出しを h1→h2→h3 の順序に修正 |
| `MD009`      | 行末の不要なスペース   | 行末スペースを削除             |
| `MD012`      | 複数の空行             | 空行を1行に統一                |
| `MD022`      | 見出し前後の空行不足   | 見出し前後に空行を追加         |
| `MD025`      | 複数の h1 見出し       | h1 は1つのみに制限             |

#### markdownlint エラー解決戦略

- 見出し階層の修正 (h1→h2→h3 の順序遵守)
- 空行・スペースの統一 (不要な空行・スペース削除)
- Markdown 構文の正規化 (統一された形式)

### dprint フォーマットチェック

実行コマンド:

```bash
# フォーマットチェック
dprint check

# 自動フォーマット適用
dprint fmt
```

#### dprint 設定

- インデント: スペース 2 個
- 行末: LF (Unix スタイル)
- 行末スペース: 削除
- 最終行改行: 追加

## エラー対応の優先順位

### 優先度レベル

1. Critical: 構文エラー (MD001, MD025 など)
2. High: 可読性に影響するエラー (sentence-length, max-comma など)
3. Medium: スタイル統一エラー (ja-spacing など)
4. Low: 細かい表現エラー (ja-no-weak-phrase など)

### エラー対応フロー

```bash
# 1. Critical エラー優先解決
markdownlint-cli2 --config configs/markdownlint/.markdownlint-cli2.jsonc --fix docs/**/*.md

# 2. High エラー手動修正
# 文章構造の見直し・分割

# 3. Medium/Low エラー対応
textlint --config configs/textlint/.textlintrc.yml --fix docs/**/*.md

# 4. 最終確認
textlint --config configs/textlint/.textlintrc.yml docs/**/*.md
markdownlint-cli2 --config configs/markdownlint/.markdownlint-cli2.jsonc docs/**/*.md
dprint check
```

## ドキュメント品質基準

### 必須達成基準

- textlint エラー: `0` 件
- markdownlint エラー: `0` 件
- dprint フォーマット違反: `0` 件
- プロジェクト統一記法: `@(#)` 記法・MIT ライセンス

### スタイル統一基準

- 見出し階層: h1→h2→h3 の順序遵守
- 箇条書き: 適切な階層・形式
- コードブロック: 言語指定・適切なインデント
- リンク: 相対パス (プロジェクト内) ・絶対パス (外部)

## プロジェクト固有ルール

### フロントマター必須要素

```yaml
---
header:
  - src: <filename>
  - @(#): <Document Identifier>
title: agla-logger
description: <ドキュメント概要>
version: 1.0.0
created: YYYY-MM-DD
authors:
  - atsushifx
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---
```

### 記法統一ルール

- 括弧: 半角 `()` 使用
- 括弧前: 半角スペース挿入
- 技術用語: バッククォートで囲む (`pnpm`, `textlint`)
- コマンド: コードブロック使用

## トラブルシューティング

### textlint エラー未解決

```bash
# エラー詳細確認
textlint --config configs/textlint/.textlintrc.yml --debug docs/target.md

# ルール無効化 (最終手段)
<!-- textlint-disable rule-name -->
対象テキスト
<!-- textlint-enable rule-name -->
```

### markdownlint エラー未解決

```bash
# エラー詳細確認
markdownlint-cli2 --config configs/markdownlint/.markdownlint-cli2.jsonc docs/target.md

# ルール無効化 (最終手段)
<!-- markdownlint-disable rule-code -->
対象テキスト
<!-- markdownlint-enable rule-code -->
```

### dprint フォーマット失敗

```bash
# 設定確認
cat .dprint.json

# 個別ファイルフォーマット
dprint fmt docs/target.md
```

## 完了基準

### ドキュメント品質確認完了条件

- [ ] textlint エラー 0 件
- [ ] markdownlint エラー 0 件
- [ ] dprint フォーマット違反 0 件
- [ ] フロントマター形式遵守
- [ ] プロジェクト固有ルール遵守

### 未完了時の対応

- エラー未解決の場合は修正継続
- 修正不可能な場合は理由を明記
- ルール無効化は最終手段として使用

---

### See Also

- [08-quality-assurance.md](08-quality-assurance.md) - コード品質ゲート
- [../writing-rules/01-writing-rules.md](../writing-rules/01-writing-rules.md) - 執筆ルール
- [../writing-rules/README.md](../writing-rules/README.md) - ドキュメント作成ガイド

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
