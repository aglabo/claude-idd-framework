#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/idd-issue-branch-functions.lib.sh
# @(#): Test mock functions for /idd:issue:branch command
#
# @file idd-issue-branch-functions.lib.sh
# @brief Provides mock functions for testing branch.md implementation
# @description
#   This library contains mock functions to replace external dependencies
#   during unit and integration tests. The actual implementation functions
#   are now located in branch.md and can be sourced from there.
#
#   Mock functions:
#   - mock_codex_mcp: Mocks Codex-MCP inference behavior
#   - setup_branch_functions: Test setup helper
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/idd-issue-branch-functions.lib.sh
#   setup_branch_functions
#
# @author atsushifx
# @version 2.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Setup Function
# =============================================================================

##
# @description Setup test environment by sourcing branch.md implementation
# @noargs
# @exitcode 0 Always successful
##
setup_branch_functions() {
  # Source the actual implementation from branch.md
  local repo_root
  repo_root=$(git rev-parse --show-toplevel)

  # Load required libraries
  . "$repo_root/.claude/commands/_libs/io-utils.lib.sh"
  . "$repo_root/.claude/commands/_libs/filename-utils.lib.sh"
  . "$repo_root/.claude/commands/_libs/idd-session.lib.sh"

  # Extract and source shell functions from branch.md
  local branch_md="$repo_root/.claude/commands/idd/issue/branch.md"

  # Extract bash code blocks from Script Library section using awk
  # Create temporary file to avoid stdin sourcing issues
  BRANCH_FUNCTIONS_TEMP_SCRIPT="${TMPDIR:-/tmp}/branch-functions-$$.sh"
  sed -n '/^## スクリプトライブラリ/,/^## License$/p' "$branch_md" | \
    awk '/^```bash$/ {flag=1; next} /^```$/ {flag=0; next} flag' > "$BRANCH_FUNCTIONS_TEMP_SCRIPT"

  # Source the extracted functions
  . "$BRANCH_FUNCTIONS_TEMP_SCRIPT"

  return 0
}

##
# @description Cleanup test environment by removing temporary script
# @noargs
# @exitcode 0 Always successful
##
cleanup_branch_functions() {
  if [ -n "$BRANCH_FUNCTIONS_TEMP_SCRIPT" ] && [ -f "$BRANCH_FUNCTIONS_TEMP_SCRIPT" ]; then
    rm -f "$BRANCH_FUNCTIONS_TEMP_SCRIPT"
  fi
  return 0
}

# =============================================================================
# Mock Functions
# =============================================================================

##
# @brief Mock Codex-MCP command for testing
# @description Simulates Codex-MCP behavior without actual API calls
# @param --prompt Prompt string (contains title and issue type)
# @return 0 on success, 1 on failure (based on prompt content)
# @stdout Mocked domain inference result
# @example
#   result=$(mock_codex_mcp --prompt "Title: Add feature, Type: feature")
##
mock_codex_mcp() {
  local prompt=""

  # Parse --prompt argument
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt)
        prompt="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  # Extract title from prompt (simplified pattern matching)
  if [[ "$prompt" =~ \"([^\"]+)\" ]]; then
    local title="${BASH_REMATCH[1]}"

    # Simple domain inference based on keywords
    case "$title" in
      *"/idd-issue"*|*"claude-commands"*)
        echo "claude-commands"
        return 0
        ;;
      *"xcp.sh"*|*"scripts"*)
        echo "scripts"
        return 0
        ;;
      *"README"*|*"docs"*)
        echo "docs"
        return 0
        ;;
      *"Add"*|*"Implement"*)
        echo "feature"
        return 0
        ;;
      *"Fix"*)
        echo "bugfix"
        return 0
        ;;
      *)
        # Unknown case - simulate failure
        return 1
        ;;
    esac
  fi

  # No title found - simulate failure
  return 1
}

# =============================================================================
# Mock Command Alias
# =============================================================================

##
# @brief Alias 'claude' command to mock_codex_mcp for tests
# @description This allows tests to use "claude mcp__codex-mcp__codex --prompt ..."
#   which will be intercepted by the mock function
# @note This should be set up in test environment before running tests
##
claude() {
  if [[ "$1" == "mcp__codex-mcp__codex" ]]; then
    shift
    mock_codex_mcp "$@"
  else
    # Fallback to actual claude command (if needed)
    command claude "$@"
  fi
}
