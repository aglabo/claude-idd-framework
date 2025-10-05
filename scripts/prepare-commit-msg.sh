#!/usr/bin/env bash
# src: ./scripts/prepare-codex-msg.sh
# @(#) : prepare commit message using Codex CLI if no message exists
#
# Usage:
#   prepare-commit-msg.sh                  # 標準出力にコミットメッセージを出力
#   prepare-commit-msg.sh --git-buffer     # Gitバッファーにコミットメッセージを出力
#   prepare-commit-msg.sh --to-buffer      # Gitバッファーにコミットメッセージを出力（短縮形）
#
# Copyright (c) 2025 atsushifx
# Released under the MIT License.
# https://opensource.org/licenses/MIT

set -euCo pipefail

## Constants
REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly REPO_ROOT

## Variables
GIT_COMMIT_MSG=".git/COMMIT_EDITMSG"
# TMP_MSG="./temp/commit_current_msg.md"
FLAG_OUTPUT_TO_STDOUT=true  # デフォルトは標準出力

## Parse command line options
while [[ $# -gt 0 ]]; do
  case $1 in
    --git-buffer|--to-buffer)
      FLAG_OUTPUT_TO_STDOUT=false
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--git-buffer|--to-buffer] [commit_msg_file]"
      echo "  --git-buffer, --to-buffer : Gitバッファーにコミットメッセージを出力"
      echo "  デフォルト                 : 標準出力にコミットメッセージを出力"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      # 引数がオプションでない場合はコミットメッセージファイルとして扱う
      GIT_COMMIT_MSG="$1"
      shift
      ;;
  esac
done

mkdir -p temp

## 関数: 既存ﾒ・bｾZｰ[ｼﾞWがあるかﾁ`ｪFｯbｸN
has_existing_message() {
  local file="$1"
  grep -vE '^\s*(#|$)' "$file" | grep -q '.'
}

## 関数: diff と log をまとめる
make_context_block() {
  echo "----- GIT LOGS -----"
  git log --oneline -10 || echo "No logs available."
  echo "----- END LOGS -----"
  echo
  echo "----- GIT DIFF -----"
  git diff --cached || echo "No diff available."
  echo "----- END DIFF -----"
}

## 関数: Codex CLI を呼ぶ
generate_commit_message() {
  local test_message="${1:-}"

  # テストメッセージが指定されている場合はそのまま返す
  if [[ -n "$test_message" ]]; then
    echo "${test_message}"
    return 0
  fi

  local full_output
  full_output=$({
    cat .claude/agents/commit-message-generator.md
    echo
    make_context_block
  } | codex exec --model gpt-5-codex
  )

  # === commit header === と === commit footer === に囲まれた部分を抽出
  echo "$full_output" | \
    sed '/^----- END DIFF -----$/,$!d' | sed '1d' | \
    sed -n '/^=== commit header ===/,/^=== commit footer ===/p' | \
    sed '1d;$d'

}

## Main
cd "$REPO_ROOT"

# Gitバッファーモードの場合のみ既存メッセージチェック
if [[ "$FLAG_OUTPUT_TO_STDOUT" == false && -f "$GIT_COMMIT_MSG" ]]; then
  if has_existing_message "$GIT_COMMIT_MSG"; then
    echo "✦ Detected existing Git-generated commit message. Skipping Codex." >&2
    exit 0
  fi
fi

# コミットメッセージ生成
commit_msg=$(generate_commit_message)

if [[ "$FLAG_OUTPUT_TO_STDOUT" == true ]]; then
  # 標準出力モード
  echo "$commit_msg"
else
  # Gitバッファーモード
  rm -f "$GIT_COMMIT_MSG"
  echo "$commit_msg" > "$GIT_COMMIT_MSG"
  echo "✦ Commit message written to $GIT_COMMIT_MSG" >&2
fi
