#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/xcp-copy.integration.spec.sh
# @(#): ShellSpec integration tests for xcp.sh copy operations
#
# @file xcp-copy.integration.spec.sh
# @brief ShellSpec integration tests for xcp.sh copy_file and copy_directory functions
# @description
#   Integration test suite for xcp.sh copy operations.
#   Tests file copying modes, attribute preservation, symlink handling, and directory recursion.
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

Describe 'xcp.sh - Integration tests'
  SCRIPT="./scripts/xcp.sh"

  # Load xcp.sh once for all tests
  BeforeAll '. "$SCRIPT" 2>/dev/null || true'

  # ============================================================================
  # Given: copy_file function
  # ============================================================================

  Describe 'Given: file-to-file copy (copy_single_item)'
    BeforeEach 'init_variables'

    Describe 'When: Handling existing files with default MODE_SKIP'
      It 'Then: [正常] - 既存ファイルはデフォルトでスキップし INFO ログに結果を記録する'
        # Arrange: Create source and existing destination with different content
        src_file=$(mktemp)
        dest_file=$(mktemp)
        echo "source content" > "$src_file"
        echo "dest content" > "$dest_file"
        OPERATION_MODE=$MODE_SKIP

        # Act: Call copy_single_item with existing destination
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Destination should remain unchanged
        The status should be success
        The contents of file "$dest_file" should equal "dest content"
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

        # Act: Call copy_single_item with existing destination
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Destination should be updated with source content and log overwrite message
        The status should be success
        The contents of file "$dest_file" should equal "source content"
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
        touch -t 202001010000 "$dest_file"
        src_file=$(mktemp)
        echo "new content" > "$src_file"
        touch -t 202501010000 "$src_file"
        FLAG_VERBOSE=1
        OPERATION_MODE=$MODE_UPDATE

        # Act: Call copy_single_item with source newer than destination
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Destination should be updated with newer source content
        The status should be success
        The contents of file "$dest_file" should equal "new content"
        The output should include "[VERBOSE] Updating"

        # Cleanup
        rm -f "$src_file" "$dest_file"
        FLAG_VERBOSE=0
      End

      It 'Then: [正常] - --update 指定時にソースが新しくない場合はスキップし INFO ログを出力する'
        # Arrange: Create newer destination and older source
        src_file=$(mktemp)
        echo "source content" > "$src_file"
        touch -t 202001010000 "$src_file"
        dest_file=$(mktemp)
        echo "existing content" > "$dest_file"
        touch -t 202501010000 "$dest_file"
        OPERATION_MODE=$MODE_UPDATE

        # Act: Call copy_single_item with older source than destination
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Destination should remain unchanged and skip log emitted
        The status should be success
        The contents of file "$dest_file" should equal "existing content"
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
        OPERATION_MODE=$MODE_BACKUP

        # Act: Call copy_single_item with backup mode
        When call copy_single_item "$src_file" "$dest_file"

        # Assert: Backup is created before copy and both files exist
        The status should be success
        backup_files=( "${dest_file}".bak.* )
        backup_path="${backup_files[0]}"
        backup_count=${#backup_files[@]}
        The variable backup_count should equal "1"
        The path "$backup_path" should be file
        The contents of file "$backup_path" should equal "existing content"
        The path "$dest_file" should be file
        The contents of file "$dest_file" should equal "source content"
        The output should include "[VERBOSE] Backing up:"
        The output should include "[INFO] Backed up:"
        The output should include "[VERBOSE] Copying:"

        # Cleanup
        rm -f "$src_file" "$dest_file" "$backup_path"
        FLAG_VERBOSE=0
      End
    End


    Describe 'When: Handling copy failures with fail-fast'
      It 'Then: [異常] - fail-fast 指定時はエラーで即時停止フラグを立てる'
        missing_src=$(mktemp -u)
        dest_dir=$(mktemp -d)
        FLAG_FAIL_FAST=1
        FLAG_ABORT_REQUESTED=0

        When call copy_single_item "$missing_src" "$dest_dir"

        The status should be failure
        The error should include "Failed to copy"
        The variable FLAG_ABORT_REQUESTED should equal "1"

        FLAG_FAIL_FAST=0
        FLAG_ABORT_REQUESTED=0
        rmdir "$dest_dir"
      End
    End
  End

  # ============================================================================
  # Given: file-to-directory copy (copy_single_item)
  # ============================================================================

  Describe 'Given: file-to-directory copy (copy_single_item)'
    BeforeEach 'init_variables'

    Describe 'When: Copying into existing destination directory'
      It 'Then: [正常] - 既存ディレクトリ配下へファイルを配置する'
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)
        echo "directory copy" > "$src_file"

        When call copy_single_item "$src_file" "$dest_dir"

        The status should be success
        dest_file="$dest_dir/$(basename "$src_file")"
        The path "$dest_file" should be file
        The contents of file "$dest_file" should equal "directory copy"

        rm -f "$src_file"
        rm -rf "$dest_dir"
      End
    End

    Describe 'When: Dereferencing symbolic links during directory copy'
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
        When call copy_single_item "$src_link" "$dest_dir"

        # Assert: Destination should be a regular file with target content
        The status should be success
        dest_file="$dest_dir/$(basename "$src_link")"
        The path "$dest_file" should be file
        file_type=$(command stat -c %F "$dest_file" 2>/dev/null || command stat -f %HT "$dest_file" 2>/dev/null)
        The variable file_type should equal "regular file"
        The contents of file "$dest_file" should equal "symlink target content"
        The output should include "[VERBOSE] Dereferencing symlink"

        # Cleanup
        FLAG_VERBOSE=0
        FLAG_DEREFERENCE=0
        rm -f "$target_file" "$src_link" "$dest_file"
        rmdir "$dest_dir"
      End
    End

  End

  # ============================================================================
  # Given: copy_directory function
  # ============================================================================

  Describe 'Given: directory-to-directory copy (copy_directory_tree)'
    restore_copy_single_item() {
      if declare -f original_copy_single_item >/dev/null; then
        eval "$(declare -f original_copy_single_item | sed '1s/original_copy_single_item/copy_single_item/')"
        unset -f original_copy_single_item
      fi
    }

    BeforeEach 'init_variables'
    AfterEach 'restore_copy_single_item'

    Describe 'When: Recursively copying directories'
      It 'Then: [正常] - サブディレクトリを mkdir -p しながら処理する'
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub1/sub2"
        echo "content" > "$src_dir/sub1/sub2/file.txt"
        FLAG_PARENTS=1
        FLAG_VERBOSE=1

        When call copy_directory_tree "$src_dir" "$dest_dir"

        The status should be success
        The path "$dest_dir/sub1/sub2" should be directory
        The output should match pattern "*[[]VERBOSE[]]*Creating directory:*sub1/sub2*"

        FLAG_VERBOSE=0
        FLAG_PARENTS=0
        rm -rf "$src_dir" "$dest_dir"
      End

      It 'Then: [正常] - ネストしたファイルを copy_single_item へ委譲し内容を保持する'
        src_dir=$(mktemp -d)
        dest_dir=$(mktemp -d)
        mkdir -p "$src_dir/sub1/sub2"
        echo "alpha" > "$src_dir/sub1/sub2/a.txt"
        echo "beta" > "$src_dir/sub1/sub2/b.txt"
        FLAG_PARENTS=1

        eval "$(declare -f copy_single_item | sed '1s/copy_single_item/original_copy_single_item/')"
        copy_single_item_call_count=0
        copy_single_item() {
          copy_single_item_call_count=$((copy_single_item_call_count + 1))
          original_copy_single_item "$1" "$2"
        }

        When call copy_directory_tree "$src_dir" "$dest_dir"

        The status should be success
        The variable copy_single_item_call_count should equal "2"
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

        eval "$(declare -f copy_single_item | sed '1s/copy_single_item/original_copy_single_item/')"
        copy_single_item_fail_count=0
        copy_single_item() {
          copy_single_item_fail_count=$((copy_single_item_fail_count + 1))
          log_error "Simulated copy failure: $1"
          if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
            FLAG_ABORT_REQUESTED=1
          fi
          return 1
        }

        When call copy_directory_tree "$src_dir" "$dest_dir"

        The status should be failure
        The variable copy_single_item_fail_count should equal "1"
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
        When call copy_directory_tree "$src_dir" "$dest_dir"

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
        When call copy_directory_tree "$src_dir" "$dest_dir"

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
        The contents of file "$dest_link" should equal "dereferenced content"

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
        When call copy_directory_tree "$src_dir" "$dest_dir"

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
End
