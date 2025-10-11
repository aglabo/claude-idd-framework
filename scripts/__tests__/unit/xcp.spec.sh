#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/xcp.spec.sh
# @(#): ShellSpec unit tests for xcp.sh core functions
#
# @file xcp.spec.sh
# @brief ShellSpec unit tests for xcp.sh core functions
# @description
#   Unit test suite for xcp.sh core functions including:
#   - Path resolution (resolve_destination_path)
#   - Copy precondition assessment (assess_copy_preconditions)
#   - Copy operations (perform_copy_operation, copy_single_item, copy_directory_tree)
#   - Argument parsing (parse_args, show_help, show_version)
#   - Main processing (main)
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

Describe 'xcp.sh - Core Functions Unit Tests'
  SCRIPT="./scripts/xcp.sh"

  # ============================================================================
  # Given: Path Resolution Functions
  # ============================================================================

  Describe 'Given: Path resolution function (resolve_destination_path)'
    Describe 'When: Resolving destination path'
      It 'Then: [正常] - Append source filename when destination is a directory'
        # Arrange: Create destination directory
        . "$SCRIPT" 2>/dev/null || true
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)

        # Act: Call resolve_destination_path
        When call resolve_destination_path "$src_file" "$dest_dir"

        # Assert: Should return dest_dir/basename(src_file)
        expected="$dest_dir/$(basename "$src_file")"
        The output should equal "$expected"
        The status should be success

        # Cleanup
        rm -f "$src_file"
        rm -rf "$dest_dir"
      End

      It 'Then: [正常] - Return destination path as-is when destination is not a directory'
        # Arrange: Use file as destination
        . "$SCRIPT" 2>/dev/null || true
        src_file=$(mktemp)
        dest_file="/path/to/dest/file.txt"

        # Act: Call resolve_destination_path
        When call resolve_destination_path "$src_file" "$dest_file"

        # Assert: Should return dest_file unchanged
        The output should equal "$dest_file"
        The status should be success

        # Cleanup
        rm -f "$src_file"
      End
    End
  End

  # ============================================================================
  # Given: Copy Precondition Assessment Functions
  # ============================================================================

  Describe 'Given: Copy precondition assessment function (assess_copy_preconditions)'
    Describe 'When: Assessing copy preconditions'
      It 'Then: [正常] - Return 0 when destination does not exist (proceed with copy)'
        # Arrange: Use nonexistent destination
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_file=$(mktemp)
        dest_file="$(mktemp -u)"
        OPERATION_MODE=$MODE_SKIP

        # Act: Call assess_copy_preconditions
        When call assess_copy_preconditions "$src_file" "$dest_file"

        # Assert: Should return 0 (proceed)
        The status should be success

        # Cleanup
        rm -f "$src_file"
      End

      It 'Then: [正常] - Return 1 when MODE_SKIP and destination exists (skip)'
        # Arrange: Create existing destination
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_file=$(mktemp)
        dest_file=$(mktemp)
        OPERATION_MODE=$MODE_SKIP

        # Act: Call assess_copy_preconditions
        When call assess_copy_preconditions "$src_file" "$dest_file"

        # Assert: Should return 1 (skip) and log info
        The status should be failure
        The output should include "Skipped (exists)"

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - Return 0 when MODE_OVERWRITE and destination exists (overwrite)'
        # Arrange: Create existing destination
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_file=$(mktemp)
        dest_file=$(mktemp)
        OPERATION_MODE=$MODE_OVERWRITE

        # Act: Call assess_copy_preconditions
        When call assess_copy_preconditions "$src_file" "$dest_file"

        # Assert: Should return 0 (proceed with overwrite)
        The status should be success

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - Return 0 when MODE_UPDATE and source is newer (update)'
        # Arrange: Create older destination and newer source
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        dest_file=$(mktemp)
        echo "dest" > "$dest_file"
        sleep 1
        src_file=$(mktemp)
        echo "src" > "$src_file"
        OPERATION_MODE=$MODE_UPDATE

        # Act: Call assess_copy_preconditions
        When call assess_copy_preconditions "$src_file" "$dest_file"

        # Assert: Should return 0 (proceed with update)
        The status should be success

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - Return 1 when MODE_UPDATE and source is not newer (skip)'
        # Arrange: Create newer destination and older source
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_file=$(mktemp)
        echo "src" > "$src_file"
        sleep 1
        dest_file=$(mktemp)
        echo "dest" > "$dest_file"
        OPERATION_MODE=$MODE_UPDATE

        # Act: Call assess_copy_preconditions
        When call assess_copy_preconditions "$src_file" "$dest_file"

        # Assert: Should return 1 (skip) and log info
        The status should be failure
        The output should include "Skipped (not newer)"

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - Return 0 when MODE_BACKUP and backup succeeds (proceed)'
        # Arrange: Create destination to backup
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "dest content" > "$dest_file"
        OPERATION_MODE=$MODE_BACKUP

        # Act: Call assess_copy_preconditions
        When call assess_copy_preconditions "$src_file" "$dest_file"

        # Assert: Should return 0 (proceed after backup)
        The status should be success
        backup_path=$(echo "$dest_file".bak.*)
        The path "$backup_path" should be file

        # Cleanup
        rm -f "$src_file" "$backup_path"
      End

      It 'Then: [異常] - Return 2 when MODE_BACKUP and backup fails (abort)'
        Skip "Test causes infinite loop - needs investigation"

        # Arrange: Mock backup_file to fail
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_file=$(mktemp)
        dest_file=$(mktemp)
        OPERATION_MODE=$MODE_BACKUP

        # Act: assess_copy_preconditions calls backup_file which should fail
        # Expected: Should return 2 (abort)

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End
    End
  End

  # ============================================================================
  # Given: Copy Operation Functions
  # ============================================================================

  Describe 'Given: Copy operation function (perform_copy_operation)'
    Describe 'When: Performing copy operation'
      It 'Then: [正常] - Preserve symlinks when FLAG_DEREFERENCE=0'
        # Arrange: Create symlink
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DEREFERENCE=0
        export MSYS=winsymlinks:nativestrict
        test_dir=$(mktemp -d)
        target_file="$test_dir/target.txt"
        src_link="$test_dir/link"
        dest_file="$test_dir/dest"
        echo "content" > "$target_file"

        if ! ln -s "$target_file" "$src_link" 2>/dev/null; then
          Skip "Symbolic links not supported"
          rm -rf "$test_dir"
          return 0
        fi

        # Act: Call perform_copy_operation
        When call perform_copy_operation "$src_link" "$dest_file"

        # Assert: Should copy with -P flag (preserve symlink)
        The status should be success
        [[ -L "$dest_file" ]] && symlink_status=1 || symlink_status=0
        The variable symlink_status should equal 1

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [正常] - Dereference symlinks when FLAG_DEREFERENCE=1'
        # Arrange: Create symlink
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DEREFERENCE=1
        export MSYS=winsymlinks:nativestrict
        test_dir=$(mktemp -d)
        target_file="$test_dir/target.txt"
        src_link="$test_dir/link"
        dest_file="$test_dir/dest"
        echo "dereferenced content" > "$target_file"

        if ! ln -s "$target_file" "$src_link" 2>/dev/null; then
          Skip "Symbolic links not supported"
          rm -rf "$test_dir"
          return 0
        fi

        # Act: Call perform_copy_operation
        When call perform_copy_operation "$src_link" "$dest_file"

        # Assert: Should copy with -L flag (dereference symlink)
        The status should be success
        [[ ! -L "$dest_file" && -f "$dest_file" ]] && regular_file=1 || regular_file=0
        The variable regular_file should equal 1
        content=$(cat "$dest_file")
        The variable content should equal "dereferenced content"

        # Cleanup
        rm -rf "$test_dir"
      End

      It 'Then: [正常] - Emit dry-run log when FLAG_DRY_RUN=1'
        # Arrange: Set FLAG_DRY_RUN=1
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DRY_RUN=1
        FLAG_DEREFERENCE=0
        src_file=$(mktemp)
        dest_file="/path/to/dest"

        # Act: Call perform_copy_operation
        When call perform_copy_operation "$src_file" "$dest_file"

        # Assert: Should output dry-run log and not copy
        The status should be success
        The output should include "[DRY-RUN] cp"
        The path "$dest_file" should not exist

        # Cleanup
        rm -f "$src_file"
        FLAG_DRY_RUN=0
      End

      It 'Then: [正常] - Return success when copy succeeds'
        # Arrange: Create source file
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DEREFERENCE=0
        src_file=$(mktemp)
        dest_file=$(mktemp -u)
        echo "content" > "$src_file"

        # Act: Call perform_copy_operation
        When call perform_copy_operation "$src_file" "$dest_file"

        # Assert: Should return success and copy file
        The status should be success
        The path "$dest_file" should be file
        content=$(cat "$dest_file")
        The variable content should equal "content"

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [異常] - Return failure and log error when copy fails'
        # Arrange: Mock cp to fail
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DEREFERENCE=0
        FLAG_FAIL_FAST=0
        src_file=$(mktemp)
        dest_file="/path/to/dest"

        cp() { return 1; }

        # Act: Call perform_copy_operation
        When call perform_copy_operation "$src_file" "$dest_file"

        # Assert: Should return failure and log error
        The status should be failure
        The error should include "Failed to copy"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        rm -f "$src_file"
      End

      It 'Then: [異常] - Set FLAG_ABORT_REQUESTED when FLAG_FAIL_FAST=1 and copy fails'
        # Arrange: Mock cp to fail
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DEREFERENCE=0
        FLAG_FAIL_FAST=1
        FLAG_ABORT_REQUESTED=0
        src_file=$(mktemp)
        dest_file="/path/to/dest"

        cp() { return 1; }

        # Act: Call perform_copy_operation
        When call perform_copy_operation "$src_file" "$dest_file"

        # Assert: Should set FLAG_ABORT_REQUESTED
        The status should be failure
        The variable FLAG_ABORT_REQUESTED should equal 1

        # Cleanup
        rm -f "$src_file"
        FLAG_FAIL_FAST=0
      End
    End
  End

  Describe 'Given: Single item copy function (copy_single_item)'
    Describe 'When: Copying single file or symlink'
      It 'Then: [正常] - Copy file to destination'
        # Arrange: Create source and destination
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        OPERATION_MODE=$MODE_SKIP
        FLAG_DEREFERENCE=0
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "test content" > "$src_file"

        # Act: Call copy_single_item
        When call copy_single_item "$src_file" "$dest_dir"

        # Assert: Should copy file
        The status should be success
        dest_file="$dest_dir/$(basename "$src_file")"
        The path "$dest_file" should be file
        content=$(cat "$dest_file")
        The variable content should equal "test content"

        # Cleanup
        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [正常] - Skip existing file when MODE_SKIP'
        # Arrange: Create existing destination
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        OPERATION_MODE=$MODE_SKIP
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "src" > "$src_file"
        echo "dest" > "$dest_file"
        original_content=$(cat "$dest_file")

        # Act: Call copy_single_item
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Should skip and keep original
        The status should be success
        new_content=$(cat "$dest_file")
        The variable new_content should equal "$original_content"

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - Overwrite existing file when MODE_OVERWRITE'
        # Arrange: Create existing destination
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        OPERATION_MODE=$MODE_OVERWRITE
        FLAG_DEREFERENCE=0
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "new content" > "$src_file"
        echo "old content" > "$dest_file"

        # Act: Call copy_single_item
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Should overwrite
        The status should be success
        new_content=$(cat "$dest_file")
        The variable new_content should equal "new content"

        # Cleanup
        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [異常] - Return failure when copy operation fails'
        # Arrange: Mock perform_copy_operation to fail
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        OPERATION_MODE=$MODE_SKIP
        src_file=$(mktemp)
        dest_file=$(mktemp -u)

        perform_copy_operation() { return 1; }

        # Act: Call copy_single_item
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Should return failure
        The status should be failure

        # Cleanup
        rm -f "$src_file"
      End
    End
  End

  # ============================================================================
  # Given: Directory Copy Functions
  # ============================================================================

  Describe 'Given: Directory copy function (copy_directory_tree)'
    Describe 'When: Copying directory tree recursively'
      It 'Then: [正常] - Create subdirectories in destination'
        # Arrange: Create source directory with subdirectories
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        FLAG_DEREFERENCE=0
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub1/sub2"

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_dir" "$dest_dir"

        # Assert: Should create subdirectories
        The status should be success
        The path "$dest_dir/sub1/sub2" should be directory

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - Copy all files in directory tree'
        # Arrange: Create source directory with files
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        FLAG_DEREFERENCE=0
        OPERATION_MODE=$MODE_SKIP
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub"
        echo "file1" > "$src_dir/file1.txt"
        echo "file2" > "$src_dir/sub/file2.txt"

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_dir" "$dest_dir"

        # Assert: Should copy all files
        The status should be success
        The path "$dest_dir/file1.txt" should be file
        The path "$dest_dir/sub/file2.txt" should be file
        content1=$(cat "$dest_dir/file1.txt")
        The variable content1 should equal "file1"

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - Preserve symlinks when FLAG_DEREFERENCE=0'
        # Arrange: Create directory with symlink
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        FLAG_DEREFERENCE=0
        OPERATION_MODE=$MODE_SKIP
        export MSYS=winsymlinks:nativestrict
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        target_file="$src_dir/target.txt"
        src_link="$src_dir/link"
        echo "content" > "$target_file"

        if ! ln -s "$target_file" "$src_link" 2>/dev/null; then
          Skip "Symbolic links not supported"
          rm -rf "$src_dir" "$dest_dir"
          return 0
        fi

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_dir" "$dest_dir"

        # Assert: Should preserve symlink
        The status should be success
        dest_link="$dest_dir/link"
        [[ -L "$dest_link" ]] && symlink_status=1 || symlink_status=0
        The variable symlink_status should equal 1

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - Dereference symlinks when FLAG_DEREFERENCE=1'
        # Arrange: Create directory with symlink
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_PARENTS=1
        FLAG_DEREFERENCE=1
        OPERATION_MODE=$MODE_SKIP
        export MSYS=winsymlinks:nativestrict
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        target_file="$src_dir/target.txt"
        src_link="$src_dir/link"
        echo "dereferenced" > "$target_file"

        if ! ln -s "$target_file" "$src_link" 2>/dev/null; then
          Skip "Symbolic links not supported"
          rm -rf "$src_dir" "$dest_dir"
          return 0
        fi

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_dir" "$dest_dir"

        # Assert: Should dereference symlink
        The status should be success
        dest_link="$dest_dir/link"
        [[ ! -L "$dest_link" && -f "$dest_link" ]] && regular_file=1 || regular_file=0
        The variable regular_file should equal 1

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - Emit dry-run logs when FLAG_DRY_RUN=1'
        # Arrange: Set FLAG_DRY_RUN=1
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_DRY_RUN=1
        FLAG_PARENTS=1
        FLAG_DEREFERENCE=0
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub"

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_dir" "$dest_dir"

        # Assert: Should output dry-run logs
        The status should be success
        The output should include "[DRY-RUN] find"

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
        FLAG_DRY_RUN=0
      End

      It 'Then: [異常] - Return failure when source does not exist'
        # Arrange: Use nonexistent source
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_dir="/nonexistent/directory"
        dest_dir=$(mktemp -d)

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_dir" "$dest_dir"

        # Assert: Should return failure
        The status should be failure
        The error should include "Source not found"

        # Cleanup
        rm -rf "$dest_dir"
      End

      It 'Then: [異常] - Return failure when source is not a directory'
        # Arrange: Use file as source
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_file" "$dest_dir"

        # Assert: Should return failure
        The status should be failure
        The error should include "not a directory"

        # Cleanup
        rm -f "$src_file"
        rm -rf "$dest_dir"
      End

      It 'Then: [異常] - Stop immediately when FLAG_FAIL_FAST=1 and error occurs'
        # Arrange: Mock copy_single_item to fail
        . "$SCRIPT" 2>/dev/null || true
        logger_init
        FLAG_FAIL_FAST=1
        FLAG_PARENTS=1
        FLAG_DEREFERENCE=0
        FLAG_ABORT_REQUESTED=0
        OPERATION_MODE=$MODE_SKIP
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        echo "file1" > "$src_dir/file1.txt"
        echo "file2" > "$src_dir/file2.txt"

        copy_single_item() {
          log_error "Simulated failure"
          FLAG_ABORT_REQUESTED=1
          return 1
        }

        # Act: Call copy_directory_tree
        When call copy_directory_tree "$src_dir" "$dest_dir"

        # Assert: Should stop after first failure
        The status should be failure
        The variable FLAG_ABORT_REQUESTED should equal 1

        # Cleanup
        rm -rf "$src_dir" "$dest_dir"
        FLAG_FAIL_FAST=0
      End
    End
  End
End
