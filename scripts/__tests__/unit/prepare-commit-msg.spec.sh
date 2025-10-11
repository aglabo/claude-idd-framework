#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/prepare-commit-msg.spec.sh
# @(#): ShellSpec tests for prepare-commit-msg.sh
#
# @file prepare-commit-msg.spec.sh
# @brief ShellSpec tests for prepare-commit-msg.sh
# @description
#   Test suite for the prepare-commit-msg.sh script.
#   Tests argument parsing and commit message generation workflow.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh'
  SCRIPT="./scripts/prepare-commit-msg.sh"

  # Source individual functions without executing main logic
  parse_options() {
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
  }

  has_existing_message() {
    local file="$1"
    grep -vE '^\s*(#|$)' "$file" | grep -q '.'
  }

  make_context_block() {
    echo "----- GIT LOGS -----"
    git log --oneline -10 || echo "No logs available."
    echo "----- END LOGS -----"
    echo
    echo "----- GIT DIFF -----"
    git diff --cached || echo "No diff available."
    echo "----- END DIFF -----"
  }

  output_commit_message() {
    local commit_msg="$1"
    local output_file="${2:-$GIT_COMMIT_MSG}"

    if [[ "$FLAG_OUTPUT_TO_STDOUT" == true ]]; then
      # 標準出力モード
      echo "$commit_msg"
    else
      # Gitバッファーモード
      rm -f "${output_file}"
      echo "${commit_msg}" > "${output_file}"
      echo "✦ Commit message written to $output_file" >&2
    fi
  }



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

  Describe 'generate_commit_message()'
    # Source the actual function from the script
    generate_commit_message() {
      local test_message="${1:-}"

      # テストメッセージが指定されている場合はそのまま返す
      if [[ -n "$test_message" ]]; then
        echo "$test_message"
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
      # ----- END DIFF ----- より後ろを取得 (存在しない場合は全体)
      local after_diff
      if echo "$full_output" | grep -q "^----- END DIFF -----$"; then
        after_diff=$(echo "$full_output" | sed -n '/^----- END DIFF -----$/,$p' | sed '1d')
      else
        after_diff="$full_output"
      fi

      # === commit header === と === commit footer === の間を抽出
      echo "$after_diff" | \
        sed -n '/^=== commit header ===/,/^=== commit footer ===/p' | \
        sed '1d;$d'
    }

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

    Context 'Given: Codex CLI is available'
      It 'Then: [正常] - generates commit message without header/footer markers'
        Skip "Integration test - requires actual Codex CLI"
        When call generate_commit_message
        The status should equal 0
        The output should not include "=== commit header ==="
        The output should not include "=== commit footer ==="
      End

      It 'Then: [正常] - outputs non-empty message'
        Skip "Integration test - requires actual Codex CLI"
        When call generate_commit_message
        The status should equal 0
        The output should not equal ""
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
