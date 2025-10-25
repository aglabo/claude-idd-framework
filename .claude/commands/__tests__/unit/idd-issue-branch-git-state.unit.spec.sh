#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/unit/idd-issue-branch-git-state.unit.spec.sh
# @(#): Unit tests for /idd:issue:branch Git state validation (T9) and branch existence check (T10)
#
# @file idd-issue-branch-git-state.unit.spec.sh
# @brief Unit tests for validate_git_state() and check_branch_exists() functions (T9, T10)
# @description
#   Unit test suite for Git state validation and branch existence checking in /idd:issue:branch command.
#   Tests cover all BDD verification items from tasks.md T9 and T10.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#   Test approach: Direct function calls with mocked git commands
#
#   Covered functionality:
#   - T9-1: Clean working directory returns 0
#   - T9-2: Uncommitted changes returns 1 with error message
#   - T9-3: Untracked files only returns 0 (allowed)
#   - T10-1: Branch does not exist returns 1
#   - T10-2: Branch exists returns 0
#   - T10-3: Commit error handling when branch already exists
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

PROJECT_ROOT="${PROJECT_ROOT:-${SHELLSPEC_PROJECT_ROOT:-$(pwd)}}"
HELPERS_DIR="$PROJECT_ROOT/.claude/commands/__tests__/__helpers"
. "$HELPERS_DIR/idd-issue-branch-functions.lib.sh"

# Setup branch functions from branch.md
setup_branch_functions

# Cleanup temporary files after all tests
AfterAll 'cleanup_branch_functions'

Describe 'validate_git_state() - T9 Git state validation'

  # ============================================================================
  # T9-1: クリーンな作業ディレクトリ
  # ============================================================================

  Describe 'Given: Git repository with no uncommitted changes'
    Context 'When: validate_git_state() is called'
      It 'Then: [正常] - should return 0 with no message'
        # Arrange: Mock git status to return empty (clean state)
        git() {
          if [ "$1" = "status" ] && [ "$2" = "--porcelain" ]; then
            echo ""  # Clean working directory
          else
            command git "$@"
          fi
        }

        # Act
        When call validate_git_state

        # Assert
        The status should be success
        The output should be blank
      End
    End
  End

  # ============================================================================
  # T9-2: 未コミット変更あり
  # ============================================================================

  Describe 'Given: Git repository with uncommitted changes'
    Context 'When: validate_git_state() is called'
      It 'Then: [異常] - should return 1 with error message'
        # Arrange: Mock git status to return modified files
        git() {
          if [ "$1" = "status" ] && [ "$2" = "--porcelain" ]; then
            echo " M .claude/commands/idd/issue/branch.md"  # Modified file
            echo "A  new-file.txt"  # Added file
          else
            command git "$@"
          fi
        }

        # Act
        When call validate_git_state

        # Assert
        The status should be failure
        The output should include "Uncommitted changes detected"
        The output should include "git status"
        The output should include "git commit"
      End
    End
  End

  # ============================================================================
  # T9-3: 未追跡ファイルのみ
  # ============================================================================

  Describe 'Given: Git repository with only untracked files'
    Context 'When: validate_git_state() is called'
      It 'Then: [正常] - should return 0 (untracked files allowed)'
        # Arrange: Mock git status to return only untracked files
        git() {
          if [ "$1" = "status" ] && [ "$2" = "--porcelain" ]; then
            echo "?? new-untracked-file.txt"  # Untracked file
            echo "?? temp/file.tmp"  # Another untracked file
          else
            command git "$@"
          fi
        }

        # Act
        When call validate_git_state

        # Assert
        The status should be success
        The output should be blank
      End
    End
  End

End

Describe 'check_branch_exists() - T10 Branch existence check'

  # ============================================================================
  # T10-1: ブランチ不存在
  # ============================================================================

  Describe 'Given: Branch "feat-27/test" does not exist'
    Context 'When: check_branch_exists("feat-27/test") is called'
      It 'Then: [正常] - should return 1 (not found)'
        # Arrange: Mock git rev-parse to return error (branch not found)
        git() {
          if [ "$1" = "rev-parse" ] && [ "$2" = "--verify" ]; then
            return 1  # Branch does not exist
          else
            command git "$@"
          fi
        }

        # Act
        When call check_branch_exists "feat-27/test"

        # Assert
        The status should be failure
      End
    End
  End

  # ============================================================================
  # T10-2: ブランチ存在
  # ============================================================================

  Describe 'Given: Branch "main" exists'
    Context 'When: check_branch_exists("main") is called'
      It 'Then: [正常] - should return 0 (found)'
        # Arrange: Mock git rev-parse to return success (branch exists)
        git() {
          if [ "$1" = "rev-parse" ] && [ "$2" = "--verify" ]; then
            return 0  # Branch exists
          else
            command git "$@"
          fi
        }

        # Act
        When call check_branch_exists "main"

        # Assert
        The status should be success
      End
    End
  End

  # ============================================================================
  # T10-3: ブランチ既存エラー (subcommand_commit統合)
  # ============================================================================

  Describe 'Given: Branch already exists when committing'
    Context 'When: commit logic checks branch existence'
      It 'Then: [異常] - should show error and return code 5'
        # Arrange: Mock git rev-parse to return success (branch exists)
        git() {
          if [ "$1" = "rev-parse" ] && [ "$2" = "--verify" ]; then
            return 0  # Branch exists (conflict)
          else
            command git "$@"
          fi
        }

        # Simulate commit logic that checks for existing branch
        test_commit_branch_check() {
          local suggested_branch="feat-27/existing-branch"

          if check_branch_exists "$suggested_branch"; then
            echo "❌ Branch already exists: $suggested_branch"
            echo "💡 Switch to existing branch or use a different name:"
            echo "   - git switch $suggested_branch"
            return 5
          fi

          echo "Creating branch..."
          return 0
        }

        # Act
        When call test_commit_branch_check

        # Assert
        The status should equal 5
        The output should include "Branch already exists"
        The output should include "git switch"
      End
    End
  End

End
