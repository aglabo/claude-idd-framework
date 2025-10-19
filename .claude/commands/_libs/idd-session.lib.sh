#!/bin/bash
##
# IDD Session Management Library
#
# セッション管理用のヘルパー関数を提供します。
#
# @file idd-session.lib.sh
# @version 1.1.0
# @license MIT

# 依存: io-utils.lib.sh (error_print)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_libs/io-utils.lib.sh
source "$SCRIPT_DIR/io-utils.lib.sh"

##
# 最終使用ファイル名を保存
#
# @param $1 ディレクトリパス
# @param $2 ファイル名
# @return 0=成功, 1=失敗
# @example
#   _save_last_file "$PR_DIR" "feature-123.md"
#   # → $PR_DIR/.last_draft に "feature-123.md" を保存
_save_last_file() {
  local dir="$1"
  local filename="$2"

  if [ -z "$dir" ] || [ -z "$filename" ]; then
    error_print "❌ Error: Directory and filename required"
    return 1
  fi

  echo "$filename" > "$dir/.last_draft"
}

##
# 最終使用ファイル名を読み込み
#
# @param $1 ディレクトリパス
# @param $2 デフォルトファイル名 (ファイルがない場合)
# @return ファイル名
# @example
#   OUTPUT_FILE=$(_load_last_file "$PR_DIR" "pr_current_draft.md")
_load_last_file() {
  local dir="$1"
  local default="$2"

  if [ -f "$dir/.last_draft" ]; then
    cat "$dir/.last_draft"
  else
    echo "$default"
  fi
}

##
# セッション情報を保存（key, value のペアを可変長で受け取る形式）
#
# @param $1 セッションファイルパス
# @param $@ キーと値のペア（例: KEY1 VALUE1 KEY2 VALUE2 ...）
# @return 0=成功, 1=失敗（ファイルパスが指定されていない場合など）
# @example
#   _save_session "$SESSION_FILE" \
#     LAST_ISSUE_FILE "$filename" \
#     LAST_ISSUE_NUMBER "$issue_num" \
#     LAST_COMMAND "$command"
_save_session() {
  local session_file="$1"
  shift

  if [ -z "$session_file" ]; then
    error_print "❌ Error: Session file path required"
    return 1
  fi

  {
    echo "# Last session"

    local i=0
    while [ "$i" -lt "$#" ]; do
      local key="${!i}"
      local val_index=$((i + 1))

      if [ "$val_index" -ge "$#" ]; then
        error_print "⚠️ Warning: Unpaired key for '${key}'"
        break
      fi

      local value="${!val_index}"
      echo "$key=\"${value}\""

      i=$((i + 2))
    done

    echo "LAST_MODIFIED=\"$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S)\""
  } > "$session_file"
}

##
# セッション情報を読み込み、変数として展開
#
# @param $1 セッションファイルパス
# @return 0=成功 (変数が展開される), 1=失敗
# @example
#   _load_session "$SESSION_FILE"
#   echo "Last issue: $LAST_ISSUE_NUMBER"
_load_session() {
  local session_file="$1"

  if [ ! -f "$session_file" ]; then
    return 1
  fi

  # shellcheck disable=SC1090
  . "$session_file"
  return 0
}

##
# セッションファイルの存在確認
#
# @param $1 セッションファイルパス
# @return 0=存在, 1=存在しない
# @example
#   if _has_session "$SESSION_FILE"; then
#     echo "Session exists"
#   fi
_has_session() {
  local session_file="$1"
  [ -f "$session_file" ]
}
