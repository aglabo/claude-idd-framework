# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

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
