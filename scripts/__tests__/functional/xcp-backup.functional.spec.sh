#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/functional/xcp-backup.functional.spec.sh
# @(#): ShellSpec functional tests for xcp.sh backup operations
#
# @file xcp-backup.functional.spec.sh
# @brief ShellSpec functional tests for xcp.sh backup operations
# @description
#   Functional test suite for xcp.sh backup functionality.
#   Tests backup file creation with timestamp, dry-run mode, and error handling.
#
#   Test framework: ShellSpec
#   BDD hierarchy: Given (feature) → When (action) → Then (expected result)
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'xcp.sh - Backup operations'
  SCRIPT="./scripts/xcp.sh"

  # Load xcp.sh once for all tests
  BeforeAll '. "$SCRIPT" 2>/dev/null || true'

  # Reset variables before each test
  BeforeEach 'init_variables'

  # ============================================================================
  # Given: backup_file function
  # ============================================================================

  Describe 'Given: backup_file function'
    setup_backup() {
      :
    }

    BeforeEach 'setup_backup'

    Describe 'When: Performing backups'
      It 'Then: [正常] - Emit dry-run backup command'
        FLAG_DRY_RUN=1
        target_file=$(mktemp)
        echo "content" > "$target_file"

        When call backup_file "$target_file"

        The status should be success
        The output should match pattern "*[[]DRY-RUN[]] mv *bak.*"
        The path "$target_file" should be file

        rm -f "$target_file"
        FLAG_DRY_RUN=0
      End

      It 'Then: [正常] - Create timestamped backup file'
        target_file=$(mktemp)
        echo "backup-data" > "$target_file"

        When call backup_file "$target_file"

        The status should be success
        backup_path=$(echo "$target_file".bak.*)
        The path "$backup_path" should be file
        The output should include "Backed up:"

        exist_flag=0
        [[ -e "$target_file" ]] && exist_flag=1
        The value "$exist_flag" should equal "0"

        rm -f "$backup_path"
      End

      backup_failure() {
        mv() { return 1; }
        backup_file "$1"
        local status=$?
        unset -f mv
        return $status
      }

      It 'Then: [異常] - Log error when backup fails'
        target_file=$(mktemp)
        echo "fail" > "$target_file"

        When call backup_failure "$target_file"

        The status should be failure
        The error should include "Failed to backup"
        The result of function logger_get_error_count should equal 1

        rm -f "$target_file"
      End
    End
  End
End
