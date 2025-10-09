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

        # Override parse_args to set SOURCE_ARGS, DEST_ARG, and flags
        parse_args() {
          SOURCE_ARGS=("$src_file")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
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

        # Override parse_args to set flags and arguments
        parse_args() {
          SOURCE_ARGS=("$src_dir")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
          FLAG_RECURSIVE=1
          return 0
        }

        # Act: Call main with source directory
        When call main "$src_dir" "$dest_dir"

        # Assert: Directory should be recursively copied
        The status should be success
        The output should include "[INFO] Created directory:"
        dest_subdir="$dest_dir/$(basename "$src_dir")"
        The path "$dest_subdir/file.txt" should be file
        The path "$dest_subdir/subdir/nested.txt" should be file

        # Cleanup
        FLAG_PARENTS=0
        FLAG_RECURSIVE=0
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

        # Override parse_args
        parse_args() {
          SOURCE_ARGS=("$src1" "$src2")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
          return 0
        }

        # Act: Call main with multiple sources
        When call main "$src1" "$src2" "$dest_dir"

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
        FLAG_PARENTS=0
        rm -rf "$src1" "$src2" "$dest_dir"
      End
    End

    Describe 'When: Reporting errors and exit codes'
      It 'Then: [正常] - returns exit code 0 when all operations succeed'
        # Arrange: Create valid source and destination
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "success content" > "$src_file"

        # Override parse_args
        parse_args() {
          SOURCE_ARGS=("$src_file")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
          return 0
        }

        # Act: Call main with valid inputs
        When call main "$src_file" "$dest_dir"

        # Assert: Should return success (0)
        The status should be success

        # Cleanup
        FLAG_PARENTS=0
        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [異常] - displays error count message when errors occur'
        # Arrange: Create source files where one will fail
        src1=$(mktemp)
        src2=$(mktemp -u)  # Non-existent file to cause error
        dest_dir=$(mktemp -d)
        echo "content1" > "$src1"

        # Override parse_args to set multiple sources
        parse_args() {
          SOURCE_ARGS=("$src1" "$src2")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
          return 0
        }

        # Act: Call main with sources where one fails
        When call main "$src1" "$src2" "$dest_dir"

        # Assert: Should display error count message
        The status should be failure
        The error should include "[ERROR] Completed with"
        The error should include "error(s)"

        # Cleanup
        FLAG_PARENTS=0
        rm -rf "$src1" "$dest_dir"
      End

      It 'Then: [異常] - returns exit code 1 when errors occur'
        # Arrange: Create scenario with non-existent source
        missing_src=$(mktemp -u)
        dest_dir=$(mktemp -d)

        # Override parse_args
        parse_args() {
          SOURCE_ARGS=("$missing_src")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
          return 0
        }

        # Act: Call main with missing source
        When call main "$missing_src" "$dest_dir"

        # Assert: Should return exit code 1
        The status should be failure
        The error should include "[ERROR]"

        # Cleanup
        FLAG_PARENTS=0
        rm -rf "$dest_dir"
      End

      It 'Then: [正常] - displays consistent summary in dry-run mode'
        # Arrange: Create test file for dry-run
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "dry-run content" > "$src_file"

        # Override parse_args
        parse_args() {
          SOURCE_ARGS=("$src_file")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
          FLAG_DRY_RUN=1
          return 0
        }

        # Act: Call main in dry-run mode
        When call main "$src_file" "$dest_dir"

        # Assert: Should succeed and show dry-run logs
        The status should be success
        The output should include "[DRY-RUN]"

        # Cleanup
        FLAG_PARENTS=0
        FLAG_DRY_RUN=0
        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [異常] - fail-fast mode stops on first error'
        # Arrange: Create files where first will fail
        src1=$(mktemp -u)  # Non-existent to cause immediate error
        src2=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "content2" > "$src2"

        # Override parse_args
        parse_args() {
          SOURCE_ARGS=("$src1" "$src2")
          DEST_ARG="$dest_dir"
          FLAG_PARENTS=1
          FLAG_FAIL_FAST=1
          return 0
        }

        # Act: Call main with fail-fast enabled
        When call main "$src1" "$src2" "$dest_dir"

        # Assert: Should fail on first error
        The status should be failure
        The error should include "[ERROR]"

        # Cleanup
        FLAG_PARENTS=0
        FLAG_FAIL_FAST=0
        rm -rf "$src2" "$dest_dir"
      End
    End
  End
End
