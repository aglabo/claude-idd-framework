#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/integration/prepare-commit-msg-generate.integration.spec.sh
# @(#): Integration tests for commit message generation logic
#
# @file prepare-commit-msg-generate.integration.spec.sh
# @brief Integration tests for message generation and parsing
# @description
#   Tests generate_commit_message() function with mock data and parsing logic.
#   Validates message extraction from formatted output without actual Codex calls.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - Message generation'
  # Source the actual script to get function definitions
  Include scripts/prepare-commit-msg.sh

  Describe 'generate_commit_message()'
    Context 'Given: test_message parameter is provided'
      It 'Then: [正常] - returns test message directly without calling codex'
        When call generate_commit_message "test: mock commit message"
        The output should equal "test: mock commit message"
        The status should equal 0
      End

      It 'Then: [正常] - handles multi-line test messages'
        multiline_msg="feat: add new feature

This is a detailed description."
        When call generate_commit_message "$multiline_msg"
        The line 1 should equal "feat: add new feature"
        The line 2 should equal ""
        The line 3 should equal "This is a detailed description."
        The status should equal 0
      End

      It 'Then: [正常] - handles Conventional Commits format'
        conventional_msg="fix(core): resolve memory leak

- Fixed buffer overflow in parser
- Added bounds checking

Closes #456"
        When call generate_commit_message "$conventional_msg"
        The output should include "fix(core): resolve memory leak"
        The output should include "Fixed buffer overflow"
        The output should include "Closes #456"
        The status should equal 0
      End
    End

    Context 'Given: parsing logic verification'
      generate_commit_message_mock() {
        local full_output
        full_output=$(cat << 'EOF'
Some preamble text
----- END DIFF -----
Extra line
=== commit header ===
feat(core): implement new feature

This is the commit body.

Refs: #123
=== commit footer ===
Some trailing text
EOF
        )

        # Apply same parsing logic as generate_commit_message()
        local after_diff
        if echo "$full_output" | grep -q "^----- END DIFF -----$"; then
          after_diff=$(echo "$full_output" | sed -n '/^----- END DIFF -----$/,$p' | sed '1d')
        else
          after_diff="$full_output"
        fi

        echo "$after_diff" | \
          sed -n '/^=== commit header ===/,/^=== commit footer ===/p' | \
          sed '1d;$d'
      }

      It 'Then: [正常] - extracts only message between markers'
        When call generate_commit_message_mock
        The line 1 should equal "feat(core): implement new feature"
        The output should include "This is the commit body."
        The output should include "Refs: #123"
        The output should not include "=== commit header ==="
        The output should not include "=== commit footer ==="
        The output should not include "Some preamble text"
        The output should not include "Some trailing text"
      End

      generate_commit_message_without_diff_marker() {
        local full_output
        full_output=$(cat << 'EOF'
=== commit header ===
fix(test): handle codex output without diff markers

This handles the case when codex output doesn't include
the END DIFF marker.

Refs: #789
=== commit footer ===
EOF
        )

        # Apply same parsing logic as generate_commit_message()
        local after_diff
        if echo "$full_output" | grep -q "^----- END DIFF -----$"; then
          after_diff=$(echo "$full_output" | sed -n '/^----- END DIFF -----$/,$p' | sed '1d')
        else
          after_diff="$full_output"
        fi

        echo "$after_diff" | \
          sed -n '/^=== commit header ===/,/^=== commit footer ===/p' | \
          sed '1d;$d'
      }

      It 'Then: [正常] - handles output without END DIFF marker'
        When call generate_commit_message_without_diff_marker
        The line 1 should equal "fix(test): handle codex output without diff markers"
        The output should include "This handles the case when codex output"
        The output should include "Refs: #789"
        The output should not include "=== commit header ==="
        The output should not include "=== commit footer ==="
      End
    End
  End
End
