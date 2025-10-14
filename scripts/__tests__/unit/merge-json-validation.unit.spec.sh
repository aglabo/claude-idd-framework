#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/merge-json-validation.unit.spec.sh
# @(#): ShellSpec unit tests for merge-json.sh JSON validation
#
# @file merge-json-validation.unit.spec.sh
# @brief ShellSpec unit tests for merge-json.sh JSON validation
# @description
#   Unit test suite for merge-json.sh including:
#   - JSON data validation (T-REF-1)
#   - JSON file loading (T-REF-2)
#   - JSON file validation (T4-1)
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

Describe 'merge-json.sh - JSON Validation Tests'
  SCRIPT="./scripts/merge-json.sh"

  # ============================================================================
  # Setup: Source script once for all tests
  # ============================================================================

  BeforeAll '. "$SCRIPT" 2>/dev/null || true'

  # ============================================================================
  # Given: validate_json_data() function (T-REF-1)
  # ============================================================================

  Describe 'Given: validate_json_data() function'
    Describe 'When: valid JSON object string provided'
      It 'Then: [正常] - returns exit code 0'
        When call validate_json_data '{"key": "value"}'
        The status should equal 0
      End
    End

    Describe 'When: invalid JSON string provided'
      It 'Then: [異常] - returns exit code 3'
        When call validate_json_data '{invalid}'
        The status should equal 3
        The stderr should include "Error: Invalid JSON"
      End
    End

    Describe 'When: JSON array string provided'
      It 'Then: [異常] - returns exit code 4'
        When call validate_json_data '["item1", "item2"]'
        The status should equal 4
        The stderr should include "Error: JSON root must be an object"
      End
    End

    Describe 'When: JSON primitive provided'
      It 'Then: [異常] - returns exit code 4 for string'
        When call validate_json_data '"text"'
        The status should equal 4
        The stderr should include "Error: JSON root must be an object"
      End
    End

    Describe 'When: empty object provided'
      It 'Then: [エッジケース] - returns exit code 0'
        When call validate_json_data '{}'
        The status should equal 0
      End
    End
  End

  # ============================================================================
  # Given: load_json_file() function (T-REF-2)
  # ============================================================================

  Describe 'Given: load_json_file() function'
    Describe 'When: file does not exist'
      It 'Then: [異常] - returns exit code 2'
        When call load_json_file "/nonexistent/file.json"
        The status should equal 2
        The stderr should include "Error: File not found"
      End
    End

    Describe 'When: file exists and is readable'
      setup_load_test_file() {
        TEMP_LOAD="${SHELLSPEC_TMPBASE}/load-test.json"
        echo '{"test": "data"}' > "$TEMP_LOAD"
      }
      BeforeEach 'setup_load_test_file'

      It 'Then: [正常] - returns exit code 0 and outputs file contents'
        When call load_json_file "$TEMP_LOAD"
        The status should equal 0
        The output should equal '{"test": "data"}'
      End
    End
  End

  # ============================================================================
  # Given: validate_json_file() function (T4-1)
  # ============================================================================

  Describe 'Given: validate_json_file() function'
    Describe 'When: file does not exist'
      It 'Then: [異常] - returns exit code 2 with filename in error'
        When call validate_json_file "/nonexistent/test.json"
        The status should equal 2
        The stderr should include "Error: File not found"
        The stderr should include "/nonexistent/test.json"
      End
    End

    Describe 'When: file contains invalid JSON syntax'
      setup_invalid_json() {
        TEMP_INVALID="${SHELLSPEC_TMPBASE}/invalid.json"
        echo '{invalid}' > "$TEMP_INVALID"
      }
      BeforeEach 'setup_invalid_json'

      It 'Then: [異常] - returns exit code 3'
        When call validate_json_file "$TEMP_INVALID"
        The status should equal 3
        The stderr should include "Error: Invalid JSON"
      End
    End

    Describe 'When: file root is not object'
      setup_array_json() {
        TEMP_ARRAY="${SHELLSPEC_TMPBASE}/array.json"
        echo '["item1", "item2"]' > "$TEMP_ARRAY"
      }
      BeforeEach 'setup_array_json'

      It 'Then: [異常] - returns exit code 4 for array'
        When call validate_json_file "$TEMP_ARRAY"
        The status should equal 4
        The stderr should include "Error: JSON root must be an object"
      End
    End

    Describe 'When: file root is string'
      setup_string_json() {
        TEMP_STRING="${SHELLSPEC_TMPBASE}/string.json"
        echo '"text"' > "$TEMP_STRING"
      }
      BeforeEach 'setup_string_json'

      It 'Then: [異常] - returns exit code 4'
        When call validate_json_file "$TEMP_STRING"
        The status should equal 4
        The stderr should include "Error: JSON root must be an object"
      End
    End

    Describe 'When: file root is number'
      setup_number_json() {
        TEMP_NUMBER="${SHELLSPEC_TMPBASE}/number.json"
        echo '123' > "$TEMP_NUMBER"
      }
      BeforeEach 'setup_number_json'

      It 'Then: [異常] - returns exit code 4'
        When call validate_json_file "$TEMP_NUMBER"
        The status should equal 4
        The stderr should include "Error: JSON root must be an object"
      End
    End

    Describe 'When: file is valid JSON object'
      setup_valid_json() {
        TEMP_VALID="${SHELLSPEC_TMPBASE}/valid.json"
        echo '{"key": "value"}' > "$TEMP_VALID"
      }
      BeforeEach 'setup_valid_json'

      It 'Then: [正常] - returns exit code 0'
        When call validate_json_file "$TEMP_VALID"
        The status should equal 0
      End
    End

    Describe 'When: file is empty object'
      setup_empty_json() {
        TEMP_EMPTY="${SHELLSPEC_TMPBASE}/empty.json"
        echo '{}' > "$TEMP_EMPTY"
      }
      BeforeEach 'setup_empty_json'

      It 'Then: [エッジケース] - returns exit code 0'
        When call validate_json_file "$TEMP_EMPTY"
        The status should equal 0
      End
    End
  End
End
