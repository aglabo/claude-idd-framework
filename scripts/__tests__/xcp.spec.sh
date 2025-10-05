#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/xcp.spec.sh
# @(#): ShellSpec tests for xcp.sh
#
# @file xcp.spec.sh
# @brief ShellSpec tests for xcp.sh (eXtended CoPy utility)
# @description
#   Comprehensive BDD test suite for xcp.sh.
#   Tests validation functions, timestamp operations, and copy modes.
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

Describe 'xcp.sh'
  SCRIPT="./scripts/xcp.sh"

  # ============================================================================
  # Given: Script initialization and configuration
  # ============================================================================

  Describe 'Given: Script initialization and configuration'
    Describe 'When: Setting up global variables'
      It 'Then: [正常] - Define operation mode constants (MODE_SKIP, MODE_OVERWRITE, MODE_UPDATE, MODE_BACKUP)'
        # Arrange & Act: Check that constants are defined in the script with correct values
        When run bash -c "source $SCRIPT 2>/dev/null || true; echo \"MODE_SKIP=\$MODE_SKIP MODE_OVERWRITE=\$MODE_OVERWRITE MODE_UPDATE=\$MODE_UPDATE MODE_BACKUP=\$MODE_BACKUP\""

        # Assert: Check that output contains all constant definitions
        The output should include "MODE_SKIP=0"
        The output should include "MODE_OVERWRITE=1"
        The output should include "MODE_UPDATE=2"
        The output should include "MODE_BACKUP=3"
      End

      It 'Then: [正常] - Define flag variables (FLAG_DRY_RUN, FLAG_RECURSIVE, FLAG_PARENTS, etc.)'
        # Arrange & Act: Check that all flag variables are initialized to 0
        When run bash -c "source $SCRIPT 2>/dev/null || true; echo \"DRY_RUN=\$FLAG_DRY_RUN RECURSIVE=\$FLAG_RECURSIVE PARENTS=\$FLAG_PARENTS VERBOSE=\$FLAG_VERBOSE QUIET=\$FLAG_QUIET DEREF=\$FLAG_DEREFERENCE FAILFAST=\$FLAG_FAIL_FAST\""

        # Assert: Check that all flags are initialized to 0 (false)
        The output should include "DRY_RUN=0"
        The output should include "RECURSIVE=0"
        The output should include "PARENTS=0"
        The output should include "VERBOSE=0"
        The output should include "QUIET=0"
        The output should include "DEREF=0"
        The output should include "FAILFAST=0"
      End
    End
  End

  # Note: Logging function tests (log_info, log_verbose, log_error, log_dry_run)
  # are covered in scripts/__tests__/logger.spec.sh since xcp.sh now uses logger.lib.sh

  Describe 'Given: Logging flags integration'
    Describe 'When: Controlling informational output with --quiet'
      It 'Then: [正常] - Suppress INFO logs when quiet flag enabled'
        # Arrange: Source script and enable quiet mode
        When run bash -c ". \"$SCRIPT\" >/dev/null 2>&1; logger_init; FLAG_QUIET=1; log_info \"Quiet mode test\""

        # Assert: No INFO output should appear
        The status should be success
        The output should equal ""
      End

      It 'Then: [正常] - log_info returns success status under quiet mode'
        # Arrange: Source script and enable quiet mode
        When run bash -c ". \"$SCRIPT\" >/dev/null 2>&1; logger_init; FLAG_QUIET=1; log_info \"Quiet mode status\"; echo \$?"

        # Assert: Function return value should indicate success
        The output should equal "0"
        The status should be success
      End
    End

    Describe 'When: Emitting verbose logs with --verbose'
      It 'Then: [正常] - Emit VERBOSE logs when verbose flag enabled'
        # Arrange: Source script and enable verbose mode
        When run bash -c ". \"$SCRIPT\" >/dev/null 2>&1; logger_init; FLAG_VERBOSE=1; log_verbose \"Verbose output test\""

        # Assert: VERBOSE output should be visible
        The status should be success
        The output should include "[VERBOSE]"
        The output should include "Verbose output test"
      End

      It 'Then: [正常] - log_verbose returns success status'
        # Arrange: Source script and enable verbose mode
        When run bash -c ". \"$SCRIPT\" >/dev/null 2>&1; logger_init; FLAG_VERBOSE=1; log_verbose \"Verbose status test\" >/dev/null; echo \$?"

        # Assert: Function return value should indicate success
        The output should equal "0"
        The status should be success
      End
    End

    Describe 'When: Tracking errors through logger error count'
      It 'Then: [正常] - Increment error count on error logging'
        # Arrange: Source script and reset logger state
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        initial_count=$(logger_get_error_count)

        # Act: Log an error
        When call log_error "Simulated copy failure"

        # Assert: Error count should increment and message emitted
        The result of function logger_get_error_count should equal "$((initial_count + 1))"
        The error should include "[ERROR]"
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: Utility functions - Validation
  # ============================================================================

  Describe 'Given: Utility functions - Validation'
    Describe 'When: Implementing validate_source function'
      It 'Then: [正常] - Return success (0) when source exists and is readable'
        # Arrange: Create a temporary readable file
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)
        chmod 644 "$test_file"

        # Act: Call validate_source with readable file
        When call validate_source "$test_file"

        # Assert: Function should return success (0)
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [異常] - Return failure (1) and log error when source does not exist'
        # Arrange: Source script and reset error tracking
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call validate_source with nonexistent path
        When call validate_source "/nonexistent/path/to/file.txt"

        # Assert: Function should return failure and log error
        The status should be failure
        The error should include "Source not found"
        The result of function logger_get_error_count should equal 1
      End

      It 'Then: [異常] - Return failure (1) and log error when source is not readable'
        # Note: Skipped on Windows - chmod 000 doesn't prevent read access
        Skip "Permission tests not reliable on Windows/Git Bash"

        # Arrange: Create unreadable file (chmod 000)
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_file=$(mktemp)
        chmod 000 "$test_file"

        # Act: Call validate_source with unreadable file
        When call validate_source "$test_file"

        # Assert: Function should return failure and log error
        The status should be failure
        The error should include "Source not readable"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        chmod 644 "$test_file"
        rm -f "$test_file"
      End

      It 'Then: [エッジケース] - Handle paths with spaces correctly'
        # Arrange: Create file with spaces in filename
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)
        test_file="$test_dir/test file with spaces.txt"
        echo "test content" > "$test_file"

        # Act: Call validate_source with space-containing path
        When call validate_source "$test_file"

        # Assert: Function should handle spaces correctly and return success
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [エッジケース] - Handle paths with special characters'
        # Arrange: Create file with special characters (safe for filesystem)
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)
        test_file="$test_dir/test-file_with.special@chars.txt"
        echo "test content" > "$test_file"

        # Act: Call validate_source with special char path
        When call validate_source "$test_file"

        # Assert: Function should handle special characters and return success
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [エッジケース] - Handle empty source path'
        # Arrange: Source script and reset error tracking
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call validate_source with empty string
        When call validate_source ""

        # Assert: Function should return failure and log error
        The status should be failure
        The error should include "Source not found"
        The result of function logger_get_error_count should equal 1
      End
    End

    Describe 'When: Implementing validate_dest_dir function'
      It 'Then: [正常] - Return success (0) when directory exists and is writable'
        # Arrange: Create a writable test directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_dir=$(mktemp -d)
        FLAG_PARENTS=0

        # Act: Call validate_dest_dir with writable directory
        When call validate_dest_dir "$test_dir"

        # Assert: Function should return success (0)
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [正常] - Create directory and return success when FLAG_PARENTS enabled'
        # Arrange: Set FLAG_PARENTS=1 and use nonexistent directory path
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        test_dir=$(mktemp -d)
        target_dir="$test_dir/nonexistent/nested/dir"
        rm -rf "$test_dir"  # Remove parent to ensure nonexistent

        # Act: Call validate_dest_dir - should create directory
        When call validate_dest_dir "$target_dir"

        # Assert: Function creates directory and returns success
        The status should be success
        The path "$target_dir" should be directory

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [異常] - Return failure (1) when directory exists but not writable'
        # Note: Skipped on Windows - chmod doesn't reliably restrict write access
        Skip "Permission tests not reliable on Windows/Git Bash"

        # Arrange: Create directory and make it non-writable
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        test_dir=$(mktemp -d)
        chmod 555 "$test_dir"  # Read + execute only, no write

        # Act: Call validate_dest_dir with non-writable directory
        When call validate_dest_dir "$test_dir"

        # Assert: Function should return failure and log error
        The status should be failure
        The error should include "not writable"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        chmod 755 "$test_dir"
        rm -rf "$test_dir"
      End

      It 'Then: [異常] - Return failure (1) when directory does not exist and FLAG_PARENTS disabled'
        # Arrange: Set FLAG_PARENTS=0 (disabled) and use nonexistent directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=0
        test_dir=$(mktemp -d)
        nonexistent_dir="$test_dir/nonexistent"
        rm -rf "$test_dir"  # Remove to ensure nonexistent

        # Act: Call validate_dest_dir when FLAG_PARENTS=0
        When call validate_dest_dir "$nonexistent_dir"

        # Assert: Function should return failure and log error
        The status should be failure
        The error should include "does not exist"
        The result of function logger_get_error_count should equal 1
      End

      It 'Then: [エッジケース] - Handle paths with spaces correctly'
        # Arrange: Create directory with spaces in path
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        base_dir=$(mktemp -d)
        test_dir="$base_dir/test dir with spaces"
        mkdir -p "$test_dir"

        # Act: Call validate_dest_dir with space-containing path
        When call validate_dest_dir "$test_dir"

        # Assert: Function should handle spaces correctly and return success
        The status should be success

        # Cleanup
        rm -rf "$base_dir"
      End

      It 'Then: [エッジケース] - Handle empty destination path'
        # Arrange: Source script and reset error tracking
        . "$SCRIPT" 2>/dev/null || true
        logger_init

        # Act: Call validate_dest_dir with empty string
        When call validate_dest_dir ""

        # Assert: Function should return failure and log error
        The status should be failure
        The error should include "empty"
        The result of function logger_get_error_count should equal 1
      End

      It 'Then: [異常] - Return failure when directory creation fails'
        # Note: Skipped on Windows - chmod doesn't reliably restrict write access
        Skip "Permission tests not reliable on Windows/Git Bash"

        # Arrange: Create read-only parent directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        test_dir=$(mktemp -d)
        chmod 555 "$test_dir"  # Read + execute only, no write
        target_dir="$test_dir/cannot/create/this"

        # Act: Call validate_dest_dir when directory creation is impossible
        When call validate_dest_dir "$target_dir"

        # Assert: Function should return failure and log error
        The status should be failure
        The error should include "Failed to create"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        chmod 755 "$test_dir"
        rm -rf "$test_dir"
      End
    End

    Describe 'When: Ensuring destination directories'
      ensure_dest_dir_failure() {
        # Override mkdir to simulate failure
        mkdir() { return 1; }
        ensure_dest_dir "$1"
        local status=$?
        unset -f mkdir
        return $status
      }

      It 'Then: [正常] - Create missing directories when parents flag enabled'
        # Arrange: Prepare non-existing nested directory
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        base_dir=$(mktemp -d)
        target_dir="$base_dir/nested/subdir"

        # Act
        When call ensure_dest_dir "$target_dir"

        # Assert
        The status should be success
        The path "$target_dir" should be directory
        The output should include "[INFO] Created directory"

        # Cleanup
        rm -rf "$base_dir"
      End

      It 'Then: [正常] - Emit dry-run log without creating directory'
        # Arrange: Enable parents and dry-run flags
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        FLAG_DRY_RUN=1
        base_dir=$(mktemp -d)
        target_dir="$base_dir/dry-run/dir"
        expected_message="[DRY-RUN] mkdir -p \"$target_dir\""

        # Act
        When call ensure_dest_dir "$target_dir"

        # Assert
        The status should be success
        The output should include "$expected_message"
        The path "$target_dir" should not exist

        # Cleanup
        rm -rf "$base_dir"
        FLAG_DRY_RUN=0
      End

      It 'Then: [異常] - Log error and fail when directory creation fails'
        # Arrange: Simulate mkdir failure
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        target_dir="$(mktemp -u)"

        # Act
        When call ensure_dest_dir_failure "$target_dir"

        # Assert
        The status should be failure
        The error should include "Failed to create directory"
        The result of function logger_get_error_count should equal 1
      End
    End

    Describe 'When: Implementing is_directory function'
      It 'Then: [正常] - Return success (0) when path is a directory'
        # Arrange: Create a test directory
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)

        # Act: Call is_directory with directory path
        When call is_directory "$test_dir"

        # Assert: Function should return success (0)
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [正常] - Return failure (1) when path is a regular file'
        # Arrange: Create a test file
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)

        # Act: Call is_directory with file path
        When call is_directory "$test_file"

        # Assert: Function should return failure (1)
        The status should be failure

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [異常] - Return failure (1) when path does not exist'
        # Arrange: Use a nonexistent path
        . "$SCRIPT" 2>/dev/null || true
        nonexistent_path="/nonexistent/path/to/directory"

        # Act: Call is_directory with nonexistent path
        When call is_directory "$nonexistent_path"

        # Assert: Function should return failure (1)
        The status should be failure
      End

      It 'Then: [エッジケース] - Handle symlink to directory'
        # Arrange: Create a directory and a symlink to it
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)
        test_link="$test_dir/link_to_dir"
        target_dir="$test_dir/target"
        mkdir -p "$target_dir"
        ln -s "$target_dir" "$test_link"

        # Act: Call is_directory with symlink path
        When call is_directory "$test_link"

        # Assert: Function should return success (0) - symlink to directory is a directory
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End
    End

    Describe 'When: Implementing is_file function'
      It 'Then: [正常] - Return success (0) when path is a regular file'
        # Arrange: Create a test file
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)

        # Act: Call is_file with file path
        When call is_file "$test_file"

        # Assert: Function should return success (0)
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [正常] - Return failure (1) when path is a directory'
        # Arrange: Create a test directory
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)

        # Act: Call is_file with directory path
        When call is_file "$test_dir"

        # Assert: Function should return failure (1)
        The status should be failure

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [異常] - Return failure (1) when path does not exist'
        # Arrange: Use a nonexistent path
        . "$SCRIPT" 2>/dev/null || true
        nonexistent_path="/nonexistent/path/to/file"

        # Act: Call is_file with nonexistent path
        When call is_file "$nonexistent_path"

        # Assert: Function should return failure (1)
        The status should be failure
      End

      It 'Then: [エッジケース] - Handle symlink to file'
        # Arrange: Create a file and a symlink to it
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)
        test_file="$test_dir/target_file"
        test_link="$test_dir/link_to_file"
        touch "$test_file"
        ln -s "$test_file" "$test_link"

        # Act: Call is_file with symlink path
        When call is_file "$test_link"

        # Assert: Function should return success (0) - symlink to file is a file
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End
    End
  End

  # is_symlink function tests
  Describe 'Given: xcp.sh script with is_symlink function'
    Describe 'When: Checking if path is a symbolic link'
      It 'Then: [正常] - Return true (0) when path is a symbolic link'
        # Arrange: Create a file and a symlink to it
        . "$SCRIPT" 2>/dev/null || true
        export MSYS=winsymlinks:nativestrict
        test_dir=$(mktemp -d)
        test_file="$test_dir/target_file"
        test_link="$test_dir/link"
        touch "$test_file"
        ln -s "$test_file" "$test_link"

        # Act: Call is_symlink with symlink path
        When call is_symlink "$test_link"

        # Assert: Function should return success (0)
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [正常] - Return false (1) when path is a regular file'
        # Arrange: Create a regular file
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)
        test_file="$test_dir/regular_file"
        touch "$test_file"

        # Act: Call is_symlink with regular file
        When call is_symlink "$test_file"

        # Assert: Function should return failure (1)
        The status should be failure

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [正常] - Return false (1) when path is a directory'
        # Arrange: Create a directory
        . "$SCRIPT" 2>/dev/null || true
        test_dir=$(mktemp -d)
        test_subdir="$test_dir/subdir"
        mkdir "$test_subdir"

        # Act: Call is_symlink with directory
        When call is_symlink "$test_subdir"

        # Assert: Function should return failure (1)
        The status should be failure

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [異常] - Return false (1) when path does not exist'
        # Arrange: Use nonexistent path
        . "$SCRIPT" 2>/dev/null || true
        nonexistent_path="/nonexistent/path/that/does/not/exist"

        # Act: Call is_symlink with nonexistent path
        When call is_symlink "$nonexistent_path"

        # Assert: Function should return failure (1)
        The status should be failure
      End

      It 'Then: [エッジケース] - Handle broken symlink (return true for symlink even if target missing)'
        # Arrange: Create a broken symlink (symlink to nonexistent target)
        . "$SCRIPT" 2>/dev/null || true
        export MSYS=winsymlinks:nativestrict
        test_dir=$(mktemp -d)
        test_link="$test_dir/broken_link"
        ln -s "/nonexistent/target" "$test_link"

        # Act: Call is_symlink with broken symlink
        When call is_symlink "$test_link"

        # Assert: Function should return success (0) - it's still a symlink
        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End
    End
  End

  # ============================================================================
  # Given: Utility functions - Timestamp Operations
  # ============================================================================

  Describe 'Given: get_timestamp function'
    Describe 'When: get_timestamp is called'
      It 'Then: [正常] - Returns current timestamp in YYMMDDHHMMSS format'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true

        # Act: Call get_timestamp
        When call get_timestamp

        # Assert: Output should be 12-digit timestamp (YYMMDDHHMMSS)
        The output should match pattern "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
        The status should be success
      End

      It 'Then: [正常] - Uses date command with +%y%m%d%H%M%S format'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true

        # Act: Get timestamp from function and directly from date command
        timestamp=$(get_timestamp)
        expected=$(date +%y%m%d%H%M%S)

        # Assert: Both timestamps should be equal (or differ by at most 1 second due to timing)
        # Check if timestamps match exactly OR are within 1 second
        When call bash -c "[[ '$timestamp' == '$expected' ]] || [[ $(( ${timestamp##*[!0-9]} - ${expected##*[!0-9]} )) -le 1 ]]"

        The status should be success
      End

      It 'Then: [正常] - Handles timezone correctly'
        # Arrange: Source script and get system timezone
        . "$SCRIPT" 2>/dev/null || true

        # Act: Get timestamp and verify it matches local timezone behavior
        # The date command uses local timezone by default
        timestamp=$(get_timestamp)
        expected=$(date +%y%m%d%H%M%S)

        # Assert: Timestamp should match local timezone (not UTC)
        # Verify timestamp format is consistent with system date command
        When call bash -c "[[ '$timestamp' =~ ^[0-9]{12}$ ]] && [[ '$timestamp' == '$expected' || $(( ${timestamp##*[!0-9]} - ${expected##*[!0-9]} )) -le 1 ]]"

        The status should be success
      End

      It 'Then: [エッジケース] - Ensure timestamp is consistent within same second'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true

        # Act: Call get_timestamp multiple times rapidly
        # All calls within the same second should return identical timestamps
        timestamp1=$(get_timestamp)
        timestamp2=$(get_timestamp)
        timestamp3=$(get_timestamp)

        # Assert: All timestamps should be identical (same second)
        # This ensures backup naming consistency
        When call bash -c '
          t1='"$timestamp1"'
          t2='"$timestamp2"'
          t3='"$timestamp3"'
          t1_dec=$((10#$t1))
          t2_dec=$((10#$t2))
          t3_dec=$((10#$t3))
          max=$t1_dec
          for val in "$t2_dec" "$t3_dec"; do
            [[ $val -gt $max ]] && max=$val
          done
          min=$t1_dec
          for val in "$t2_dec" "$t3_dec"; do
            [[ $val -lt $min ]] && min=$val
          done
          [[ $(( max - min )) -le 1 ]]
        '

        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: get_mtime function
  # ============================================================================

  Describe 'Given: get_mtime function'
    Describe 'When: getting file modification time'
      It 'Then: [正常] - Returns Unix timestamp using GNU stat command'
        # Arrange: Create a test file and source script
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)
        touch "$test_file"

        # Act: Call get_mtime with test file
        When call get_mtime "$test_file"

        # Assert: Output should be Unix timestamp (numeric, 10 digits)
        The output should match pattern "[0-9][0-9]*"
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [正常] - Returns Unix timestamp using BSD stat command (fallback)'
        # Arrange: Create test file and mock GNU stat to fail, BSD stat to succeed
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)
        touch "$test_file"
        expected_mtime=$(command stat -c %Y "$test_file" 2>/dev/null)

        # Mock stat command to force BSD fallback
        # GNU stat (-c flag) will fail, BSD stat (-f flag) will return mtime
        stat() {
          if [[ "$1" == "-c" ]]; then
            # GNU stat syntax - simulate failure (exit 1)
            return 1
          elif [[ "$1" == "-f" ]]; then
            # BSD stat syntax - simulate success with actual mtime
            # On real BSD: stat -f %m "$file"
            # Simulate by returning the expected mtime
            echo "$expected_mtime"
            return 0
          else
            # Fallback to command stat for other uses
            command stat "$@"
          fi
        }

        # Act: Call get_mtime with test file (GNU stat will fail, fallback to BSD)
        When call get_mtime "$test_file"

        # Assert: Output should be Unix timestamp from BSD stat
        The output should match pattern "[0-9][0-9]*"
        The output should equal "$expected_mtime"
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [異常] - Returns empty string when stat command unavailable'
        # Arrange: Source script and mock command builtin to hide stat
        . "$SCRIPT" 2>/dev/null || true
        test_file=$(mktemp)
        touch "$test_file"

        # Mock command builtin to report stat as unavailable
        command() {
          if [[ "$1" == "-v" ]] && [[ "$2" == "stat" ]]; then
            # Simulate stat command not found
            return 1
          else
            # Fallback to builtin command for other uses
            builtin command "$@"
          fi
        }

        # Act: Call get_mtime with test file when stat is unavailable
        When call get_mtime "$test_file"

        # Assert: Output should be empty string (nothing output)
        The output should equal ""
        The status should be success

        # Cleanup
        rm -f "$test_file"
      End

      It 'Then: [異常] - Returns empty string when file does not exist'
        # Arrange: Source script
        . "$SCRIPT" 2>/dev/null || true

        # Act: Call get_mtime with nonexistent file path
        When call get_mtime "/this/path/does/not/exist.txt"

        # Assert: Output should be empty string (stat fails silently due to 2>/dev/null)
        The output should equal ""
        The status should be success
      End

      It 'Then: [エッジケース] - Handle symlinks correctly (get link mtime, not target)'
        # Arrange: Create temp file, symlink to it, and modify symlink mtime
        . "$SCRIPT" 2>/dev/null || true
        export MSYS=winsymlinks:nativestrict
        test_dir=$(mktemp -d)
        target_file="$test_dir/target.txt"
        symlink_path="$test_dir/link"

        # Create target file and symlink
        touch "$target_file"
        sleep 1  # Ensure different timestamps
        ln -s "$target_file" "$symlink_path"

        # Get mtimes: symlink should have newer mtime than target
        target_mtime=$(command stat -c %Y "$target_file" 2>/dev/null || command stat -f %m "$target_file" 2>/dev/null)
        symlink_mtime=$(get_mtime "$symlink_path")

        # Act & Assert: Verify symlink_mtime is different from target_mtime
        # Since we created symlink after target (sleep 1), symlink should have later mtime
        When call bash -c "[[ '$symlink_mtime' -ne '$target_mtime' ]]"

        The status should be success

        # Cleanup
        rm -rf "$test_dir"
      End
    End
  End

  # ============================================================================
  # Given: is_newer function
  # ============================================================================

  Describe 'Given: is_newer function'
    Describe 'When: Comparing source and destination timestamps'
      It 'Then: [正常] - Return success when source is newer'
        # Arrange
        . "$SCRIPT" 2>/dev/null || true
        FLAG_VERBOSE=0
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "dest" > "$dest_file"
        sleep 1
        echo "src" > "$src_file"

        # Act
        When call is_newer "$src_file" "$dest_file"

        # Assert
        The status should be success
        The output should equal ""

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - Return failure and log skip when source is not newer'
        # Arrange
        . "$SCRIPT" 2>/dev/null || true
        FLAG_VERBOSE=0
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "src" > "$src_file"
        sleep 1
        echo "dest" > "$dest_file"

        # Act
        When call is_newer "$src_file" "$dest_file"

        # Assert
        The status should be failure
        The output should equal ""

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [エッジケース] - Assume newer when timestamps unavailable'
        # Arrange
        . "$SCRIPT" 2>/dev/null || true
        FLAG_VERBOSE=0
        src_file=$(mktemp)
        echo "data" > "$src_file"
        nonexistent_dest="$(mktemp -u)"

        # Act
        When call is_newer "$src_file" "$nonexistent_dest"

        # Assert
        The status should be success
        The output should equal ""

        # Cleanup
        rm -f "$src_file"
      End
    End
  End

  # ============================================================================
  # Given: backup_file function
  # ============================================================================

  Describe 'Given: backup_file function'
    setup_backup() {
      . "$SCRIPT" 2>/dev/null || true
      logger_init
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

  # ============================================================================
  # Given: copy_file function
  # ============================================================================

  Describe 'Given: copy_file function with mode branching'
    setup_copy_file() {
      . "$SCRIPT" 2>/dev/null || true
      logger_init
    }

    BeforeEach 'setup_copy_file'

    Describe 'When: Handling existing files with default MODE_SKIP'
      It 'Then: [正常] - 既存ファイルはデフォルトでスキップし INFO ログに結果を記録する'
        # Arrange: Create source and existing destination with different content
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "source content" > "$src_file"
        echo "dest content" > "$dest_file"
        original_content=$(cat "$dest_file")
        OPERATION_MODE=$MODE_SKIP

        # Act: Call copy_file with existing destination
        When call copy_file "$src_file" "$dest_file"

        # Assert: Destination should remain unchanged
        The status should be success
        new_content=$(cat "$dest_file")
        The variable new_content should equal "$original_content"
        The output should include "[INFO] Skipped (exists)"

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End
    End

    Describe 'When: Handling existing files with MODE_OVERWRITE'
      It 'Then: [正常] - --overwrite 指定時に既存ファイルを強制上書きし詳細ログを出力する'
        # Arrange: Enable verbose mode and create test files
        FLAG_VERBOSE=1
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "source content" > "$src_file"
        echo "dest content" > "$dest_file"
        OPERATION_MODE=$MODE_OVERWRITE

        # Act: Call copy_file with existing destination
        When call copy_file "$src_file" "$dest_file"

        # Assert: Destination should be updated with source content and log overwrite message
        The status should be success
        new_content=$(cat "$dest_file")
        The variable new_content should equal "source content"
        The output should include "[VERBOSE] Overwriting"

        # Cleanup
        rm -f "$src_file" "$dest_file"
        FLAG_VERBOSE=0
      End
    End

    Describe 'When: Handling existing files with MODE_UPDATE'
      It 'Then: [正常] - --update 指定時にソースが新しい場合は更新する'
        # Arrange: Create destination file, wait, then create newer source
        dest_file=$(mktemp)
        echo "old content" > "$dest_file"
        sleep 1
        src_file=$(mktemp)
        echo "new content" > "$src_file"
        FLAG_VERBOSE=1
        OPERATION_MODE=$MODE_UPDATE

        # Act: Call copy_file with source newer than destination
        When call copy_file "$src_file" "$dest_file"

        # Assert: Destination should be updated with newer source content
        The status should be success
        new_content=$(cat "$dest_file")
        The variable new_content should equal "new content"
        The output should include "[VERBOSE] Updating"

        # Cleanup
        rm -f "$src_file" "$dest_file"
        FLAG_VERBOSE=0
      End

      It 'Then: [正常] - --update 指定時にソースが新しくない場合はスキップし INFO ログを出力する'
        # Arrange: Create newer destination and older source
        src_file=$(mktemp)
        echo "source content" > "$src_file"
        sleep 1
        dest_file=$(mktemp)
        echo "existing content" > "$dest_file"
        OPERATION_MODE=$MODE_UPDATE
        original_content=$(cat "$dest_file")

        # Act: Call copy_file with older source than destination
        When call copy_file "$src_file" "$dest_file"

        # Assert: Destination should remain unchanged and skip log emitted
        The status should be success
        new_content=$(cat "$dest_file")
        The variable new_content should equal "$original_content"
        The output should include "[INFO] Skipped (not newer)"

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End
    End

    Describe 'When: Handling existing files with MODE_BACKUP'
      It 'Then: [正常] - --backup 指定時にバックアップを作成してからコピーする'
        # Arrange: Prepare source and destination plus verbose logging
        FLAG_VERBOSE=1
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "source content" > "$src_file"
        echo "existing content" > "$dest_file"
        original_content=$(cat "$dest_file")
        OPERATION_MODE=$MODE_BACKUP

        # Act: Call copy_file with backup mode
        When call copy_file "$src_file" "$dest_file"

        # Assert: Backup is created before copy and both files exist
        The status should be success
        backup_files=( "${dest_file}".bak.* )
        backup_path="${backup_files[0]}"
        backup_count=${#backup_files[@]}
        The variable backup_count should equal "1"
        The path "$backup_path" should be file
        backup_content=$(cat "$backup_path")
        The variable backup_content should equal "$original_content"
        The path "$dest_file" should be file
        new_content=$(cat "$dest_file")
        The variable new_content should equal "source content"
        The output should include "[VERBOSE] Backing up:"
        The output should include "[INFO] Backed up:"
        The output should include "[VERBOSE] Copying:"

        # Cleanup
        rm -f "$src_file" "$dest_file" "$backup_path"
        FLAG_VERBOSE=0
      End
    End

    Describe 'When: Preserving file attributes during copy'
      It 'Then: [正常] - コピー後のパーミッションがソースと一致する'
        # Arrange: Prepare source and destination with differing permissions
        case "$(uname -s)" in
          MINGW*|MSYS*|CYGWIN*)
            Skip 'Windows 環境ではパーミッション検証をスキップ'
            ;;
        esac

        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "source content" > "$src_file"
        echo "destination content" > "$dest_file"
        chmod 640 "$src_file"
        chmod 600 "$dest_file"
        OPERATION_MODE=$MODE_OVERWRITE

        # Act: Overwrite existing destination file
        When call copy_file "$src_file" "$dest_file"

        # Assert: Destination permissions should match source permissions
        The status should be success
        src_mode=$(command stat -c %a "$src_file" 2>/dev/null || command stat -f %Mp%Lp "$src_file" 2>/dev/null)
        dest_mode=$(command stat -c %a "$dest_file" 2>/dev/null || command stat -f %Mp%Lp "$dest_file" 2>/dev/null)
        The variable dest_mode should equal "$src_mode"

        # Cleanup
        OPERATION_MODE=$MODE_SKIP
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - コピー後のタイムスタンプがソースと一致する'
        # Arrange: Prepare source and destination with differing timestamps
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "timestamp content" > "$src_file"
        echo "old content" > "$dest_file"
        command touch -t 202001010000 "$src_file" 2>/dev/null || command touch -d '2020-01-01 00:00:00' "$src_file"
        sleep 1
        command touch -t 202402020202 "$dest_file" 2>/dev/null || command touch -d '2024-02-02 02:02:00' "$dest_file"
        OPERATION_MODE=$MODE_OVERWRITE

        # Act: Overwrite existing destination file
        When call copy_file "$src_file" "$dest_file"

        # Assert: Destination timestamp should match source timestamp
        The status should be success
        src_mtime=$(command stat -c %Y "$src_file" 2>/dev/null || command stat -f %m "$src_file" 2>/dev/null)
        dest_mtime=$(command stat -c %Y "$dest_file" 2>/dev/null || command stat -f %m "$dest_file" 2>/dev/null)
        The variable dest_mtime should equal "$src_mtime"

        # Cleanup
        OPERATION_MODE=$MODE_SKIP
        rm -f "$src_file" "$dest_file"
      End
    End

    Describe 'When: Dereferencing symbolic links during copy'
      It 'Then: [正常] - FLAG_DEREFERENCE=1 のときリンク先の実体をコピーする'
        # Arrange: Prepare file and symlink setup
        target_file=$(mktemp)
        echo "symlink target content" > "$target_file"
        src_link="${target_file}.link"
        if ! ln -s "$target_file" "$src_link" 2>/dev/null; then
          Skip 'シンボリックリンクを作成できない環境'
          return 0
        fi
        dest_dir=$(mktemp -d)
        FLAG_VERBOSE=1
        FLAG_DEREFERENCE=1

        # Act: Copy symlink with dereference enabled
        When call copy_file "$src_link" "$dest_dir"

        # Assert: Destination should be a regular file with target content
        The status should be success
        dest_file="$dest_dir/$(basename "$src_link")"
        The path "$dest_file" should be file
        file_type=$(command stat -c %F "$dest_file" 2>/dev/null || command stat -f %HT "$dest_file" 2>/dev/null)
        The variable file_type should equal "regular file"
        dest_content=$(cat "$dest_file")
        The variable dest_content should equal "symlink target content"
        The output should include "[VERBOSE] Dereferencing symlink"

        # Cleanup
        FLAG_VERBOSE=0
        FLAG_DEREFERENCE=0
        rm -f "$target_file" "$src_link" "$dest_file"
        rmdir "$dest_dir"
      End
    End

    Describe 'When: Handling copy failures with fail-fast'
      It 'Then: [異常] - fail-fast 指定時はエラーで即時停止フラグを立てる'
        # Arrange: Prepare missing source to force failure
        missing_src=$(mktemp -u)
        dest_dir=$(mktemp -d)
        FLAG_FAIL_FAST=1
        FLAG_ABORT_REQUESTED=0

        # Act: Attempt to copy missing source
        When call copy_file "$missing_src" "$dest_dir"

        # Assert: copy_file should fail and request abort
        The status should be failure
        The error should include "Failed to copy"
        The variable FLAG_ABORT_REQUESTED should equal "1"

        # Cleanup
        FLAG_FAIL_FAST=0
        FLAG_ABORT_REQUESTED=0
        rmdir "$dest_dir"
      End

      It 'Then: [異常] - fail-fast 無効時は停止フラグを立てずにエラーを返す'
        # Arrange: Prepare missing source to force failure
        missing_src=$(mktemp -u)
        dest_dir=$(mktemp -d)
        FLAG_FAIL_FAST=0
        FLAG_ABORT_REQUESTED=0

        # Act: Attempt to copy missing source
        When call copy_file "$missing_src" "$dest_dir"

        # Assert: copy_file should fail but not request abort
        The status should be failure
        The error should include "Failed to copy"
        The variable FLAG_ABORT_REQUESTED should equal "0"

        # Cleanup
        FLAG_ABORT_REQUESTED=0
        rmdir "$dest_dir"
      End
    End
  End

  Describe 'Given: copy_directory function'
    setup_copy_directory() {
      . "$SCRIPT" 2>/dev/null || true
      logger_init
      FLAG_VERBOSE=0
      FLAG_PARENTS=0
      FLAG_FAIL_FAST=0
      FLAG_ABORT_REQUESTED=0
    }

    restore_copy_file() {
      if declare -f original_copy_file >/dev/null; then
        eval "$(declare -f original_copy_file | sed '1s/original_copy_file/copy_file/')"
        unset -f original_copy_file
      fi
    }

    BeforeEach 'setup_copy_directory'
    AfterEach 'restore_copy_file'

    Describe 'When: Recursively copying directories'
      It 'Then: [正常] - サブディレクトリを mkdir -p しながら処理する'
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub1/sub2"
        echo "content" > "$src_dir/sub1/sub2/file.txt"
        FLAG_PARENTS=1
        FLAG_VERBOSE=1

        When call copy_directory "$src_dir" "$dest_dir"

        The status should be success
        The path "$dest_dir/sub1/sub2" should be directory
        The output should match pattern "*[[]VERBOSE[]]*Creating directory:*sub1/sub2*"

        FLAG_VERBOSE=0
        FLAG_PARENTS=0
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - ネストしたファイルを copy_file へ委譲し内容を保持する'
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub1/sub2"
        echo "alpha" > "$src_dir/sub1/sub2/a.txt"
        echo "beta" > "$src_dir/sub1/sub2/b.txt"
        FLAG_PARENTS=1

        eval "$(declare -f copy_file | sed '1s/copy_file/original_copy_file/')"
        copy_file_call_count=0
        copy_file() {
          copy_file_call_count=$((copy_file_call_count + 1))
          original_copy_file "$1" "$2"
        }

        When call copy_directory "$src_dir" "$dest_dir"

        The status should be success
        The variable copy_file_call_count should equal "2"
        The contents of file "$dest_dir/sub1/sub2/a.txt" should equal "alpha"
        The contents of file "$dest_dir/sub1/sub2/b.txt" should equal "beta"
        The output should match pattern "*[[]INFO[]] Created directory:*"

        FLAG_PARENTS=0
        rm -rf "$src_dir" "$dest_dir"
      End
    End

    Describe 'When: Handling failures during recursion'
      It 'Then: [異常] - fail-fast 指定時は子要素失敗で巡回を停止する'
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub1"
        echo "one" > "$src_dir/sub1/a.txt"
        echo "two" > "$src_dir/sub1/b.txt"
        FLAG_PARENTS=1
        FLAG_FAIL_FAST=1
        FLAG_ABORT_REQUESTED=0

        eval "$(declare -f copy_file | sed '1s/copy_file/original_copy_file/')"
        copy_file_fail_count=0
        copy_file() {
          copy_file_fail_count=$((copy_file_fail_count + 1))
          log_error "Simulated copy failure: $1"
          if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
            FLAG_ABORT_REQUESTED=1
          fi
          return 1
        }

        When call copy_directory "$src_dir" "$dest_dir"

        The status should be failure
        The variable copy_file_fail_count should equal "1"
        The result of function logger_get_error_count should equal 1
        The variable FLAG_ABORT_REQUESTED should equal "1"

        FLAG_FAIL_FAST=0
        FLAG_ABORT_REQUESTED=0
        FLAG_PARENTS=0
        rm -rf "$src_dir" "$dest_dir"
      End
    End

    Describe 'When: Copying directories with symlinks (--dereference disabled)'
      It 'Then: [正常] - シンボリックリンクを cp -P で維持する'
        # Arrange: Create directory with symlink
        export MSYS=winsymlinks:nativestrict
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        target_file="$src_dir/target.txt"
        symlink_file="$src_dir/link.txt"

        echo "target content" > "$target_file"
        if ! ln -s "$target_file" "$symlink_file" 2>/dev/null; then
          Skip 'シンボリックリンクを作成できない環境'
          rm -rf "$src_dir" "$dest_dir"
          return 0
        fi

        FLAG_PARENTS=1
        FLAG_DEREFERENCE=0  # Preserve symlinks

        # Act: Copy directory with symlink
        When call copy_directory "$src_dir" "$dest_dir"

        # Assert: Symlink should be preserved (not dereferenced)
        The status should be success
        dest_link="$dest_dir/link.txt"
        The path "$dest_link" should exist

        # Verify it's a symlink
        if [[ -L "$dest_link" ]]; then
          symlink_preserved=1
        else
          symlink_preserved=0
        fi
        The variable symlink_preserved should equal "1"

        # Cleanup
        FLAG_PARENTS=0
        FLAG_DEREFERENCE=0
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - FLAG_DEREFERENCE=1 のときリンク先の実体をコピーする'
        # Arrange: Create directory with symlink
        export MSYS=winsymlinks:nativestrict
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        target_file="$src_dir/target.txt"
        symlink_file="$src_dir/link.txt"

        echo "dereferenced content" > "$target_file"
        if ! ln -s "$target_file" "$symlink_file" 2>/dev/null; then
          Skip 'シンボリックリンクを作成できない環境'
          rm -rf "$src_dir" "$dest_dir"
          return 0
        fi

        FLAG_PARENTS=1
        FLAG_DEREFERENCE=1  # Dereference symlinks

        # Act: Copy directory with symlink dereferencing enabled
        When call copy_directory "$src_dir" "$dest_dir"

        # Assert: Symlink should be dereferenced (copied as regular file)
        The status should be success
        dest_link="$dest_dir/link.txt"
        The path "$dest_link" should exist

        # Verify it's a regular file (not a symlink)
        if [[ ! -L "$dest_link" && -f "$dest_link" ]]; then
          symlink_dereferenced=1
        else
          symlink_dereferenced=0
        fi
        The variable symlink_dereferenced should equal "1"

        # Verify content is copied
        dest_content=$(cat "$dest_link")
        The variable dest_content should equal "dereferenced content"

        # Cleanup
        FLAG_PARENTS=0
        FLAG_DEREFERENCE=0
        rm -rf "$src_dir" "$dest_dir"
      End
    End

    Describe 'When: Dry-run mode for directory copy'
      It 'Then: [正常] - 各コピー操作を [DRY-RUN] ログとして出力する'
        # Arrange: Create directory with files and symlink
        export MSYS=winsymlinks:nativestrict
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/subdir"
        echo "file content" > "$src_dir/file.txt"
        echo "nested content" > "$src_dir/subdir/nested.txt"
        target_file="$src_dir/target.txt"
        symlink_file="$src_dir/link.txt"
        echo "target" > "$target_file"

        # Create symlink (skip test if not supported)
        if ! ln -s "$target_file" "$symlink_file" 2>/dev/null; then
          Skip 'シンボリックリンクを作成できない環境'
          rm -rf "$src_dir" "$dest_dir"
          return 0
        fi

        FLAG_PARENTS=1
        FLAG_DRY_RUN=1
        FLAG_DEREFERENCE=0

        # Act: Copy directory in dry-run mode
        When call copy_directory "$src_dir" "$dest_dir"

        # Assert: Should output dry-run logs without actually copying
        The status should be success
        The output should include "[DRY-RUN] find"
        The output should include "-type d -print0"
        The output should include "\\( -type f -o -type l \\) -print0"

        # Verify no actual files were copied
        dest_file_count=$(find "$dest_dir" -type f 2>/dev/null | wc -l)
        The variable dest_file_count should equal "0"

        # Cleanup
        FLAG_PARENTS=0
        FLAG_DRY_RUN=0
        FLAG_DEREFERENCE=0
        rm -rf "$src_dir" "$dest_dir"
      End
    End
  End

  # ============================================================================
  # Given: main function with source processing flow
  # ============================================================================

  Describe 'Given: main function with source processing flow'
    setup_main() {
      . "$SCRIPT" 2>/dev/null || true
      logger_init
      FLAG_VERBOSE=0
      FLAG_PARENTS=0
      FLAG_RECURSIVE=0
      FLAG_FAIL_FAST=0
      FLAG_ABORT_REQUESTED=0
      OPERATION_MODE=$MODE_SKIP
    }

    BeforeEach 'setup_main'

    Describe 'When: Processing single source file'
      It 'Then: [正常] - main identifies file and calls copy_file'
        # Arrange: Create source file and destination directory
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "test content" > "$src_file"
        FLAG_PARENTS=1

        # Override parse_args to set SOURCE_ARGS and DEST_ARG
        parse_args() {
          SOURCE_ARGS=("$src_file")
          DEST_ARG="$dest_dir"
          return 0
        }

        # Act: Call main with source file and destination
        When call main "$src_file" "$dest_dir"

        # Assert: File should be copied to destination
        The status should be success
        dest_file="$dest_dir/$(basename "$src_file")"
        The path "$dest_file" should be file
        dest_content=$(cat "$dest_file")
        The variable dest_content should equal "test content"

        # Cleanup
        FLAG_PARENTS=0
        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [正常] - main identifies directory and calls copy_directory when recursive enabled'
        # Arrange: Create source directory with files
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/subdir"
        echo "file content" > "$src_dir/file.txt"
        echo "nested content" > "$src_dir/subdir/nested.txt"
        FLAG_PARENTS=1
        FLAG_RECURSIVE=1

        # Override parse_args
        parse_args() {
          SOURCE_ARGS=("$src_dir")
          DEST_ARG="$dest_dir"
          return 0
        }

        # Act: Call main with source directory
        When call main "$src_dir" "$dest_dir"

        # Assert: Directory should be recursively copied
        The status should be success
        dest_subdir="$dest_dir/$(basename "$src_dir")"
        The path "$dest_subdir/file.txt" should be file
        The path "$dest_subdir/subdir/nested.txt" should be file

        # Cleanup
        FLAG_PARENTS=0
        FLAG_RECURSIVE=0
        rm -rf "$src_dir" "$dest_dir"
      End
    End
  End
End
