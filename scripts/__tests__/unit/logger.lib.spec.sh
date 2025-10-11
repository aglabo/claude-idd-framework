#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/logger.lib.spec.sh
# @(#): ShellSpec tests for logger.lib.sh
#
# @file logger.lib.spec.sh
# @brief ShellSpec tests for logger.lib.sh
# @description
#   Comprehensive test suite for the logger.lib.sh library.
#   Tests logging functions, error tracking, and flag behavior.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'logger.lib.sh'
  # Source the library
  Include scripts/libs/logger.lib.sh

  # ============================================================================
  # Error API Tests
  # ============================================================================

  Describe 'logger_init()'
    Context 'Given: default state'
      It 'Then: [正常] - resets error count to 0'
        logger_init
        When call logger_get_error_count
        The output should equal "0"
      End

      It 'Then: [正常] - clears error log array'
        logger_init
        When call logger_get_errors
        The output should equal ""
      End
    End

    Context 'Given: errors exist before init'
      test_reset_error_count() {
        logger_init
        log_error "First error"
        log_error "Second error"
        logger_init
        logger_get_error_count
      }

      test_reset_error_log() {
        logger_init
        log_error "First error"
        log_error "Second error"
        logger_init
        logger_get_errors
      }

      It 'Then: [正常] - resets existing error count'
        When run test_reset_error_count
        The output should equal "0"
        The stderr should include "[ERROR] First error"
        The stderr should include "[ERROR] Second error"
      End

      It 'Then: [正常] - clears existing error log'
        When run test_reset_error_log
        The output should equal ""
        The stderr should include "[ERROR] First error"
        The stderr should include "[ERROR] Second error"
      End
    End
  End

  Describe 'logger_get_error_count()'
    setup() {
      logger_init
    }

    BeforeEach 'setup'

    Context 'Given: no errors logged'
      It 'Then: [正常] - returns 0'
        When call logger_get_error_count
        The output should equal "0"
      End
    End

    Context 'Given: single error logged'
      test_single_error_count() {
        log_error "Test error"
        logger_get_error_count
      }

      It 'Then: [正常] - returns 1'
        When run test_single_error_count
        The output should equal "1"
        The stderr should include "[ERROR] Test error"
      End
    End

    Context 'Given: multiple errors logged'
      test_multiple_errors_count() {
        log_error "Error 1"
        log_error "Error 2"
        log_error "Error 3"
        logger_get_error_count
      }

      It 'Then: [正常] - returns correct count'
        When run test_multiple_errors_count
        The output should equal "3"
        The stderr should include "[ERROR] Error 1"
        The stderr should include "[ERROR] Error 2"
        The stderr should include "[ERROR] Error 3"
      End
    End
  End

  Describe 'logger_get_errors()'
    setup() {
      logger_init
    }

    BeforeEach 'setup'

    Context 'Given: no errors logged'
      It 'Then: [正常] - returns empty output'
        When call logger_get_errors
        The output should equal ""
      End
    End

    Context 'Given: single error logged'
      test_single_error_message() {
        log_error "Test error message"
        logger_get_errors
      }

      It 'Then: [正常] - returns the error message'
        When run test_single_error_message
        The output should equal "Test error message"
        The stderr should include "[ERROR] Test error message"
      End
    End

    Context 'Given: multiple errors logged'
      test_multiple_error_messages() {
        log_error "First error"
        log_error "Second error"
        log_error "Third error"
        logger_get_errors
      }

      It 'Then: [正常] - returns all error messages (one per line)'
        When run test_multiple_error_messages
        The line 1 should equal "First error"
        The line 2 should equal "Second error"
        The line 3 should equal "Third error"
        The stderr should include "[ERROR] First error"
        The stderr should include "[ERROR] Second error"
        The stderr should include "[ERROR] Third error"
      End
    End

    Context 'Given: edge cases'
      test_error_special_chars() {
        log_error "Error with \$VAR and 'quotes'"
        logger_get_errors
      }

      test_empty_error() {
        log_error ""
        logger_get_errors
      }

      It 'Then: [エッジケース] - handles errors with special characters'
        When run test_error_special_chars
        The output should include "\$VAR"
        The output should include "'quotes'"
        The stderr should include "[ERROR]"
      End

      It 'Then: [エッジケース] - handles empty error message'
        When run test_empty_error
        The output should equal ""
        The stderr should include "[ERROR]"
      End
    End
  End

  # ============================================================================
  # Logger API Tests
  # ============================================================================

  Describe 'log_info()'
    setup() {
      logger_init
      FLAG_QUIET=0
    }

    BeforeEach 'setup'

    Context 'Given: FLAG_QUIET=0 (default)'
      It 'Then: [正常] - outputs message with [INFO] prefix to stdout'
        When call log_info "Test message"
        The output should include "[INFO] Test message"
        The stderr should equal ""
      End
    End

    Context 'Given: FLAG_QUIET=1'
      It 'Then: [正常] - suppresses output'
        FLAG_QUIET=1
        When call log_info "Test message"
        The output should equal ""
      End
    End
  End

  Describe 'log_verbose()'
    setup() {
      logger_init
      FLAG_VERBOSE=0
    }

    BeforeEach 'setup'

    Context 'Given: FLAG_VERBOSE=0 (default)'
      It 'Then: [正常] - suppresses output'
        When call log_verbose "Test message"
        The output should equal ""
      End
    End

    Context 'Given: FLAG_VERBOSE=1'
      It 'Then: [正常] - outputs message with [VERBOSE] prefix to stdout'
        FLAG_VERBOSE=1
        When call log_verbose "Test message"
        The output should include "[VERBOSE] Test message"
        The stderr should equal ""
      End
    End
  End

  Describe 'log_error()'
    setup() {
      logger_init
      FLAG_QUIET=0
    }

    BeforeEach 'setup'

    Context 'Given: single error'
      test_error_tracking() {
        log_error "Test error"
        echo "count:$(logger_get_error_count)"
        logger_get_errors
      }

      It 'Then: [正常] - outputs to stderr, increments count, and stores in log'
        When run test_error_tracking
        The stderr should include "[ERROR] Test error"
        The output should include "count:1"
        The output should include "Test error"
      End
    End

    Context 'Given: multiple errors'
      test_multiple_errors_tracking() {
        log_error "Error 1"
        log_error "Error 2"
        log_error "Error 3"
        echo "count:$(logger_get_error_count)"
        echo "errors:"
        logger_get_errors
      }

      It 'Then: [正常] - tracks all errors correctly'
        When run test_multiple_errors_tracking
        The line 1 should equal "count:3"
        The line 2 should equal "errors:"
        The line 3 should equal "Error 1"
        The line 4 should equal "Error 2"
        The line 5 should equal "Error 3"
        The stderr should include "[ERROR] Error 1"
        The stderr should include "[ERROR] Error 2"
        The stderr should include "[ERROR] Error 3"
      End
    End
  End

  Describe 'log_dry_run()'
    setup() {
      logger_init
      FLAG_QUIET=0
      FLAG_VERBOSE=0
    }

    BeforeEach 'setup'

    Context 'Given: normal operation'
      It 'Then: [正常] - outputs with [DRY-RUN] prefix to stdout regardless of flags'
        FLAG_QUIET=1
        When call log_dry_run "cp source dest"
        The output should include "[DRY-RUN] cp source dest"
        The stderr should equal ""
      End
    End
  End
End
