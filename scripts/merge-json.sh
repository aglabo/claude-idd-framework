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
