---
header:
  - src: scripts/README-xcp.md
  - "@(#): xcp.sh 基本的な使い方"
title: claude-idd-framework
description: eXtended CoPy utility の基本的な使用方法
version: 1.0.0
created: 2025-10-13
authors:
  - atsushifx
changes:
  - 2025-10-13: 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

# xcp.sh - eXtended CoPy utility

`xcp.sh` は、標準の `cp` コマンドを拡張した高機能なファイルコピーユーティリティです。
複数の動作モード、dry-run プレビュー、再帰コピー、エラートラッキングなどの機能を提供します。

## 基本的な使用例

### 基本コピー (既存ファイルはスキップ)

```bash
bash scripts/xcp.sh source.txt dest.txt
```

デフォルトでは、既存ファイルは上書きせずスキップします。

### Dry-run プレビュー

```bash
bash scripts/xcp.sh --dry-run -R source/ dest/
```

実際にコピーせず、実行内容をプレビュー表示します。

### バックアップ付きコピー

```bash
bash scripts/xcp.sh -b source.txt dest.txt
```

既存ファイルをタイムスタンプ付きでバックアップしてからコピーします (例: `dest.txt.bak.250113120000`)。

### 再帰的ディレクトリコピー (隠しファイル含む)

```bash
bash scripts/xcp.sh -RH source/ dest/
```

ディレクトリを再帰的にコピーし、ドットファイル (隠しファイル) も含めます。

### 複数ファイル一括コピー

```bash
bash scripts/xcp.sh -p file1.txt file2.txt file3.txt /dest/dir/
```

複数のソースファイルを指定したディレクトリにコピーします。`-p` オプションで親ディレクトリを自動作成します。

## 主要オプション

### 動作モード

- `-n, --noclobber`: 既存ファイルをスキップ (デフォルト)
- `-f, --force`: 既存ファイルを上書き
- `-u, --update`: ソースが新しい場合のみ更新
- `-b, --backup`: 既存ファイルをバックアップしてから上書き

### コピーオプション

- `-r, -R, --recursive`: ディレクトリを再帰的にコピー
- `-p, --parents`: 必要に応じて親ディレクトリを作成
- `-L, --dereference`: シンボリックリンクの実体をコピー
- `-H, --hidden`: 隠しファイル (ドットファイル) を含める

### 実行制御

- `--dry-run`: 実際にコピーせず、実行内容をプレビュー表示
- `--fail-fast`: エラー発生時に即座に停止

### 出力制御

- `-v, --verbose`: 詳細な進行状況を表示
- `-q, --quiet`: エラーメッセージのみ表示

### その他

- `-h, --help`: ヘルプメッセージを表示
- `-V, --version`: バージョン情報を表示

## 詳細ヘルプ

すべてのオプションと詳細な説明は、以下のコマンドで確認できます。

```bash
bash scripts/xcp.sh --help
```

## 関連ドキュメント

- [scripts/xcp.sh](xcp.sh): スクリプト本体 (shdoc ヘッダーに詳細な実装情報)
- [scripts/README.md](README.md): セットアップスクリプト全般の説明

---

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
