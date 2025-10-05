#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/functional/xcp-copy-helpers.functional.spec.sh
# @(#): ShellSpec functional tests for xcp.sh copy helper functions
#
# @file xcp-copy-helpers.functional.spec.sh
# @brief ShellSpec functional tests for xcp.sh copy helper functions
# @description
#   Functional test suite for xcp.sh copy helper functions.
#   Tests destination path resolution, copy precondition assessment, and copy operation execution.
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

Describe 'xcp.sh - Copy helper functions'
  SCRIPT="./scripts/xcp.sh"

  # Load xcp.sh once for all tests
  BeforeAll '. "$SCRIPT" 2>/dev/null || true'

  # Reset variables before each test
  BeforeEach 'init_variables'

  # ============================================================================
  # Given: File copy helper functions
  # ============================================================================

  Describe 'Given: File copy helper functions'
    setup_copy_helpers() {
      FLAG_VERBOSE=0
      FLAG_DRY_RUN=0
      FLAG_DEREFERENCE=0
      FLAG_FAIL_FAST=0
      FLAG_ABORT_REQUESTED=0
      OPERATION_MODE=$MODE_SKIP
      unset -f cp >/dev/null 2>&1 || true
      unset -f backup_file >/dev/null 2>&1 || true
    }

    cleanup_copy_helpers() {
      unset -f cp >/dev/null 2>&1 || true
      unset -f backup_file >/dev/null 2>&1 || true
      FLAG_ABORT_REQUESTED=0
      FLAG_FAIL_FAST=0
      FLAG_DRY_RUN=0
      FLAG_DEREFERENCE=0
      OPERATION_MODE=$MODE_SKIP
    }

    BeforeEach 'setup_copy_helpers'
    AfterEach 'cleanup_copy_helpers'

    Describe 'When: Resolving destination paths'
      It 'Then: [正常] - ディレクトリ指定時はファイル名を結合する'
        src_file=$(mktemp)
        dest_dir=$(mktemp -d)

        result=$(resolve_destination_path "$src_file" "$dest_dir")

        The variable result should equal "$dest_dir/$(basename "$src_file")"

        rm -rf "$src_file" "$dest_dir"
      End

      It 'Then: [正常] - ファイル指定時はそのままのパスを返す'
        src_file=$(mktemp)
        dest_file=$(mktemp)

        result=$(resolve_destination_path "$src_file" "$dest_file")

        The variable result should equal "$dest_file"

        rm -f "$src_file" "$dest_file"
      End
    End

    Describe 'When: Assessing copy preconditions'
      It 'Then: [正常] - 宛先が存在しない場合はコピー続行を許可する'
        src_file=$(mktemp)
        dest_file=$(mktemp -u)

        When call assess_copy_preconditions "$src_file" "$dest_file"

        The status should be success

        rm -f "$src_file"
      End

      It 'Then: [正常] - MODE_SKIP では既存ファイルをスキップする'
        src_file=$(mktemp)
        dest_file=$(mktemp)
        OPERATION_MODE=$MODE_SKIP

        When call assess_copy_preconditions "$src_file" "$dest_file"

        The status should equal 1
        The output should include "[INFO] Skipped (exists)"

        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - MODE_UPDATE でソースが新しい場合は続行する'
        dest_file=$(mktemp)
        echo "old" > "$dest_file"
        sleep 1
        src_file=$(mktemp)
        echo "new" > "$src_file"
        OPERATION_MODE=$MODE_UPDATE

        When call assess_copy_preconditions "$src_file" "$dest_file"

        The status should be success

        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - MODE_UPDATE でソースが新しくない場合はスキップする'
        src_file=$(mktemp)
        echo "src" > "$src_file"
        sleep 1
        dest_file=$(mktemp)
        echo "dest" > "$dest_file"
        OPERATION_MODE=$MODE_UPDATE

        When call assess_copy_preconditions "$src_file" "$dest_file"

        The status should equal 1
        The output should include "[INFO] Skipped (not newer)"

        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - MODE_BACKUP でバックアップ成功時は続行する'
        src_file=$(mktemp)
        dest_file=$(mktemp)
        OPERATION_MODE=$MODE_BACKUP
        backup_called=0
        backup_file() {
          backup_called=1
          return 0
        }

        When call assess_copy_preconditions "$src_file" "$dest_file"

        The status should be success
        The variable backup_called should equal "1"

        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [異常] - MODE_BACKUP でバックアップ失敗時は 2 を返す'
        src_file=$(mktemp)
        dest_file=$(mktemp)
        OPERATION_MODE=$MODE_BACKUP
        backup_file() { return 1; }

        When call assess_copy_preconditions "$src_file" "$dest_file"

        The status should equal 2

        rm -f "$src_file" "$dest_file"
      End
    End

    Describe 'When: Performing copy operations'
      It 'Then: [正常] - シンボリックリンク保持時は -P フラグを付与する'
        src_file=$(mktemp)
        dest_file=$(mktemp -u)
        FLAG_DEREFERENCE=0
        cp_args=""
        cp() {
          cp_args="$*"
          command cp "$@"
        }

        When call perform_copy_operation "$src_file" "$dest_file"

        The status should be success
        The variable cp_args should include "-P"

        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - シンボリックリンク解決時は -L フラグを付与する'
        src_file=$(mktemp)
        dest_file=$(mktemp -u)
        FLAG_DEREFERENCE=1
        cp_args=""
        cp() {
          cp_args="$*"
          command cp "$@"
        }

        When call perform_copy_operation "$src_file" "$dest_file"

        The status should be success
        The variable cp_args should include "-L"

        rm -f "$src_file" "$dest_file"
      End

      It 'Then: [正常] - ドライラン時はコマンドをログに出力する'
        src_file=$(mktemp)
        dest_file=$(mktemp -u)
        FLAG_DRY_RUN=1
        cp() { return 1; }

        When call perform_copy_operation "$src_file" "$dest_file"

        The status should be success
        The output should include "[DRY-RUN] cp"

        rm -f "$src_file"
      End

      It 'Then: [異常] - コピー失敗時に fail-fast 指定なら停止フラグを立てる'
        src_file=$(mktemp)
        dest_file=$(mktemp -u)
        FLAG_FAIL_FAST=1
        FLAG_ABORT_REQUESTED=0
        cp() { return 1; }

        When call perform_copy_operation "$src_file" "$dest_file"

        The status should be failure
        The variable FLAG_ABORT_REQUESTED should equal "1"
        The error should include "Failed to copy"

        rm -f "$src_file"
      End

      It 'Then: [異常] - ディスク容量不足時にエラーログを出力する'
        # Arrange: ファイル準備
        src_file=$(mktemp)
        dest_file=$(mktemp -u)
        echo "test content" > "$src_file"

        # cp コマンドをMock: ENOSPC (No space left on device) シミュレート
        cp() {
          echo "cp: error writing '$2': No space left on device" >&2
          return 1
        }

        # Act: コピー操作実行
        When call perform_copy_operation "$src_file" "$dest_file"

        # Assert: エラーログ出力、失敗ステータス
        The status should be failure
        The error should include "Failed to copy"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        rm -f "$src_file"
      End

      It 'Then: [異常] - ディスク容量不足時に fail-fast なら即座に停止する'
        # Arrange: ファイル準備とfail-fast有効化
        src_file=$(mktemp)
        dest_file=$(mktemp -u)
        echo "test content" > "$src_file"
        FLAG_FAIL_FAST=1
        FLAG_ABORT_REQUESTED=0

        # cp コマンドをMock: ENOSPC シミュレート
        cp() {
          echo "cp: write error: No space left on device" >&2
          return 1
        }

        # Act: コピー操作実行
        When call perform_copy_operation "$src_file" "$dest_file"

        # Assert: エラーログ、fail-fastフラグ設定
        The status should be failure
        The error should include "Failed to copy"
        The variable FLAG_ABORT_REQUESTED should equal "1"
        The result of function logger_get_error_count should equal 1

        # Cleanup
        FLAG_FAIL_FAST=0
        FLAG_ABORT_REQUESTED=0
        rm -f "$src_file"
      End
    End
  End
End
