#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/integration/prepare-commit-msg-file.integration.spec.sh
# @(#): Integration tests for file I/O operations
#
# @file prepare-commit-msg-file.integration.spec.sh
# @brief Integration tests for file handling functionality
# @description
#   Tests has_existing_message() and output_commit_message() file mode.
#   Validates real file I/O operations and content checking.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - File I/O operations'
  # Source the actual script to get function definitions
  Include scripts/prepare-commit-msg.sh

  # Helper function: stdin-based version for testing without file I/O
  has_existing_message_stdin() {
    grep -vE '^\s*(#|$)' | grep -q '.'
  }

  Describe 'has_existing_message()'
    Context 'Given: empty content'
      It 'Then: [正常] - returns false (exit code 1) for empty input'
        Data ""
        When call has_existing_message_stdin
        The status should equal 1
      End

      It 'Then: [正常] - returns false (exit code 1) for only whitespace'
        Data "   "
        When call has_existing_message_stdin
        The status should equal 1
      End

      It 'Then: [正常] - returns false (exit code 1) for only comments'
        Data
          #|# This is a comment
          #|# Another comment
        End
        When call has_existing_message_stdin
        The status should equal 1
      End
    End

    Context 'Given: content with actual message'
      It 'Then: [正常] - returns true (exit code 0) for commit message'
        Data "feat: add new feature"
        When call has_existing_message_stdin
        The status should equal 0
      End

      It 'Then: [正常] - returns true (exit code 0) for message with comments'
        Data
          #|feat: add new feature
          #|
          #|# Please enter the commit message for your changes.
        End
        When call has_existing_message_stdin
        The status should equal 0
      End

      It 'Then: [正常] - returns true (exit code 0) for multiline message'
        Data
          #|feat: add new feature
          #|
          #|This is the body of the commit message.
          #|It spans multiple lines.
          #|
          #|# Comments below
        End
        When call has_existing_message_stdin
        The status should equal 0
      End
    End

  End

  Describe 'output_commit_message() - file mode'
    setup() {
      FLAG_OUTPUT_TO_STDOUT=false
      TEST_OUTPUT_FILE="./temp/test_output_commit_msg"
      mkdir -p ./temp
    }

    cleanup() {
      rm -f "$TEST_OUTPUT_FILE"
    }

    BeforeEach 'setup'
    AfterEach 'cleanup'

    Context 'Given: FLAG_OUTPUT_TO_STDOUT is false (Git buffer mode)'
      It 'Then: [正常] - writes message to file and outputs confirmation'
        FLAG_OUTPUT_TO_STDOUT=false
        When call output_commit_message "feat: test commit" "$TEST_OUTPUT_FILE"
        The stderr should include "✦ Commit message written to"
        The stderr should include "$TEST_OUTPUT_FILE"
        The file "$TEST_OUTPUT_FILE" should be exist
        The contents of file "$TEST_OUTPUT_FILE" should equal "feat: test commit"
      End

    End
  End
End
