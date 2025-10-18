#!/bin/bash
##
# IDD I/O Utilities Library
#
# I/O操作用のヘルパー関数を提供します。
#
# @file io-utils.lib.sh
# @version 1.0.0
# @license MIT

##
# エラーメッセージを標準エラー出力に表示
#
# 可変長引数とヒアドキュメントの両方に対応します。
# - 引数が渡された場合: すべての引数を結合して出力
# - 引数がない場合: 標準入力 (ヒアドキュメント) から読み込んで出力
#
# @param $@ エラーメッセージ (可変長引数、オプション)
# @return 常に0を返す
# @example
#   # 引数指定
#   error_print "❌ Error: File not found: $file"
#   error_print "❌" "Error:" "Multiple arguments"
#
#   # ヒアドキュメント
#   error_print <<EOF
#   ❌ Error: Invalid configuration
#   Please check the following:
#   - Config file exists
#   - JSON syntax is valid
#   EOF
error_print() {
  if [ $# -gt 0 ]; then
    # 引数が渡された場合: すべての引数を結合して出力
    echo "$@" >&2
  else
    # 引数がない場合: 標準入力から読み込んで出力
    cat >&2
  fi
}

##
# y/n/q 選択入力を取得
#
# ユーザーに y/n/q の選択を求め、正規化された値を返します。
# - y/yes → "y" を返す
# - n/no → "n" を返す
# - q/quit → "q" を返す
# - その他 → エラーメッセージを表示して再入力
#
# @param $1 プロンプトメッセージ (オプション、デフォルト: "選択してください (y/n/q): ")
# @return 0 (成功)
# @stdout "y", "n", "q" のいずれか
# @example
#   choice=$(get_choice)
#   choice=$(get_choice "このタイトルでよろしいですか? (y/n/q): ")
get_choice() {
  local prompt="${1:-選択してください (y/n/q): }"
  local choice

  while true; do
    read -r -p "$prompt" choice

    # 小文字に変換
    choice=$(echo "$choice" | tr '[:upper:]' '[:lower:]')

    case "$choice" in
      y|yes)
        echo "y"
        return 0
        ;;
      n|no)
        echo "n"
        return 0
        ;;
      q|quit)
        echo "q"
        return 0
        ;;
      *)
        echo "エラー: y/yes, n/no, q/quit のいずれかを入力してください" >&2
        ;;
    esac
  done
}
