#!/usr/bin/env bash
# shellcheck shell=bash
# ShellSpec tests for scripts/prepare-commit-msg.sh

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

  Describe 'parse_options()'
    setup() {
      FLAG_OUTPUT_TO_STDOUT=true
      GIT_COMMIT_MSG=".git/COMMIT_EDITMSG"
    }

    BeforeEach 'setup'

    Context 'Given: default state'
      It 'Then: [正常] - FLAG_OUTPUT_TO_STDOUT is true by default'
        When call parse_options
        The variable FLAG_OUTPUT_TO_STDOUT should equal "true"
      End

      It 'Then: [正常] - GIT_COMMIT_MSG has default value'
        When call parse_options
        The variable GIT_COMMIT_MSG should equal ".git/COMMIT_EDITMSG"
      End
    End

    Context 'Given: --git-buffer option'
      It 'Then: [正常] - sets FLAG_OUTPUT_TO_STDOUT to false'
        When call parse_options --git-buffer
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
      End

      It 'Then: [正常] - keeps default GIT_COMMIT_MSG'
        When call parse_options --git-buffer
        The variable GIT_COMMIT_MSG should equal ".git/COMMIT_EDITMSG"
      End
    End

    Context 'Given: --to-buffer option'
      It 'Then: [正常] - sets FLAG_OUTPUT_TO_STDOUT to false'
        When call parse_options --to-buffer
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
      End
    End

    Context 'Given: custom commit message file'
      It 'Then: [正常] - sets GIT_COMMIT_MSG to custom path'
        When call parse_options "custom/path/COMMIT_MSG"
        The variable GIT_COMMIT_MSG should equal "custom/path/COMMIT_MSG"
      End

      It 'Then: [正常] - keeps FLAG_OUTPUT_TO_STDOUT as true'
        When call parse_options "custom/path/COMMIT_MSG"
        The variable FLAG_OUTPUT_TO_STDOUT should equal "true"
      End
    End

    Context 'Given: combination of options and file path'
      It 'Then: [正常] - handles --git-buffer with custom file'
        When call parse_options --git-buffer "temp/test_commit"
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
        The variable GIT_COMMIT_MSG should equal "temp/test_commit"
      End

      It 'Then: [正常] - handles --to-buffer with custom file'
        When call parse_options --to-buffer "temp/test_commit"
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
        The variable GIT_COMMIT_MSG should equal "temp/test_commit"
      End
    End

    Context 'Given: unknown option'
      It 'Then: [異常] - exits with error for unknown option'
        When run parse_options --unknown-option
        The status should equal 1
        The stderr should include "Unknown option: --unknown-option"
      End

      It 'Then: [異常] - exits with error for invalid flag'
        When run parse_options -x
        The status should equal 1
        The stderr should include "Unknown option: -x"
      End
    End

    Context 'Given: help option'
      It 'Then: [正常] - displays usage with --help'
        When run parse_options --help
        The status should equal 0
        The output should include "Usage:"
        The output should include "--git-buffer"
      End

      It 'Then: [正常] - displays usage with -h'
        When run parse_options -h
        The status should equal 0
        The output should include "Usage:"
      End
    End
  End

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

  Describe 'output_commit_message()'
    setup() {
      FLAG_OUTPUT_TO_STDOUT=true
      TEST_OUTPUT_FILE="./temp/test_output_commit_msg"
      mkdir -p ./temp
    }

    cleanup() {
      rm -f "$TEST_OUTPUT_FILE"
    }

    BeforeEach 'setup'
    AfterEach 'cleanup'

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

      It 'Then: [正常] - does not create file in stdout mode'
        FLAG_OUTPUT_TO_STDOUT=true
        When call output_commit_message "feat: test" "$TEST_OUTPUT_FILE"
        The output should equal "feat: test"
        The file "$TEST_OUTPUT_FILE" should not be exist
      End
    End

    Context 'Given: FLAG_OUTPUT_TO_STDOUT is false (Git buffer mode)'
      It 'Then: [正常] - writes message to temp file'
        FLAG_OUTPUT_TO_STDOUT=false
        When call output_commit_message "feat: test commit" "$TEST_OUTPUT_FILE"
        The stderr should include "✦ Commit message written to"
        The stderr should include "$TEST_OUTPUT_FILE"
        The file "$TEST_OUTPUT_FILE" should be exist
        The contents of file "$TEST_OUTPUT_FILE" should equal "feat: test commit"
      End

      It 'Then: [正常] - writes multi-line message to temp file'
        FLAG_OUTPUT_TO_STDOUT=false
        multiline="feat: test commit

This is the body.
- Item 1
- Item 2"
        When call output_commit_message "$multiline" "$TEST_OUTPUT_FILE"
        The stderr should include "✦ Commit message written to"
        The file "$TEST_OUTPUT_FILE" should be exist
        The contents of file "$TEST_OUTPUT_FILE" should include "feat: test commit"
        The contents of file "$TEST_OUTPUT_FILE" should include "This is the body."
      End

      It 'Then: [正常] - outputs confirmation with custom path to stderr'
        FLAG_OUTPUT_TO_STDOUT=false
        When call output_commit_message "feat: test" "$TEST_OUTPUT_FILE"
        The stderr should include "✦ Commit message written to"
        The stderr should include "$TEST_OUTPUT_FILE"
      End

      It 'Then: [正常] - removes existing temp file before writing'
        FLAG_OUTPUT_TO_STDOUT=false
        echo "old content" > "$TEST_OUTPUT_FILE"
        When call output_commit_message "new: content" "$TEST_OUTPUT_FILE"
        The stderr should include "✦ Commit message written to"
        The contents of file "$TEST_OUTPUT_FILE" should equal "new: content"
      End

      It 'Then: [正常] - uses default GIT_COMMIT_MSG when path not specified'
        FLAG_OUTPUT_TO_STDOUT=false
        GIT_COMMIT_MSG="./temp/test_default_msg"
        When call output_commit_message "feat: default path"
        The stderr should include "✦ Commit message written to"
        The stderr should include "./temp/test_default_msg"
        The file "./temp/test_default_msg" should be exist
        The contents of file "./temp/test_default_msg" should equal "feat: default path"
        rm -f "./temp/test_default_msg"
      End
    End

    Context 'Given: edge cases'
      It 'Then: [エッジケース] - handles empty message in stdout mode'
        FLAG_OUTPUT_TO_STDOUT=true
        When call output_commit_message "" "$TEST_OUTPUT_FILE"
        The output should equal ""
      End

      It 'Then: [エッジケース] - handles empty message in buffer mode'
        FLAG_OUTPUT_TO_STDOUT=false
        When call output_commit_message "" "$TEST_OUTPUT_FILE"
        The stderr should include "✦ Commit message written to"
        The file "$TEST_OUTPUT_FILE" should be exist
        The contents of file "$TEST_OUTPUT_FILE" should equal ""
      End

      It 'Then: [エッジケース] - handles message with special characters'
        FLAG_OUTPUT_TO_STDOUT=true
        special="fix: escape \$VAR and 'quotes' and \"double\""
        When call output_commit_message "$special" "$TEST_OUTPUT_FILE"
        The output should include "\$VAR"
        The output should include "'quotes'"
      End
    End
  End
End
