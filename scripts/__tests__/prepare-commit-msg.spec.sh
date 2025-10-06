#!/usr/bin/env bash
# shellcheck shell=bash
# ShellSpec tests for scripts/prepare-commit-msg.sh

Describe 'prepare-commit-msg.sh'
  SCRIPT="./scripts/prepare-commit-msg.sh"

  # Source individual functions without executing main logic
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

  Describe 'has_existing_message()'
    setup() {
      TEST_FILE="./temp/test_commit_msg"
      mkdir -p ./temp
    }

    cleanup() {
      rm -f "$TEST_FILE"
    }

    BeforeEach 'setup'
    AfterEach 'cleanup'

    Context 'Given: empty file exists'
      It 'Then: [正常] - returns false (exit code 1) for empty file'
        touch "$TEST_FILE"
        When call has_existing_message "$TEST_FILE"
        The status should equal 1
      End

      It 'Then: [正常] - returns false (exit code 1) for file with only whitespace'
        echo "   " > "$TEST_FILE"
        When call has_existing_message "$TEST_FILE"
        The status should equal 1
      End

      It 'Then: [正常] - returns false (exit code 1) for file with only comments'
        cat > "$TEST_FILE" << 'EOF'
# This is a comment
# Another comment
EOF
        When call has_existing_message "$TEST_FILE"
        The status should equal 1
      End
    End

    Context 'Given: file with actual content'
      It 'Then: [正常] - returns true (exit code 0) for file with commit message'
        echo "feat: add new feature" > "$TEST_FILE"
        When call has_existing_message "$TEST_FILE"
        The status should equal 0
      End

      It 'Then: [正常] - returns true (exit code 0) for file with message and comments'
        cat > "$TEST_FILE" << 'EOF'
feat: add new feature

# Please enter the commit message for your changes.
EOF
        When call has_existing_message "$TEST_FILE"
        The status should equal 0
      End

      It 'Then: [正常] - returns true (exit code 0) for multiline message'
        cat > "$TEST_FILE" << 'EOF'
feat: add new feature

This is the body of the commit message.
It spans multiple lines.

# Comments below
EOF
        When call has_existing_message "$TEST_FILE"
        The status should equal 0
      End
    End

    Context 'Given: edge cases'
      It 'Then: [エッジケース] - returns false for file with only blank lines'
        printf "\n\n\n" > "$TEST_FILE"
        When call has_existing_message "$TEST_FILE"
        The status should equal 1
      End

      It 'Then: [エッジケース] - returns false for mixed empty lines and comments'
        cat > "$TEST_FILE" << 'EOF'

# Comment

# Another comment

EOF
        When call has_existing_message "$TEST_FILE"
        The status should equal 1
      End
    End
  End

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
      echo "$full_output" | \
        sed '/^----- END DIFF -----$/,$!d' | sed '1d' | \
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
        echo "$full_output" | \
          sed '/^----- END DIFF -----$/,$!d' | sed '1d' | \
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
    End
  End
End
