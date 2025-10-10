#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/integration/prepare-commit-msg-git.integration.spec.sh
# @(#): Integration tests for Git command operations
#
# @file prepare-commit-msg-git.integration.spec.sh
# @brief Integration tests for Git repository interactions
# @description
#   Tests make_context_block() function that executes Git commands.
#   Validates integration with git log and git diff operations.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - Git operations'
  # Source the actual script to get function definitions
  Include scripts/prepare-commit-msg.sh

  Describe 'make_context_block()'
    Context 'Given: Git repository with history'
      It 'Then: [正常] - outputs Git logs section'
        When call make_context_block
        The output should include "----- GIT LOGS -----"
        The output should include "----- END LOGS -----"
      End

      It 'Then: [正常] - outputs Git diff section'
        When call make_context_block
        The output should include "----- GIT DIFF -----"
        The output should include "----- END DIFF -----"
      End

      It 'Then: [正常] - contains log and diff in correct order'
        When call make_context_block
        The line 1 should equal "----- GIT LOGS -----"
        The output should include "----- END LOGS -----"
        The output should include "----- GIT DIFF -----"
      End
    End

    Context 'Given: checking output structure'
      It 'Then: [正常] - separates sections with blank line'
        When call make_context_block
        The output should include "$(printf -- "----- END LOGS -----\n\n----- GIT DIFF -----")"
      End
    End
  End
End
