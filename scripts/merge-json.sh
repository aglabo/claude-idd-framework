#!/usr/bin/env bash
# src: ./scripts/merge-json.sh
# @(#): Merge two JSON configuration files with shallow merge strategy
#
# @file merge-json.sh
# @brief Merge two JSON configuration files with shallow merge strategy
# @description
#   Merges two JSON configuration files using shallow merge with array concatenation.
#   Key features:
#   - Shallow merge (top-level keys only)
#   - Last-wins for key conflicts
#   - Array concatenation (file1 + file2)
#   - Nested objects replaced entirely (no deep merge)
#
# @example
#   # Merge to stdout
#   bash scripts/merge-json.sh base.json override.json
#
#   # Merge to file
#   bash scripts/merge-json.sh base.json override.json -o merged.json
#
# @exitcode 0 If merge succeeds
# @exitcode 1 If arguments invalid
# @exitcode 2 If file not found
# @exitcode 3 If JSON parse error
# @exitcode 4 If JSON root not object
# @exitcode 5 If write error
#
# @help<<
# Usage: <SCRIPT_NAME> FILE1 FILE2 [-o OUTPUT_FILE] [-h] [-v]
#
# Merge two JSON configuration files with shallow merge strategy.
#
# Arguments:
#   FILE1             Base JSON configuration file
#   FILE2             Override JSON configuration file
#
# Options:
#   -o, --output FILE Write merged JSON to FILE (default: stdout)
#   -h, --help        Display this help message
#   -v, --version     Display version information
#
# Exit Codes:
#   0  Success - JSON files merged successfully
#   1  Invalid arguments
#   2  File not found or not readable
#   3  Invalid JSON or merge failure
#   4  JSON root is not an object
#   5  Cannot write to output file
#
# Examples:
#   # Merge to stdout
#   <SCRIPT_NAME> base.json override.json
#
#   # Merge to file
#   <SCRIPT_NAME> base.json override.json -o merged.json
#
#   # Display help
#   <SCRIPT_NAME> --help
#
#<<
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

set -euo pipefail

# ============================================================================
# Dependencies
# ============================================================================

##
# @description Script directory path (absolute)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source io-utils library for error_print
# shellcheck source=libs/io-utils.lib.sh
. "${SCRIPT_DIR}/libs/io-utils.lib.sh"

# ============================================================================
# Configuration & Constants
# ============================================================================

##
# @description Script version (extracted from file header)
VERSION=$(sed -n '1,/^$/p' "${BASH_SOURCE[0]}" | sed -n 's/^# @version //p')
readonly VERSION

##
# @description Script name (from BASH_SOURCE or $0)
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# ============================================================================
# Command-Line Arguments (set by parse_args)
# ============================================================================

##
# @description Base configuration file path
FILE1=""

##
# @description Override configuration file path
FILE2=""

##
# @description Output file path (empty = stdout)
OUTPUT_FILE=""

# ============================================================================
# Initialize & Configuration
# ============================================================================

##
# initialize global variables
#
init_variables() {
  FILE1=""
  FILE2=""

  OUTPUT_FILE=""
}


# ============================================================================
# Dependency Checking
# ============================================================================

##
# @description Check if required dependencies (jq) are available
# @exitcode 0 If all dependencies are available
# @exitcode 1 If any dependency is missing
check_dependencies() {
  if command -v jq &> /dev/null; then
    return 0
  else
    error_print <<EOF
Error: jq is not installed. Please install jq:
  - Windows: scoop install jq
  - macOS: brew install jq
  - Linux: apt install jq (Debian/Ubuntu) or yum install jq (RHEL/CentOS)
EOF
    return 1
  fi
}

#
# ============================================================================
# Argument Parsing
# ============================================================================

##
# @description Parse command-line arguments
# @arg $@ string Command-line arguments
# @exitcode 0 If arguments are valid
# @exitcode 1 If invalid arguments
# @exitcode 2 If help/version requested
parse_args() {
  # Reset parsed arguments for each invocation
  init_variables

  # Parse options and collect positional arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output)
        if [[ $# -gt 1 ]]; then
          OUTPUT_FILE="$2"
          shift 2
        else
          # Validation of missing argument handled in T3-5; avoid unbound variable
          OUTPUT_FILE=""
          shift
        fi
        ;;
      -h|--help)
        show_help
        return 2
        ;;
      -v|--version)
        show_version
        return 2
        ;;
      -*)
        # Unknown option - will be handled by validation in T3-5
        shift
        ;;
      *)
        # Positional argument
        if [[ -z "$FILE1" ]]; then
          FILE1="$1"
        elif [[ -z "$FILE2" ]]; then
          FILE2="$1"
        fi
        shift
        ;;
    esac
  done

  return 0
}

# ============================================================================
# JSON File I/O
# ============================================================================

##
# @description Load JSON file contents
# @arg $1 string File path to load
# @stdout File contents
# @exitcode 0 If file loaded successfully
# @exitcode 2 If file not found or not readable
# @stderr Error messages for file access failures
load_json_file() {
  local file="$1"

  # Check file existence and readability
  if [[ ! -e "$file" ]] || [[ ! -r "$file" ]]; then
    error_print "Error: File not found: $file"
    return 2
  fi

  # Output file contents
  cat "$file"
  return 0
}

# ============================================================================
# JSON Data Validation
# ============================================================================

##
# @description Validate JSON string has valid syntax and object root
# @arg $1 string JSON string to validate
# @exitcode 0 If JSON is valid object
# @exitcode 3 If JSON parse error
# @exitcode 4 If JSON root is not object
# @stderr Error messages for validation failures
validate_json_data() {
  local json_string="$1"

  # Check JSON validity
  local jq_error
  if ! jq_error=$(echo "$json_string" | jq empty 2>&1); then
    error_print "Error: Invalid JSON: $jq_error"
    return 3
  fi

  # Check root is object
  if ! echo "$json_string" | jq -e 'type == "object"' &>/dev/null; then
    error_print "Error: JSON root must be an object"
    return 4
  fi

  return 0
}

# ============================================================================
# JSON File Validation
# ============================================================================

##
# @description Validate JSON file exists, is readable, and has object root
# @arg $1 string File path to validate
# @exitcode 0 If file is valid JSON object
# @exitcode 2 If file not found or not readable
# @exitcode 3 If JSON parse error
# @exitcode 4 If JSON root is not object
validate_json_file() {
  local file="$1"

  # Load file contents
  local json_content
  json_content=$(load_json_file "$file") || return $?

  # Validate JSON content
  validate_json_data "$json_content"
}

# ============================================================================
# Help & Version Display
# ============================================================================

##
# @description Display help message with usage, options, and examples
show_help() {
  echo ""
  sed -n '/^# @help<</,/^#<</p' "${BASH_SOURCE[0]}" \
    | sed '1d;$d' \
    | sed 's/^# //' \
    | sed 's/^#$//' \
    | sed "s/<SCRIPT_NAME>/$SCRIPT_NAME/g"
  echo ""
  return 0
}

##
# @description Display version information
show_version() {
    local copyright_lines
  copyright_lines=$(sed -n '1,/^$/p' "${BASH_SOURCE[0]}" \
    | sed -n '/^# @license/,/^$/p' \
    | sed '1d;$d' \
    | sed 's/^# //' \
    | sed 's/^#$//' \
    | sed '/^$/d')

  cat << EOF

$SCRIPT_NAME version $VERSION

$copyright_lines

EOF
}
