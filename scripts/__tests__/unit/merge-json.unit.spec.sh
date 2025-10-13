#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/merge-json.unit.spec.sh
# @(#): ShellSpec unit tests for merge-json.sh core functions
#
# @file merge-json.unit.spec.sh
# @brief ShellSpec unit tests for merge-json.sh core functions
# @description
#   Unit test suite for merge-json.sh including:
#   - Project structure validation (T1)
#   - Script metadata and headers (T1)
#   - Global constants and variables (T1)
#   - Dependency checking (T2)
#   - Argument parsing (T3)
#   - JSON file validation (T4)
#   - JSON merge logic (T5)
#   - Output writing (T6)
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

Describe 'merge-json.sh - Unit Tests'
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
      It 'Then: [正常] - script file exists at scripts/merge-json.sh'
        The path "$SCRIPT" should be exist
      End

      It 'Then: [正常] - test file exists at scripts/__tests__/unit/merge-json.unit.spec.sh'
        The path "./scripts/__tests__/unit/merge-json.unit.spec.sh" should be exist
      End

      It 'Then: [正常] - script has executable permissions'
        The path "$SCRIPT" should be executable
      End
    End
  End

  # ============================================================================
  # Given: Script header and metadata (T1-2)
  # ============================================================================

  Describe 'Given: merge-json.sh header'
    Describe 'When: reading script metadata'
      It 'Then: [正常] - script has shdoc @file annotation'
        When call grep -q '@file merge-json.sh' "$SCRIPT"
        The status should be success
      End

      It 'Then: [正常] - script has @version 1.0.0'
        When call grep -q '@version 1.0.0' "$SCRIPT"
        The status should be success
      End

      It 'Then: [正常] - script has @author atsushifx'
        When call grep -q '@author atsushifx' "$SCRIPT"
        The status should be success
      End

      It 'Then: [正常] - script has MIT license'
        When call grep -q 'MIT License' "$SCRIPT"
        The status should be success
      End
    End
  End

  # ============================================================================
  # Given: Global constants and variables (T1-3)
  # ============================================================================

  Describe 'Given: merge-json.sh constants'
    Describe 'When: script is sourced'
      It 'Then: [正常] - SCRIPT_DIR is set correctly'
        test_script_dir() { [ -n "$SCRIPT_DIR" ]; }
        When call test_script_dir
        The status should be success
      End

      It 'Then: [正常] - VERSION is extracted from header'
        get_version() { echo "$VERSION"; }
        When call get_version
        The output should equal "1.0.0"
      End

      It 'Then: [正常] - SCRIPT_NAME matches basename'
        get_script_name() { echo "$SCRIPT_NAME"; }
        When call get_script_name
        The output should include "merge-json.sh"
      End
    End
  End

  # ============================================================================
  # Given: check_dependencies() function (T2-1)
  # ============================================================================

  Describe 'Given: check_dependencies() function'
    Describe 'When: jq is installed'
      It 'Then: [正常] - returns exit code 0'
        When call check_dependencies
        The status should equal 0
      End

      It 'Then: [正常] - no error message logged'
        test_no_error() { check_dependencies 2>&1; }
        When call test_no_error
        The output should not include "Error"
      End
    End

    Describe 'When: jq is not installed'
      # Mock command function to simulate missing jq (no script reload needed)
      test_without_jq() {
        command() {
          if [ "$2" = "jq" ]; then
            return 1
          else
            builtin command "$@"
          fi
        }
        check_dependencies 2>&1
      }

      It 'Then: [異常] - returns exit code 1'
        When run test_without_jq
        The status should equal 1
        The output should include "Error"
      End

      It 'Then: [異常] - logs error with installation instructions'
        When run test_without_jq
        The status should equal 1
        The output should include "Error"
      End

      It 'Then: [異常] - error includes Windows (scoop install jq)'
        When run test_without_jq
        The status should equal 1
        The output should include "scoop install jq"
      End

      It 'Then: [異常] - error includes macOS (brew install jq)'
        When run test_without_jq
        The status should equal 1
        The output should include "brew install jq"
      End

      It 'Then: [異常] - error includes Linux (apt install jq)'
        When run test_without_jq
        The status should equal 1
        The output should include "apt install jq"
      End
    End
  End
End
