#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/io-utils.lib.spec.sh
# @(#): ShellSpec tests for io-utils.lib.sh
#
# @file io-utils.lib.spec.sh
# @brief ShellSpec tests for io-utils.lib.sh
# @description
#   Comprehensive test suite for the io-utils.lib.sh library.
#   Tests simple I/O utility functions including error_print.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'io-utils.lib.sh'
  # Source the library
  Include scripts/libs/io-utils.lib.sh

  # ============================================================================
  # error_print() Tests
  # ============================================================================

  Describe 'error_print()'
    Context 'When: called with single argument'
      It 'Then: [正常] - outputs message to stderr'
        When call error_print "Simple error message"
        The output should equal ""
        The stderr should equal "Simple error message"
      End
    End

    Context 'When: called with multiple arguments'
      It 'Then: [正常] - outputs each argument as separate line to stderr'
        When call error_print "Line 1" "Line 2" "Line 3"
        The output should equal ""
        The line 1 of stderr should equal "Line 1"
        The line 2 of stderr should equal "Line 2"
        The line 3 of stderr should equal "Line 3"
      End
    End

    Context 'When: called with heredoc (no arguments, stdin input)'
      test_heredoc() {
        error_print <<EOF
Error: Multi-line message
  Detail line 1
  Detail line 2
EOF
      }

      It 'Then: [正常] - outputs stdin content to stderr'
        When run test_heredoc
        The output should equal ""
        The line 1 of stderr should equal "Error: Multi-line message"
        The line 2 of stderr should equal "  Detail line 1"
        The line 3 of stderr should equal "  Detail line 2"
      End
    End

    Context 'When: called via pipe'
      test_pipe() {
        echo "Piped error message" | error_print
      }

      It 'Then: [正常] - outputs piped content to stderr'
        When run test_pipe
        The output should equal ""
        The stderr should equal "Piped error message"
      End
    End

    Context 'When: edge cases'
      It 'Then: [エッジケース] - handles empty string argument'
        When call error_print ""
        The output should equal ""
        The stderr should equal ""
      End

      It 'Then: [エッジケース] - handles special characters'
        When call error_print "Error with \$VAR and 'quotes' and \"double\""
        The output should equal ""
        The stderr should include "\$VAR"
        The stderr should include "'quotes'"
        The stderr should include "\"double\""
      End
    End
  End
End
