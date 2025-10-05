#!/usr/bin/env bash
# src: ./scripts/libs/logger.lib.sh
# @(#): Logging utility library for bash scripts
#
# @file logger.lib.sh
# @brief Logging utility library for bash scripts
# @description
#   Provides structured logging capabilities with multiple log levels (INFO, VERBOSE, ERROR, DRY-RUN).
#   Supports error tracking, quiet mode, and verbose output control through flags.
#
#   Features:
#   - Multiple log levels with configurable output
#   - Error counting and retrieval system
#   - Quiet mode (FLAG_QUIET) to suppress info messages
#   - Verbose mode (FLAG_VERBOSE) for detailed output
#   - DRY-RUN mode for showing operations without execution
#
# @example
#   . ./scripts/libs/logger.lib.sh
#   logger_init
#   log_info "Starting operation"
#   log_verbose "Detailed step information"
#   log_error "Operation failed"
#   error_count=$(logger_get_error_count)
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# ============================================================================
# Public API - Configuration
# ============================================================================

##
# @description Control verbose output (0=disabled, 1=enabled)
# @set FLAG_VERBOSE=1 to enable verbose logging
# @default 0
FLAG_VERBOSE=${FLAG_VERBOSE:-0}

##
# @description Suppress informational messages (0=normal, 1=quiet)
# @set FLAG_QUIET=1 to suppress info messages
# @default 0
FLAG_QUIET=${FLAG_QUIET:-0}

# ============================================================================
# Private Implementation - State Management
# ============================================================================

##
# @description Array storing all error messages
# @internal
declare -a _ERROR_LOG

##
# @description Counter tracking total number of errors
# @internal
_ERROR_COUNT=0

# ============================================================================
# Public API - Initialization
# ============================================================================

##
# @description Initialize logging system and reset error tracking state
# @example
#   logger_init
#   log_info "Logger initialized"
# @exitcode 0 Always succeeds
logger_init() {
  _ERROR_LOG=()
  _ERROR_COUNT=0
}

##
# @description Get current error count from error tracking system
# @example
#   count=$(logger_get_error_count)
#   echo "Total errors: $count"
# @stdout Number of errors logged since last logger_init
# @exitcode 0 Always succeeds
logger_get_error_count() {
  echo "$_ERROR_COUNT"
}

##
# @description Get all error messages from error tracking system
# @example
#   while IFS= read -r error; do
#     echo "Error: $error"
#   done < <(logger_get_errors)
# @stdout Array of error messages, one per line
# @exitcode 0 Always succeeds
logger_get_errors() {
  printf '%s\n' "${_ERROR_LOG[@]}"
}

# ============================================================================
# Public API - Logging Functions
# ============================================================================

##
# @description Print informational message to stdout
# @arg $1 string The message to log
# @example
#   log_info "Operation completed successfully"
#   log_info "Processing file: $filename"
# @stdout Message with [INFO] prefix (unless FLAG_QUIET=1)
# @exitcode 0 Always succeeds
# @see FLAG_QUIET
log_info() {
  local message="$1"

  if [[ $FLAG_QUIET -eq 0 ]]; then
    _log_with_prefix "INFO" "$message"
  fi
}

##
# @description Print verbose message when FLAG_VERBOSE is enabled
# @arg $1 string The message to log
# @example
#   FLAG_VERBOSE=1
#   log_verbose "Detailed operation info"
#   log_verbose "Processing step 3 of 10"
# @stdout Message with [VERBOSE] prefix (only when FLAG_VERBOSE=1)
# @exitcode 0 Always succeeds
# @see FLAG_VERBOSE
log_verbose() {
  local message="$1"

  if [[ $FLAG_VERBOSE -eq 1 ]]; then
    _log_with_prefix "VERBOSE" "$message"
  fi
}

##
# @description Print error message to stderr and track it
# @arg $1 string The error message to log
# @example
#   log_error "File not found: config.yaml"
#   log_error "Invalid argument: $arg"
# @stderr Message with [ERROR] prefix
# @exitcode 0 Always succeeds (does not terminate script)
# @see logger_get_error_count
# @see logger_get_errors
log_error() {
  local message="$1"

  _log_with_prefix "ERROR" "$message" >&2
  _track_error "$message"
}

##
# @description Print dry-run operation to stdout
# @arg $1 string The operation that would be performed
# @example
#   log_dry_run "cp source.txt dest.txt"
#   log_dry_run "rm -rf /tmp/cache"
# @stdout Message with [DRY-RUN] prefix (always outputs)
# @exitcode 0 Always succeeds
log_dry_run() {
  local operation="$1"

  _log_with_prefix "DRY-RUN" "$operation"
}

# ============================================================================
# Private Implementation - Helper Functions
# ============================================================================

##
# @description Format and print message with level prefix
# @internal
# @arg $1 string Log level (INFO, ERROR, VERBOSE, DRY-RUN)
# @arg $2 string The message to format
# @stdout Formatted message: [LEVEL] message
_log_with_prefix() {
  local level="$1"
  local timestamp
  local message="$2"

  timestamp="$(date +%y-%m-%d\ %H:%M:%S)"
  echo "[${timestamp}] [${level}] ${message}"
}

##
# @description Record error in tracking system
# @internal
# @arg $1 string The error message to track
_track_error() {
  local message="$1"

  _ERROR_LOG+=("${message}")
  _ERROR_COUNT=$((_ERROR_COUNT + 1))
}
