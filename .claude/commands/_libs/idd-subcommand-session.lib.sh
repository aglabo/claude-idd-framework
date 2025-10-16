#!/bin/bash
##
# IDD Subcommand Session Library
#
# サブコマンド間のデータ受け渡し用セッション管理を提供します。
# JSON形式でINPUT/OUTPUTを管理し、スラッシュコマンド間の連携を実現します。
#
# @file idd-subcommand-session.lib.sh
# @version 1.0.0
# @license MIT

# 依存: io-utils.lib.sh (error_print)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_libs/io-utils.lib.sh
. "$SCRIPT_DIR/io-utils.lib.sh"

##
# セッションファイルパスを取得
#
# リポジトリルートの temp/idd/.subcommand.session に固定
#
# @return セッションファイルの絶対パス (標準出力)
_get_session_file_path() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [ -z "$repo_root" ]; then
    error_print "Not in a git repository" >&2
    return 1
  fi

  local session_dir="$repo_root/temp/idd"
  local session_file="$session_dir/.subcommand.session"

  # ディレクトリが存在しない場合は作成
  if [ ! -d "$session_dir" ]; then
    mkdir -p "$session_dir" 2>/dev/null || {
      error_print "Failed to create session directory: $session_dir" >&2
      return 1
    }
  fi

  echo "$session_file"
  return 0
}

# グローバル定数: サブコマンドセッションファイルパス (temp/idd/.subcommand.session)
SUBCOMMAND_SESSION_FILE=$(_get_session_file_path)
readonly SUBCOMMAND_SESSION_FILE

##
# セッションにINPUTを書き込み
#
# サブコマンド実行前にパラメータをセッションファイルに保存します。
# JSON形式で保存され、他のサブコマンドから読み込み可能です。
#
# @param $1 コマンド名
# @param $2 JSON形式のINPUTデータ
# @return 0=成功, 1=失敗
# @example
#   items_json='["item1","item2","item3"]'
#   input_json=$(jq -n --arg prompt "Select" --argjson items "$items_json" \
#     '{prompt: $prompt, items: $items}')
#   _write_subcommand_input "select-from-list" "$input_json"
_write_subcommand_input() {
  local command="$1"
  local input_json="$2"
  local session_file="$SUBCOMMAND_SESSION_FILE"

  if ! command -v jq >/dev/null 2>&1; then
    error_print "jq is required but not installed"
    return 1
  fi

  # セッションファイル作成
  cat > "$session_file" <<EOF
{
  "command": "$command",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S)",
  "input": $input_json,
  "output": null
}
EOF

  return 0
}

##
# セッションからINPUTを読み込み
#
# @return JSON形式のINPUTデータ (標準出力)
# @example
#   input=$(_read_subcommand_input)
#   prompt=$(echo "$input" | jq -r '.prompt')
_read_subcommand_input() {
  local session_file="$SUBCOMMAND_SESSION_FILE"

  if [ ! -f "$session_file" ]; then
    echo "{}"
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    error_print "jq is required but not installed"
    echo "{}"
    return 1
  fi

  jq -r '.input' "$session_file" 2>/dev/null || echo "{}"
}

##
# セッションにOUTPUTを書き込み
#
# サブコマンド実行後の結果をセッションファイルに保存します。
# 既存のINPUTを保持したまま、OUTPUTフィールドのみを更新します。
#
# @param $1 JSON形式のOUTPUTデータ
# @return 0=成功, 1=失敗
# @example
#   output_json=$(jq -n --arg item "selected.md" \
#     '{selected_item: $item, status: "success"}')
#   _write_subcommand_output "$output_json"
_write_subcommand_output() {
  local output_json="$1"
  local session_file="$SUBCOMMAND_SESSION_FILE"

  if [ ! -f "$session_file" ]; then
    error_print "No subcommand session found. Run command with INPUT first."
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    error_print "jq is required but not installed"
    return 1
  fi

  # 既存のINPUTを保持してOUTPUTのみ更新
  local temp_file="${session_file}.tmp"
  if jq ".output = $output_json" "$session_file" > "$temp_file" 2>/dev/null; then
    mv "$temp_file" "$session_file"
    return 0
  else
    rm -f "$temp_file"
    error_print "Failed to update session output"
    return 1
  fi
}

##
# セッションからOUTPUTを読み込み
#
# @return JSON形式のOUTPUTデータ (標準出力、nullの場合もあり)
# @example
#   output=$(_read_subcommand_output)
#   if [ "$output" != "null" ]; then
#     selected=$(echo "$output" | jq -r '.selected_item')
#   fi
_read_subcommand_output() {
  local session_file="$SUBCOMMAND_SESSION_FILE"

  if [ ! -f "$session_file" ]; then
    echo "null"
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    error_print "jq is required but not installed"
    echo "null"
    return 1
  fi

  jq -r '.output' "$session_file" 2>/dev/null || echo "null"
}

##
# セッションをクリア
#
# サブコマンド実行完了後、セッションファイルを削除します。
#
# @return 常に0
# @example
#   # Issue表示後にセッションクリア
#   cat "$ISSUE_FILE"
#   _clear_subcommand_session
_clear_subcommand_session() {
  local session_file="$SUBCOMMAND_SESSION_FILE"

  if [ -f "$session_file" ]; then
    rm -f "$session_file"
  fi
  return 0
}

##
# セッションの存在確認
#
# @return 0=セッション存在, 1=セッションなし
# @example
#   if _has_subcommand_session; then
#     output=$(_read_subcommand_output)
#   fi
_has_subcommand_session() {
  local session_file="$SUBCOMMAND_SESSION_FILE"
  [ -f "$session_file" ]
}
