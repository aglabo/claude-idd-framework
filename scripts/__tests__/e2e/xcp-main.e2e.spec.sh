#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/e2e/xcp-main.e2e.spec.sh
# @(#): ShellSpec E2E tests for xcp.sh main function workflow
#
# @file xcp-main.e2e.spec.sh
# @brief ShellSpec E2E tests for xcp.sh main function and end-to-end workflows
# @description
#   End-to-end test suite for xcp.sh main function.
#   Tests complete workflows from argument parsing through copy execution to exit codes.
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

Describe 'xcp.sh - E2E tests'
  SCRIPT="./scripts/xcp.sh"
  
  # Load xcp.sh once for all tests
  BeforeAll '. "$SCRIPT" 2>/dev/null || true'
  
  # Reset variables before each test
  BeforeEach 'init_variables'

  # ============================================================================
  # Given: main function with source processing flow
  # ============================================================================

  Describe 'Given: main function with source processing flow'
    # No additional setup needed - BeforeAll already loads the script
    # and BeforeEach calls init_variables

    Describe 'When: Processing single source file'
      It 'Then: [正常] - main identifies file and calls copy_file'
        # Arrange: Create source file and destination directory
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "test content" > "$src_file"

        # Act: Call main with -p flag for parent directory creation
        When call main -p "$src_file" "$dest_dir"

        # Assert: File should be copied to destination
        The status should be success
        dest_file="$dest_dir/$(basename "$src_file")"
        The path "$dest_file" should be file
        dest_content=$(cat "$dest_file")
        The variable dest_content should equal "test content"

        # Cleanup
        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [正常] - main identifies directory and calls copy_directory when recursive enabled'
        # Arrange: Create source directory with files
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/subdir"
        echo "file content" > "$src_dir/file.txt"
        echo "nested content" > "$src_dir/subdir/nested.txt"

        # Act: Call main with -R and -p flags for recursive copy
        When call main -R -p "$src_dir" "$dest_dir"

        # Assert: Directory should be recursively copied
        The status should be success
        The output should include "[INFO] Created directory:"
        dest_subdir="$dest_dir/$(basename "$src_dir")"
        The path "$dest_subdir/file.txt" should be file
        The path "$dest_subdir/subdir/nested.txt" should be file

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
      End
    End

    Describe 'When: Processing multiple sources'
      It 'Then: [正常] - main processes all source files successfully'
        # Arrange: Create multiple source files
        src1=$(mktemp)
        src2=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "content1" > "$src1"
        echo "content2" > "$src2"

        # Act: Call main with -p flag and multiple sources
        When call main -p "$src1" "$src2" "$dest_dir"

        # Assert: All files should be copied
        The status should be success
        dest1="$dest_dir/$(basename "$src1")"
        dest2="$dest_dir/$(basename "$src2")"
        The path "$dest1" should be file
        The path "$dest2" should be file
        content1=$(cat "$dest1")
        content2=$(cat "$dest2")
        The variable content1 should equal "content1"
        The variable content2 should equal "content2"

        # Cleanup
        rm -rf "$src1" "$src2" "$dest_dir"
      End
    End

    Describe 'When: Reporting errors and exit codes'
      It 'Then: [正常] - returns exit code 0 when all operations succeed'
        # Arrange: Create valid source and destination
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "success content" > "$src_file"

        # Act: Call main with -p flag
        When call main -p "$src_file" "$dest_dir"

        # Assert: Should return success (0)
        The status should be success

        # Cleanup
        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [異常] - displays error count message when errors occur'
        # Arrange: Create source files where one will fail
        src1=$(mktemp)
        src2=$(mktemp -u)  # Non-existent file to cause error
        dest_dir=$(mktemp -d)
        echo "content1" > "$src1"

        # Act: Call main with -p flag and sources where one fails
        When call main -p "$src1" "$src2" "$dest_dir"

        # Assert: Should display error count message
        The status should be failure
        The error should include "[ERROR] Completed with"
        The error should include "error(s)"

        # Cleanup
        rm -rf "$src1" "$dest_dir"
      End

      It 'Then: [異常] - returns exit code 1 when errors occur'
        # Arrange: Create scenario with non-existent source
        missing_src=$(mktemp -u)
        dest_dir=$(mktemp -d)

        # Act: Call main with -p flag and missing source
        When call main -p "$missing_src" "$dest_dir"

        # Assert: Should return exit code 1
        The status should be failure
        The error should include "[ERROR]"

        # Cleanup
        rm -rf "$dest_dir"
      End

      It 'Then: [正常] - displays consistent summary in dry-run mode'
        # Arrange: Create test file for dry-run
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "dry-run content" > "$src_file"

        # Act: Call main with --dry-run and -p flags
        When call main --dry-run -p "$src_file" "$dest_dir"

        # Assert: Should succeed and show dry-run logs
        The status should be success
        The output should include "[DRY-RUN]"

        # Cleanup
        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [異常] - fail-fast mode stops on first error'
        # Arrange: Create files where first will fail
        src1=$(mktemp -u)  # Non-existent to cause immediate error
        src2=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "content2" > "$src2"

        # Act: Call main with --fail-fast and -p flags
        When call main --fail-fast -p "$src1" "$src2" "$dest_dir"

        # Assert: Should fail on first error
        The status should be failure
        The error should include "[ERROR]"

        # Cleanup
        rm -rf "$src2" "$dest_dir"
      End
    End
  End

  # ============================================================================
  # Given: main function with hidden files handling
  # ============================================================================

  Describe 'Given: main function with hidden files handling'
    BeforeEach 'init_variables'

    Describe 'When: Copying directories with hidden files'
      It 'Then: [正常] - デフォルトで隠しファイルを除外する'
        # Arrange: ディレクトリ作成（通常ファイル + 隠しファイル）
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        echo "visible" > "$src_dir/visible.txt"
        echo "hidden" > "$src_dir/.hidden.txt"
        mkdir -p "$src_dir/subdir"
        echo "nested visible" > "$src_dir/subdir/nested.txt"
        echo "nested hidden" > "$src_dir/subdir/.nested_hidden.txt"

        # Act: main を -R -p フラグで実行（-H なし）
        When call main -R -p "$src_dir" "$dest_dir"

        # Assert: 通常ファイルのみコピーされる
        The status should be success
        The output should include "[INFO] Created directory:"
        dest_subdir="$dest_dir/$(basename "$src_dir")"
        The path "$dest_subdir/visible.txt" should be file
        The path "$dest_subdir/.hidden.txt" should not exist
        The path "$dest_subdir/subdir/nested.txt" should be file
        The path "$dest_subdir/subdir/.nested_hidden.txt" should not exist

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - -H フラグで隠しファイルを含める'
        # Arrange: ディレクトリ作成（通常ファイル + 隠しファイル）
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        echo "visible" > "$src_dir/visible.txt"
        echo "hidden content" > "$src_dir/.hidden.txt"
        mkdir -p "$src_dir/subdir"
        echo "nested visible" > "$src_dir/subdir/nested.txt"
        echo "nested hidden content" > "$src_dir/subdir/.nested_hidden.txt"

        # Act: main を -R -p -H フラグで実行
        When call main -R -p -H "$src_dir" "$dest_dir"

        # Assert: すべてのファイルがコピーされる
        The status should be success
        The output should include "[INFO] Created directory:"
        dest_subdir="$dest_dir/$(basename "$src_dir")"
        The path "$dest_subdir/visible.txt" should be file
        The path "$dest_subdir/.hidden.txt" should be file
        The path "$dest_subdir/subdir/nested.txt" should be file
        The path "$dest_subdir/subdir/.nested_hidden.txt" should be file
        hidden_content=$(cat "$dest_subdir/.hidden.txt")
        nested_hidden_content=$(cat "$dest_subdir/subdir/.nested_hidden.txt")
        The variable hidden_content should equal "hidden content"
        The variable nested_hidden_content should equal "nested hidden content"

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
      End
    End
  End
End
