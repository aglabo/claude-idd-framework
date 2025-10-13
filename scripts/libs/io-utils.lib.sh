#!/usr/bin/env bash
# src: ./scripts/libs/io-utils.lib.sh
# @(#): General-purpose I/O utility library for bash scripts
#
# @file io-utils.lib.sh
# @brief General-purpose I/O utility library for bash scripts
# @description
#   Provides simple input/output utilities for bash scripts without structured logging overhead.
#   This library focuses on basic I/O operations and does not include logging levels,
#   timestamps, or error tracking. For structured logging, use logger.lib.sh instead.
#
#   Features:
#   - Simple stderr output utility (error_print)
#   - Supports both arguments and heredoc input
#   - No dependencies on logging frameworks
#   - Lightweight and reusable across scripts
#
# @example
#   . ./scripts/libs/io-utils.lib.sh
#   error_print "Simple error message"
#   error_print "Line 1" "Line 2"
#   error_print <<EOF
#     Multi-line error
#     with heredoc
#   EOF
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# ============================================================================
# Public API - I/O Utility Functions
# ============================================================================

##
# @description Print message to stderr
# @arg $@ string Message(s) to print (supports heredoc via stdin)
# @example
#   error_print "Simple error message"
#   error_print "Line 1" "Line 2"
#   error_print <<EOF
#     Multi-line error
#     with heredoc
#   EOF
# @stderr Message output
# @exitcode 0 Always succeeds
error_print() {
  if [[ $# -gt 0 ]]; then
    # Arguments provided: output each as separate line
    printf '%s\n' "$@" >&2
  else
    # No arguments: read from stdin (heredoc support)
    cat >&2
  fi
}
