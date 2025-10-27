---
# Claude Code 必須要素
allowed-tools:
  Bash(
    jq:*, echo:*, cat:*
  ),
  Read(*)
argument-hint: select_list(json)
description: Interactive list selection from subcommand session

# 設定変数
config:
  libs_dir: .claude/commands/_libs

# ag-logger プロジェクト要素
title: select-from-list
version: 1.0.0
created: 2025-10-16
authors:
  - atsushifx
changes:
  - 2025-10-16: 初版作成 - サブコマンドセッション対話選択機能実装
---

## _internal/_select-from-list : Overview

サブコマンド:
カスタムスラッシュコマンドから呼び出されて、項目の一覧を表示します。
一覧から項目を選択し、選択した項目を返します。

## 入出力

### 入力パラメータ

#### 入力パラメータ (シンプルリスト)

```json
{
  "items": [
    "Apple",
    "Banana",
    "Cherry"
  ],
  "current": "Apple"
}
```

- パラメータ:
  - `items`: 選択候補の配列 (文字列リスト)
  - `current`: 現在選択中の項目 (任意)

#### 入力パラメータ (オブジェクト形式)

```json
{
  "items": [
    { "title": "Apple", "desc": "🍎 甘くてジューシーな赤い果物" },
    { "title": "Banana", "desc": "🍌 エネルギー補給に最適な黄色い果物" },
    { "title": "Cherry", "desc": "🍒 季節限定の小さな果実" }
  ],
  "current": "Cherry"
}
```

- パラメータ:
  - `title`: 表示タイトル
  - `desc`: 説明文
  - `current`: 現在の選択項目 (任意)

### 出力

#### 出力 (選択)

```json
{
  "selected": "Apple",
  "index": 1
}
```

### 選択キャンセル

```json
{
  "cancel": true
}
```

## 実装

```bash
#!/usr/bin/env bash
# 項目選択インターフェース実装

set -euo pipefail

# JSON パラメータを標準入力または引数から取得
if [[ $# -eq 0 ]]; then
  json_input=$(cat)
else
  json_input="$1"
fi

# JSON パラメータ解析
items=$(echo "$json_input" | jq -r '.items')
current=$(echo "$json_input" | jq -r '.current // ""')

# アイテム数を取得
item_count=$(echo "$items" | jq 'length')

if [[ $item_count -eq 0 ]]; then
  echo '{"error": "No items provided"}' >&2
  exit 1
fi

# 最初のアイテムの型を判定（文字列 or オブジェクト）
first_item=$(echo "$items" | jq -r '.[0]')
is_object=$(echo "$first_item" | jq -e 'type == "object"' >/dev/null 2>&1 && echo "true" || echo "false")

# 項目一覧を表示
echo "=== Select an item ===" >&2
echo "" >&2

for i in $(seq 0 $((item_count - 1))); do
  num=$((i + 1))
  # 2桁表示（1桁の場合は前に空白）
  if [[ $num -lt 10 ]]; then
    num_display=" $num"
  else
    num_display="$num"
  fi

  if [[ "$is_object" == "true" ]]; then
    # オブジェクト形式
    title=$(echo "$items" | jq -r ".[$i].title")
    desc=$(echo "$items" | jq -r ".[$i].desc // \"\"")

    # current マーカー
    if [[ "$current" == "$title" ]]; then
      marker=">"
    else
      marker=" "
    fi

    echo "$num_display. $marker $title" >&2
    if [[ -n "$desc" ]]; then
      echo "      - $desc" >&2
    fi
  else
    # シンプルリスト形式
    item=$(echo "$items" | jq -r ".[$i]")

    # current マーカー
    if [[ "$current" == "$item" ]]; then
      marker=">"
    else
      marker=" "
    fi

    echo "$num_display. $marker $item" >&2
  fi
done

echo "" >&2
echo "Enter number (1-$item_count), or 'q' to cancel: " >&2

# 選択入力を受け付け
read -r selection

# キャンセル判定
if [[ "$selection" == "q" ]] || [[ "$selection" == "cancel" ]] || [[ -z "$selection" ]]; then
  echo '{"cancel": true}'
  exit 0
fi

# 数値検証
if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
  echo '{"error": "Invalid input: not a number"}' >&2
  exit 1
fi

# 範囲検証
if [[ $selection -lt 1 ]] || [[ $selection -gt $item_count ]]; then
  echo "{\"error\": \"Invalid selection: must be between 1 and $item_count\"}" >&2
  exit 1
fi

# 選択されたアイテムを取得（0-indexed）
selected_index=$((selection - 1))

if [[ "$is_object" == "true" ]]; then
  selected_value=$(echo "$items" | jq -r ".[$selected_index].title")
else
  selected_value=$(echo "$items" | jq -r ".[$selected_index]")
fi

# JSON 出力
jq -n \
  --arg selected "$selected_value" \
  --argjson index "$selection" \
  '{selected: $selected, index: $index}'
```

## 使用例

### シンプルリスト形式

```bash
echo '{"items": ["Apple", "Banana", "Cherry"], "current": "Banana"}' | bash _select_from_list.md
```

出力:

```
=== Select an item ===

 1.   Apple
 2. > Banana
 3.   Cherry

Enter number (1-3), or 'q' to cancel:
```

### オブジェクト形式

```bash
cat <<'EOF' | bash _select_from_list.md
{
  "items": [
    {"title": "feature", "desc": "新機能追加"},
    {"title": "bug", "desc": "バグ修正"},
    {"title": "enhancement", "desc": "既存機能の改善"}
  ],
  "current": "bug"
}
EOF
```

出力:

```
=== Select an item ===

 1.   feature
      - 新機能追加
 2. > bug
      - バグ修正
 3.   enhancement
      - 既存機能の改善

Enter number (1-3), or 'q' to cancel:
```
