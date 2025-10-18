---
# Claude Code 必須要素
allowed-tools:
  AskUserQuestion(*)
argument-hint: [title]
description: 新しくIssueを作成する

# 設定変数
config:
  issues_dir: temp/idd/issues
  session_file: temp/idd/issues/.last.session

# ag-logger プロジェクト要素
title: /idd:issue:new
version: 2.0.0
created: 2025-10-16
authors:
  - atsushifx
changes:
  - 2025-10-18: v2.0.0 - AskUserQuestion ツールを使った対話的実装に変更
  - 2025-10-16: v1.0.0 - 初版作成
copyright:
  - Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
  - This software is released under the MIT License.
  - https://opensource.org/licenses/MIT
---

# /idd:issue:new - 新しいIssue作成

ユーザーから Issue のタイトルを取得し、確認ループを行います。

## 処理フロー

1. **タイトル取得**
   - 引数でタイトルが渡された場合: それを初期値として使用
   - 引数がない場合: ユーザーに「Issue タイトルを入力してください」と質問

2. **タイトル確認ループ**
   - 取得したタイトルを表示: `入力されたタイトル: {title}`
   - AskUserQuestion ツールで確認:
     - 質問: "このタイトルでよろしいですか?"
     - 選択肢:
       - "はい (確定)" → 次のステップへ
       - "キャンセル" → 処理を中止
       - "Other" → カスタム入力で新しいタイトルを入力

3. **確定後の処理**
   - 確定メッセージを表示: `✓ 確定したタイトル: {title}`
   - 次のステップは未実装のため、ここで終了

## 実装指示

### タイトル取得

引数 `$1` が渡されているか確認してください：
- 引数あり: `$1` を初期タイトルとして使用
- 引数なし: ユーザーにタイトル入力を求める（通常のテキスト応答で）

### 確認ループ

AskUserQuestion ツールを使って以下の質問を繰り返してください：

```
question: "このタイトルでよろしいですか?"
header: "確認"
options:
  - label: "はい (確定)"
    description: "このタイトルで Issue を作成します"
  - label: "キャンセル"
    description: "Issue 作成を中止します"
multiSelect: false
```

再入力したい場合は、ユーザーが "Other" (カスタム入力) で新しいタイトルを入力できます。

### 選択による分岐

- **"はい (確定)"**: ループを抜けて確定メッセージを表示
- **"キャンセル"**: `Issue作成を中止しました` と表示して処理終了
- **"Other" (カスタム入力)**: 入力されたテキストを新しいタイトルとして使用し、再度確認ループ

### 出力形式

確定時は以下のメッセージを表示してください：

```
✓ 確定したタイトル: {title}

(今回はここで終了します - 次のステップは未実装)
```

## See Also

- `/idd-issue`: IDD Issue 管理システムのメインコマンド
- `/_helpers/_get-summary`: タイトルとサマリーの検証・編集ヘルパー

## License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).
Copyright (c) 2025 atsushifx
