#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/merge-json-metadata.unit.spec.sh
# @(#): ShellSpec unit tests for merge-json.sh metadata and structure
#
# @file merge-json-metadata.unit.spec.sh
# @brief ShellSpec unit tests for merge-json.sh metadata and structure
# @description
#   Unit test suite for merge-json.sh including:
#   - Project structure validation (T1-1)
#   - Script metadata and headers (T1-2)
#   - Global constants and variables (T1-3)
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

Describe 'merge-json.sh - Metadata and Structure Tests'
  SCRIPT="./scripts/merge-json.sh"

  # ============================================================================
  # Setup: Source script once for all tests
  # ============================================================================

  BeforeAll '. "$SCRIPT" 2>/dev/null || true'

  # ============================================================================
  # Given: Project structure (T1-1)
  # ============================================================================

  Describe 'Given: merge-json.sh project structure'
    Describe 'When: project is initialized'
      It 'Then: [正常] - script file exists with executable permissions'
        The path "$SCRIPT" should be exist
        The path "$SCRIPT" should be executable
      End
    End
  End

  # ============================================================================
  # Given: Script header and metadata (T1-2)
  # ============================================================================

  Describe 'Given: merge-json.sh header'
    Describe 'When: reading script metadata'
      It 'Then: [正常] - script has required shdoc annotations and license'
        When call grep -E '@file|@version|@author|MIT License' "$SCRIPT"
        The status should be success
        The output should include "@file merge-json.sh"
        The output should include "@version 1.0.0"
        The output should include "@author atsushifx"
        The output should include "MIT License"
      End
    End
  End

  # ============================================================================
  # Given: Global constants and variables (T1-3)
  # ============================================================================

  Describe 'Given: merge-json.sh constants'
    Describe 'When: script is sourced'
      It 'Then: [正常] - SCRIPT_DIR is set'
        test_script_dir() { [ -n "$SCRIPT_DIR" ]; }
        When call test_script_dir
        The status should be success
      End

      It 'Then: [正常] - VERSION is 1.0.0'
        get_version() { echo "$VERSION"; }
        When call get_version
        The output should equal "1.0.0"
      End

      It 'Then: [正常] - SCRIPT_NAME is merge-json.sh'
        get_script_name() { echo "$SCRIPT_NAME"; }
        When call get_script_name
        The output should include "merge-json.sh"
      End
    End
  End
End
