#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/merge-json-args.unit.spec.sh
# @(#): ShellSpec unit tests for merge-json.sh argument parsing and UI
#
# @file merge-json-args.unit.spec.sh
# @brief ShellSpec unit tests for merge-json.sh argument parsing and UI
# @description
#   Unit test suite for merge-json.sh including:
#   - Dependency checking (T2)
#   - Help/version display (T3-1, T3-2)
#   - Argument parsing (T3-3, T3-4)
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

Describe 'merge-json.sh - Argument Parsing and UI Tests'
  SCRIPT="./scripts/merge-json.sh"

  # ============================================================================
  # Setup: Source script once for all tests
  # ============================================================================

  BeforeAll '. "$SCRIPT" 2>/dev/null || true'

  # ============================================================================
  # Given: check_dependencies() function (T2-1)
  # ============================================================================

  Describe 'Given: check_dependencies() function'
    Describe 'When: jq is installed'
      It 'Then: [正常] - returns exit code 0 without errors'
        When call check_dependencies
        The status should equal 0
      End
    End

    Describe 'When: jq is not installed'
      # Mock command function to simulate missing jq
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

      It 'Then: [異常] - returns exit code 1 with installation instructions'
        When run test_without_jq
        The status should equal 1
        The output should include "Error"
        The output should include "scoop install jq"
        The output should include "brew install jq"
        The output should include "apt install jq"
      End
    End
  End

  # ============================================================================
  # Given: show_help() function (T3-1)
  # ============================================================================

  Describe 'Given: show_help() function'
    Describe 'When: help is requested'
      It 'Then: [正常] - displays complete help with usage, options, and examples'
        When call show_help
        The output should include "Usage:"
        The output should include "FILE1"
        The output should include "FILE2"
        The output should include "-o"
        The output should include "-h"
        The output should include "-v"
        The output should include "Exit Codes"
        The output should include "Examples"
      End
    End
  End

  # ============================================================================
  # Given: show_version() function (T3-2)
  # ============================================================================

  Describe 'Given: show_version() function'
    Describe 'When: version is requested'
      It 'Then: [正常] - displays version with copyright and license'
        When call show_version
        The output should include "merge-json.sh"
        The output should include "version"
        The output should include "Copyright"
        The output should include "MIT"
        The output should include "github.com"
      End
    End
  End

  # ============================================================================
  # Given: parse_args() function (T3-3)
  # ============================================================================

  Describe 'Given: parse_args() function'
    Describe 'When: valid arguments provided'
      It 'Then: [正常] - sets FILE1, FILE2, and returns exit code 0'
        parse_args "file1.json" "file2.json"
        test_basic_args() { echo "$FILE1:$FILE2:$OUTPUT_FILE"; }
        When call test_basic_args
        The output should equal "file1.json:file2.json:"
      End
    End
  End

  # ============================================================================
  # Given: parse_args() function with options (T3-4)
  # ============================================================================

  Describe 'Given: parse_args() function with options'
    Describe 'When: -o option provided'
      It 'Then: [正常] - sets OUTPUT_FILE with short and long syntax'
        parse_args "file1.json" "file2.json" "-o" "output.json"
        test_output_short() { echo "$OUTPUT_FILE"; }
        When call test_output_short
        The output should equal "output.json"
      End

      It 'Then: [正常] - accepts --output long form'
        parse_args "file1.json" "file2.json" "--output" "merged.json"
        test_output_long() { echo "$OUTPUT_FILE"; }
        When call test_output_long
        The output should equal "merged.json"
      End
    End

    Describe 'When: -h or --help option provided'
      It 'Then: [正常] - displays help and returns exit code 2'
        test_help() { parse_args "-h" 2>&1; }
        When call test_help
        The status should equal 2
        The output should include "Usage:"
      End

      It 'Then: [正常] - accepts --help long form'
        test_help_long() { parse_args "--help" 2>&1; }
        When call test_help_long
        The status should equal 2
        The output should include "Usage:"
      End
    End

    Describe 'When: -v or --version option provided'
      It 'Then: [正常] - displays version and returns exit code 2'
        test_version() { parse_args "-v" 2>&1; }
        When call test_version
        The status should equal 2
        The output should include "version"
      End

      It 'Then: [正常] - accepts --version long form'
        test_version_long() { parse_args "--version" 2>&1; }
        When call test_version_long
        The status should equal 2
        The output should include "version"
      End
    End

    Describe 'When: mixed arguments provided'
      It 'Then: [正常] - parses file1 file2 -o output.json'
        parse_args "base.json" "override.json" "-o" "result.json"
        test_mixed() { echo "$FILE1:$FILE2:$OUTPUT_FILE"; }
        When call test_mixed
        The output should equal "base.json:override.json:result.json"
      End

      It 'Then: [正常] - parses -o output.json file1 file2 (options first)'
        parse_args "-o" "result.json" "base.json" "override.json"
        test_options_first() { echo "$FILE1:$FILE2:$OUTPUT_FILE"; }
        When call test_options_first
        The output should equal "base.json:override.json:result.json"
      End
    End
  End
End
