#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/test-setup.lib.sh
# @(#): Common test setup and teardown helpers
#
# @file test-setup.lib.sh
# @brief Provides common test setup and cleanup functions
# @description
#   This library provides reusable setup and teardown functions for tests.
#   Includes environment initialization, cleanup, and mock state management.
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/test-setup.lib.sh
#   . .claude/commands/__tests__/__helpers/gh-mocks.lib.sh
#   . .claude/commands/__tests__/__helpers/idd-session-mocks.lib.sh
#
#   BeforeAll 'setup_test_environment'
#   AfterAll 'cleanup_test_environment'
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Dependencies
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"

# Source idd-session.lib.sh for _save_session function
# shellcheck disable=SC1091
. "$PROJECT_ROOT/.claude/commands/_libs/idd-session.lib.sh"

# =============================================================================
# Environment Setup Functions
# =============================================================================

##
# @description Setup test environment with temp directories and session files
# @noargs
# @global ISSUES_DIR Created temporary issues directory
# @global SESSION_FILE Session file path
# @exitcode 0 Always successful
setup_test_env() {
  # Create temp directories
  ISSUES_DIR=$(mktemp -d)
  SESSION_FILE="$ISSUES_DIR/.last.session"

  # Reset all mock variables
  reset_all_mock_state

  # Reset global variables
  unset filename issue_number issue_file TITLE title body new_filename
  unset saved_session_filename saved_session_issue_number saved_session_command
}

##
# @description Clean up test environment
# @noargs
# @global ISSUES_DIR Issues directory to remove
# @exitcode 0 Always successful
cleanup_test_env() {
  if [[ -n "${ISSUES_DIR:-}" && -d "$ISSUES_DIR" ]]; then
    rm -rf "$ISSUES_DIR"
  fi
}

# =============================================================================
# Mock State Management
# =============================================================================

##
# @description Reset all mock state variables to defaults
# @noargs
# @exitcode 0 Always successful
reset_all_mock_state() {
  # Reset gh mock state
  if declare -F reset_gh_mock_state &>/dev/null; then
    reset_gh_mock_state
  fi

  # Reset IDD session mock state
  if declare -F reset_idd_session_mock_state &>/dev/null; then
    reset_idd_session_mock_state
  fi

  # Additional resets for test-specific variables
  mock_gh_not_found=0
  mock_new_issue_number=42
}

# =============================================================================
# Convenience Setup Functions
# =============================================================================

##
# @description Setup complete test environment with all mocks
# @noargs
# @exitcode 0 Always successful
# @example
#   BeforeAll 'setup_complete_test_environment'
setup_complete_test_environment() {
  setup_test_env

  # Setup all mocks if their setup functions are available
  if declare -F setup_gh_mock &>/dev/null; then
    setup_gh_mock
  fi

  if declare -F setup_idd_session_mocks &>/dev/null; then
    setup_idd_session_mocks
  fi

  if declare -F setup_push_functions &>/dev/null; then
    setup_push_functions
  fi

  if declare -F setup_main_routine &>/dev/null; then
    setup_main_routine
  fi
}

##
# @description Alias for setup_test_env (for compatibility)
# @noargs
# @exitcode 0 Always successful
setup_test_environment() {
  setup_test_env
}

##
# @description Alias for cleanup_test_env (for compatibility)
# @noargs
# @exitcode 0 Always successful
cleanup_test_environment() {
  cleanup_test_env
}

# =============================================================================
# Per-Test Reset Functions
# =============================================================================

##
# @description Reset environment for each test (use in BeforeEach)
# @noargs
# @exitcode 0 Always successful
reset_for_each_test() {
  reset_all_mock_state

  # Ensure ISSUES_DIR exists
  if [[ -n "${ISSUES_DIR:-}" ]]; then
    mkdir -p "$ISSUES_DIR"
  fi
}

# =============================================================================
# Session File Creation Helpers
# =============================================================================

##
# @description Create .last.session file with standard fields
# @arg $1 string Session file path
# @arg $2 string (optional) LAST_BRANCH_NAME value (omit to exclude field)
# @global None
# @exitcode 0 Always successful
# @example
#   create_test_last_session "$TEST_SESSION_FILE"
#   create_test_last_session "$TEST_SESSION_FILE" "feat-27/test"
create_test_last_session() {
  local session_file="$1"
  local branch_name="${2:-}"

  # Build session data as associative array
  declare -A session_data=(
    [LAST_ISSUE_FILE]="issue-027-add-feature.md"
    [LAST_ISSUE_NUMBER]="027"
    [LAST_COMMAND]="new"
    [LAST_ISSUE_TITLE]="Add new feature"
    [LAST_ISSUE_TYPE]="feature"
    [LAST_COMMIT_TYPE]="feat"
    [LAST_BRANCH_TYPE]="feat"
  )

  # Add LAST_BRANCH_NAME if provided
  if [[ -n "$branch_name" ]]; then
    session_data[LAST_BRANCH_NAME]="$branch_name"
  fi

  # Use _save_session with fixed timestamp for reproducible tests
  _save_session "$session_file" session_data "2025-10-26T10:00:00+09:00"
}

##
# @description Create .branch.session file
# @arg $1 string Session file path
# @arg $2 string suggested_branch value
# @arg $3 string (optional) domain value (default: "test")
# @arg $4 string (optional) base_branch value (default: "main")
# @global None
# @exitcode 0 Always successful
# @example
#   create_test_branch_session "$TEST_SESSION_FILE" "feat-27/test"
#   create_test_branch_session "$TEST_SESSION_FILE" "feat-27/custom" "custom-domain" "develop"
create_test_branch_session() {
  local session_file="$1"
  local suggested_branch="$2"
  local domain="${3:-test}"
  local base_branch="${4:-main}"
  local issue_number

  # Extract issue number from suggested_branch (e.g., "feat-27/test" -> "27")
  if [[ "$suggested_branch" =~ -([0-9]+)/ ]]; then
    issue_number="${BASH_REMATCH[1]}"
  else
    issue_number="27"  # Default fallback
  fi

  # Build session data as associative array (matching save_branch_session format)
  declare -A session_data=(
    [suggested_branch]="$suggested_branch"
    [domain]="$domain"
    [base_branch]="$base_branch"
    [issue_number]="$issue_number"
  )

  # Use _save_session with fixed timestamp for reproducible tests
  _save_session "$session_file" session_data "2025-10-26T14:00:00+09:00"
}
