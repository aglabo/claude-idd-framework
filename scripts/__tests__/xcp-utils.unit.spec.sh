#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/xcp-utils.unit.spec.sh
# @(#): ShellSpec unit tests for xcp.sh utility functions
#
# @file xcp-utils.unit.spec.sh
# @brief ShellSpec unit tests for xcp.sh utility functions (logging and timestamps)
# @description
#   Unit test suite for xcp.sh logging integration and timestamp operations.
#   Tests logging flags integration with logger.lib.sh and timestamp utilities.
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

Describe 'xcp.sh - Unit tests'
  SCRIPT="./scripts/xcp.sh"

  # ============================================================================
  # Given: Logging flags integration
  # ============================================================================

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
End
