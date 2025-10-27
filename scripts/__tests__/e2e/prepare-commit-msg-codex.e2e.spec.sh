#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/e2e/prepare-commit-msg-codex.e2e.spec.sh
# @(#): E2E tests for prepare-commit-msg.sh script execution
#
# @file prepare-commit-msg-codex.e2e.spec.sh
# @brief End-to-end tests for complete script workflow
# @description
#   Tests the entire prepare-commit-msg.sh script execution.
#   Uses test_message parameter to avoid external Codex CLI dependency.
#   Validates complete integration of all components.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - E2E script execution'
  # Source the actual script to get function definitions
  Include scripts/prepare-commit-msg.sh

  Describe 'Full script workflow with test message'
    setup() {
      TEST_COMMIT_FILE="./temp/test_e2e_commit_msg"
      mkdir -p ./temp
    }

    cleanup() {
      rm -f "$TEST_COMMIT_FILE"
    }

    BeforeEach 'setup'
    AfterEach 'cleanup'

    Context 'Given: stdout mode (default)'
      It 'Then: [正常] - outputs complete commit message to stdout'
        When call generate_commit_message "feat(e2e): test commit message

This is a test body with details.

Refs: #123"
        The status should equal 0
        The line 1 should equal "feat(e2e): test commit message"
        The output should include "This is a test body with details."
        The output should include "Refs: #123"
      End

      It 'Then: [正常] - validates Conventional Commits format'
        When call generate_commit_message "fix(parser): resolve null pointer exception"
        The status should equal 0
        The line 1 should equal "fix(parser): resolve null pointer exception"
        The output should include "fix(parser):"
      End
    End

    Context 'Given: Git buffer mode'
      # Note: Detailed file I/O tests are in integration/prepare-commit-msg-file.integration.spec.sh
      # E2E only verifies basic integration
      It 'Then: [正常] - writes message to file successfully'
        FLAG_OUTPUT_TO_STDOUT=false
        When call output_commit_message "feat: e2e test" "$TEST_COMMIT_FILE"
        The stderr should include "✦ Commit message written to"
        The file "$TEST_COMMIT_FILE" should be exist
      End
    End

    Context 'Given: Git context integration'
      It 'Then: [正常] - make_context_block generates valid output'
        When call make_context_block
        The status should equal 0
        The output should include "----- GIT LOGS -----"
        The output should include "----- END LOGS -----"
        The output should include "----- GIT DIFF -----"
        The output should include "----- END DIFF -----"
      End
    End

    Context 'Given: has_existing_message validation'
      It 'Then: [正常] - detects existing commit message'
        echo "feat: existing message" > "$TEST_COMMIT_FILE"
        When call has_existing_message "$TEST_COMMIT_FILE"
        The status should equal 0
      End

      It 'Then: [正常] - returns false for comments-only file'
        echo "# Just a comment" > "$TEST_COMMIT_FILE"
        When call has_existing_message "$TEST_COMMIT_FILE"
        The status should equal 1
      End
    End
  End
End
