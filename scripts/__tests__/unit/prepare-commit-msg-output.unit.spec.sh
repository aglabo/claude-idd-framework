#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/prepare-commit-msg-output.unit.spec.sh
# @(#): Unit tests for output_commit_message() stdout mode
#
# @file prepare-commit-msg-output.unit.spec.sh
# @brief Unit tests for stdout output functionality
# @description
#   Tests the output_commit_message() function in stdout mode.
#   Validates message output without file I/O dependencies.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - output_commit_message() stdout mode'
  # Source the actual script to get function definitions
  Include scripts/prepare-commit-msg.sh

  Describe 'output_commit_message()'
    setup() {
      FLAG_OUTPUT_TO_STDOUT=true
      TEST_OUTPUT_FILE="./temp/test_output_commit_msg"
    }

    BeforeEach 'setup'

    Context 'Given: FLAG_OUTPUT_TO_STDOUT is true (stdout mode)'
      It 'Then: [正常] - outputs message to stdout'
        FLAG_OUTPUT_TO_STDOUT=true
        When call output_commit_message "feat: test commit" "$TEST_OUTPUT_FILE"
        The output should equal "feat: test commit"
      End

      It 'Then: [正常] - handles multi-line messages'
        FLAG_OUTPUT_TO_STDOUT=true
        multiline="feat: test commit

This is the body."
        When call output_commit_message "$multiline" "$TEST_OUTPUT_FILE"
        The line 1 should equal "feat: test commit"
        The line 2 should equal ""
        The line 3 should equal "This is the body."
      End
    End
  End
End
