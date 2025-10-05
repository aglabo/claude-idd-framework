#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/xcp-utils.spec.sh
# @(#): ShellSpec unit tests for xcp.sh utility functions
#
# @file xcp-utils.spec.sh
# @brief ShellSpec unit tests for xcp.sh utility functions
# @description
#   Unit test suite for xcp.sh utility functions including:
#   - Initialization functions (init_variables)
#   - Validation functions (validate_source, check_destination_directory)
#   - Directory handling (create_destination_directory)
#   - Timestamp operations (get_timestamp, get_mtime, is_newer, backup_file)
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

Describe 'xcp.sh - Utility Functions Unit Tests'
  SCRIPT="./scripts/xcp.sh"

  # ============================================================================
  # Given: Initialization Functions
  # ============================================================================

  Describe 'Given: Initialization function (init_variables)'
    Describe 'When: Calling init_variables to reset state'
      It 'Then: [正常] - Reset all variables to default values'
        # Arrange: Source script and modify some variables
        . "$SCRIPT" 2>/dev/null || true
        OPERATION_MODE=999
        FLAG_DRY_RUN=1
        FLAG_RECURSIVE=1

        # Act: Call init_variables to reset
        When call init_variables

        # Assert: All variables should be reset to defaults
        The variable OPERATION_MODE should equal "$MODE_SKIP"
        The variable FLAG_DRY_RUN should equal 0
        The variable FLAG_RECURSIVE should equal 0
        The variable FLAG_PARENTS should equal 0
        The variable FLAG_DEREFERENCE should equal 0
        The variable FLAG_FAIL_FAST should equal 0
        The variable FLAG_ABORT_REQUESTED should equal 0
        The status should be success
      End

      It 'Then: [正常] - Reinitialize logger by calling logger_init'
        # Arrange: Source script and log some errors
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        log_error "Test error" 2>/dev/null
        error_count_before=$(logger_get_error_count)

        # Act: Call init_variables
        When call init_variables

        # Assert: Logger should be reinitialized (error count reset to 0)
        error_count_after=$(logger_get_error_count)
        The variable error_count_after should equal 0
        The status should be success
      End

      It 'Then: [正常] - Clear SOURCE_ARGS and DEST_ARG arrays'
        # Arrange: Source script and set argument arrays
        . "$SCRIPT" 2>/dev/null || true
        SOURCE_ARGS=("file1" "file2")
        DEST_ARG="/dest/path"

        # Act: Call init_variables
        When call init_variables

        # Assert: Arrays should be cleared
        The value "${#SOURCE_ARGS[@]}" should equal 0
        The variable DEST_ARG should equal ""
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: Validation Functions
  # ============================================================================

  Describe 'Given: Validation function (validate_source)'
    Describe 'When: Validating source file or directory'
      It 'Then: [正常] - Return success when source exists and is readable'
        # Arrange: Create a temporary readable file
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_file=$(mktemp)
        chmod 644 "$test_file"

        # Act: Call validate_source
        When call validate_source "$test_file"

        # Assert: Should return success
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [異常] - Return failure and log error when source does not exist'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call validate_source with nonexistent path
        When call validate_source "/nonexistent/path/to/file.txt"

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "Source not found"
        The result of function logger_get_error_count should equal 1
      End

      It 'Then: [異常] - Return failure and log error when source is not readable'
        Skip "Permission tests not reliable on Windows/Git Bash"

        # Arrange: Create unreadable file
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_file=$(mktemp)
        chmod 000 "$test_file"

        # Act: Call validate_source
        When call validate_source "$test_file"

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "Source not readable"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        chmod 644 "$test_file"
        rm -f "$test_file"
      End

      It 'Then: [エッジケース] - Handle empty source path'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call validate_source with empty string
        When call validate_source ""

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "Source not found"
      End

      It 'Then: [エッジケース] - Handle paths with spaces correctly'
        # Arrange: Create file with spaces
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_dir=$(mktemp -d)
        test_file="$test_dir/test file with spaces.txt"
        echo "content" > "$test_file"

        # Act: Call validate_source
        When call validate_source "$test_file"

        # Assert: Should handle spaces correctly
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End
    End
  End

  Describe 'Given: Validation function (check_destination_directory)'
    Describe 'When: Validating destination directory'
      It 'Then: [正常] - Return 0 when directory exists and is writable'
        # Arrange: Create writable directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_dir=$(mktemp -d)

        # Act: Call check_destination_directory
        When call check_destination_directory "$test_dir"

        # Assert: Should return 0
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [異常] - Return 1 when directory exists but not writable'
        Skip "Permission tests not reliable on Windows/Git Bash"

        # Arrange: Create non-writable directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_dir=$(mktemp -d)
        chmod 555 "$test_dir"

        # Act: Call check_destination_directory
        When call check_destination_directory "$test_dir"

        # Assert: Should return 1 and log error
        The status should be failure
        The error should include "not writable"

        # Cleanup
        chmod 755 "$test_dir"
        rm -rf "$test_dir"
      End

      It 'Then: [異常] - Return 1 when path exists but is not a directory'
        # Arrange: Create a file (not directory)
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_file=$(mktemp)

        # Act: Call check_destination_directory with file path
        When call check_destination_directory "$test_file"

        # Assert: Should return 1 and log error
        The status should be failure
        The error should include "not a directory"

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [正常] - Return 2 when directory does not exist'
        # Arrange: Use nonexistent directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_dir=$(mktemp -d)
        nonexistent_dir="$test_dir/nonexistent"
        rm -rf "$test_dir"

        # Act: Call check_destination_directory
        result=0
        check_destination_directory "$nonexistent_dir" || result=$?

        # Assert: Should return 2
        When call bash -c "exit $result"

        The status should equal 2
      End

      It 'Then: [エッジケース] - Handle empty destination path'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call check_destination_directory with empty string
        When call check_destination_directory ""

        # Assert: Should return 1 and log error
        The status should be failure
        The error should include "empty"
      End
    End
  End

  # ============================================================================
  # Given: Directory Handling Functions
  # ============================================================================

  Describe 'Given: Directory handling function (create_destination_directory)'
    Describe 'When: Creating destination directory'
      It 'Then: [正常] - Return success when directory already exists'
        # Arrange: Create existing directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_dir=$(mktemp -d)

        # Act: Call create_destination_directory
        When call create_destination_directory "$test_dir"

        # Assert: Should return success
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [正常] - Create parent directories when FLAG_PARENTS=1'
        # Arrange: Set FLAG_PARENTS=1
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        base_dir=$(mktemp -d)
        target_dir="$base_dir/nested/subdir"
        rm -rf "$base_dir"

        # Act: Call create_destination_directory
        When call create_destination_directory "$target_dir"

        # Assert: Should create directory and return success
        The status should be success
        The path "$target_dir" should be directory
        The output should include "[INFO] Created directory"

        # Cleanup
        rm -rf "$base_dir"
      End

      It 'Then: [異常] - Return failure when FLAG_PARENTS=0 and directory does not exist'
        # Arrange: Set FLAG_PARENTS=0
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=0
        test_dir=$(mktemp -d)
        nonexistent_dir="$test_dir/nonexistent"
        rm -rf "$test_dir"

        # Act: Call create_destination_directory
        When call create_destination_directory "$nonexistent_dir"

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "does not exist"
        The error should include "use -p to create"
      End

      It 'Then: [正常] - Emit dry-run log when FLAG_DRY_RUN=1'
        # Arrange: Set FLAG_DRY_RUN=1 and FLAG_PARENTS=1
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DRY_RUN=1
        FLAG_PARENTS=1
        base_dir=$(mktemp -d)
        target_dir="$base_dir/dry-run/dir"

        # Act: Call create_destination_directory
        When call create_destination_directory "$target_dir"

        # Assert: Should output dry-run log and not create directory
        The status should be success
        The output should include "[DRY-RUN] mkdir -p"
        The path "$target_dir" should not exist

        # Cleanup
        rm -rf "$base_dir"
        FLAG_DRY_RUN=0
      End

      It 'Then: [エッジケース] - Handle empty destination path'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call create_destination_directory with empty string
        When call create_destination_directory ""

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "empty"
      End

      It 'Then: [異常] - Return failure when path exists but is not a directory'
        # Arrange: Create a file (not directory)
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        test_file=$(mktemp)

        # Act: Call create_destination_directory with file path
        When call create_destination_directory "$test_file"

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "not a directory"

        # Cleanup
        rm -f "$test_file"
      End
    End
  End

  # ============================================================================
  # Given: Timestamp Operations Functions
  # ============================================================================

  Describe 'Given: Timestamp function (get_timestamp)'
    Describe 'When: Getting current timestamp'
      It 'Then: [正常] - Return timestamp in YYMMDDHHMMSS format'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true

        # Act: Call get_timestamp
        When call get_timestamp

        # Assert: Should return 12-digit timestamp
        The output should match pattern "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
        The status should be success
      End

      It 'Then: [正常] - Match date command output format'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true

        # Act: Get timestamp from function and date command
        timestamp=$(get_timestamp)
        expected=$(date +%y%m%d%H%M%S)

        # Assert: Should match (allowing 1 second difference)
        When call bash -c "[[ '$timestamp' == '$expected' ]] || [[ $(( ${timestamp##*[!0-9]} - ${expected##*[!0-9]} )) -le 1 ]]"

        The status should be success
      End
    End
  End

  Describe 'Given: File modification time function (get_mtime)'
    Describe 'When: Getting file modification time'
      It 'Then: [正常] - Return Unix timestamp using stat command'
        # Arrange: Create test file
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)
        touch "$test_file"

        # Act: Call get_mtime
        When call get_mtime "$test_file"

        # Assert: Should return Unix timestamp
        The output should match pattern "[0-9][0-9]*"
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [正常] - Fallback to BSD stat when GNU stat fails'
        # Arrange: Create test file and mock stat
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)
        touch "$test_file"
        expected_mtime=$(command stat -c %Y "$test_file" 2>/dev/null)

        # Mock stat to force BSD fallback
        stat() {
          if [[ "$1" == "-c" ]]; then
            return 1
          elif [[ "$1" == "-f" ]]; then
            echo "$expected_mtime"
            return 0
          else
            command stat "$@"
          fi
        }

        # Act: Call get_mtime
        When call get_mtime "$test_file"

        # Assert: Should return mtime from BSD stat
        The output should equal "$expected_mtime"
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [異常] - Return empty string when stat command unavailable'
        # Arrange: Mock command to hide stat
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)

        command() {
          if [[ "$1" == "-v" && "$2" == "stat" ]]; then
            return 1
          else
            builtin command "$@"
          fi
        }

        # Act: Call get_mtime
        When call get_mtime "$test_file"

        # Assert: Should return empty string
        The output should equal ""
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [異常] - Return empty string when file does not exist'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true

        # Act: Call get_mtime with nonexistent file
        When call get_mtime "/nonexistent/file.txt"

        # Assert: Should return empty string
        The output should equal ""
        The status should be success
      End
    End
  End

  Describe 'Given: Timestamp comparison function (is_newer)'
    Describe 'When: Comparing source and destination timestamps'
      It 'Then: [正常] - Return success when source is newer'
        # Arrange: Use virtual timestamps (no real files needed)
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_time="1700000000"   # Newer timestamp
        dest_time="1600000000"  # Older timestamp

        # Act: Call is_newer with virtual timestamps
        When call is_newer "" "" "$src_time" "$dest_time"

        # Assert: Should return success
        The status should be success
      End

      It 'Then: [正常] - Return failure when source is not newer'
        # Arrange: Use virtual timestamps
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_time="1600000000"   # Older timestamp
        dest_time="1700000000"  # Newer timestamp

        # Act: Call is_newer with virtual timestamps
        When call is_newer "" "" "$src_time" "$dest_time"

        # Assert: Should return failure
        The status should be failure
      End

      It 'Then: [エッジケース] - Return success when timestamps unavailable'
        # Arrange: Use empty virtual timestamps
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call is_newer with empty timestamps
        When call is_newer "" "" "" ""

        # Assert: Should return success (assume newer)
        The status should be success
      End
    End
  End

  Describe 'Given: Backup file function (backup_file)'
    Describe 'When: Creating file backup'
      It 'Then: [正常] - Emit dry-run log when FLAG_DRY_RUN=1'
        # Arrange: Set FLAG_DRY_RUN=1
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DRY_RUN=1
        target_file=$(mktemp)
        echo "content" > "$target_file"

        # Act: Call backup_file
        When call backup_file "$target_file"

        # Assert: Should output dry-run log and not backup file
        The status should be success
        The output should include "[DRY-RUN] mv"
        The output should include ".bak."
        The path "$target_file" should be file

        # Cleanup
        rm -f "$target_file"
        FLAG_DRY_RUN=0
      End

      It 'Then: [正常] - Create timestamped backup file'
        # Arrange: Create target file
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        target_file=$(mktemp)
        echo "backup-data" > "$target_file"

        # Act: Call backup_file
        When call backup_file "$target_file"

        # Assert: Should create backup and remove original
        The status should be success
        backup_path=$(echo "$target_file".bak.*)
        The path "$backup_path" should be file
        The output should include "Backed up:"
        The path "$target_file" should not exist

        # Cleanup
        rm -f "$backup_path"
      End

      It 'Then: [異常] - Return failure and log error when backup fails'
        # Arrange: Mock mv to simulate failure
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        target_file=$(mktemp)
        echo "fail" > "$target_file"

        backup_failure() {
          mv() { return 1; }
          backup_file "$1"
          local status=$?
          unset -f mv
          return $status
        }

        # Act: Call backup_file via wrapper
        When call backup_failure "$target_file"

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "Failed to backup"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        rm -f "$target_file"
      End
    End
  End
End
