#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/functional/xcp-validation.functional.spec.sh
# @(#): ShellSpec functional tests for xcp.sh validation functions
#
# @file xcp-validation.functional.spec.sh
# @brief ShellSpec functional tests for xcp.sh validation functions
# @description
#   Functional test suite for xcp.sh validation functions.
#   Tests file/directory validation and destination directory creation.
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

Describe 'xcp.sh - Validation functions'
  SCRIPT="./scripts/xcp.sh"

  # Load xcp.sh once for all tests
  BeforeAll '. "$SCRIPT" 2>/dev/null || true'

  # Reset variables before each test
  BeforeEach 'init_variables'

  # ============================================================================
  # Given: Utility functions - Validation
  # ============================================================================

  Describe 'Given: Utility functions - Validation'
    Describe 'When: Implementing validate_source function'
      It 'Then: [正常] - Return success (0) when source exists and is readable'
        # Arrange: Create a temporary readable file
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

    End

    Describe 'When: Implementing check_destination_directory function'
      It 'Then: [正常] - 既存ディレクトリが書き込み可能なら成功を返す'
        test_dir=$(mktemp -d)

        When call check_destination_directory "$test_dir"

        The status should be success

        rm -rf "$test_dir"
      End

      It 'Then: [正常] - 存在しないディレクトリなら 2 を返して作成判断を委ねる'
        base_dir=$(mktemp -d)
        target_dir="$base_dir/nonexistent/nested"
        rm -rf "$base_dir"

        When call check_destination_directory "$target_dir"

        The status should equal 2
        The path "$target_dir" should not exist
      End

      It 'Then: [異常] - 非書き込みディレクトリは失敗しエラーログを出力する'
        Skip "Permission tests not reliable on Windows/Git Bash"

        test_dir=$(mktemp -d)
        chmod 555 "$test_dir"

        When call check_destination_directory "$test_dir"

        The status should be failure
        The error should include "not writable"
        The result of function logger_get_error_count should equal 1

        chmod 755 "$test_dir"
        rm -rf "$test_dir"
      End

      It 'Then: [異常] - ディレクトリ以外のパスが存在する場合は失敗する'
        temp_file=$(mktemp)

        When call check_destination_directory "$temp_file"

        The status should be failure
        The error should include "not a directory"
        The result of function logger_get_error_count should equal 1

        rm -f "$temp_file"
      End

    End

    Describe 'When: Creating destination directories'
      create_destination_directory_failure() {
        mkdir() { return 1; }
        create_destination_directory "$1"
        local status=$?
        unset -f mkdir
        return $status
      }

      It 'Then: [正常] - 既存ディレクトリの場合はそのまま成功を返す'
        FLAG_PARENTS=0
        test_dir=$(mktemp -d)

        When call create_destination_directory "$test_dir"

        The status should be success
        The path "$test_dir" should be directory

        rm -rf "$test_dir"
      End

      It 'Then: [正常] - 親ディレクトリ作成フラグが有効なら mkdir -p を実行する'
        FLAG_PARENTS=1
        base_dir=$(mktemp -d)
        target_dir="$base_dir/nested/subdir"

        When call create_destination_directory "$target_dir"

        The status should be success
        The path "$target_dir" should be directory
        The output should include "[INFO] Created directory"

        rm -rf "$base_dir"
      End

      It 'Then: [異常] - 親ディレクトリ作成フラグが無効な場合はエラーを返す'
        FLAG_PARENTS=0
        base_dir=$(mktemp -d)
        target_dir="$base_dir/disabled/subdir"
        rm -rf "$base_dir"

        When call create_destination_directory "$target_dir"

        The status should be failure
        The error should include "does not exist"
        The result of function logger_get_error_count should equal 1
      End

      It 'Then: [異常] - ディレクトリ作成に失敗した場合はエラーログを出力する'
        FLAG_PARENTS=1
        target_dir="$(mktemp -u)"

        When call create_destination_directory_failure "$target_dir"

        The status should be failure
        The error should include "Failed to create directory"
        The result of function logger_get_error_count should equal 1
      End
    End
  End
End
