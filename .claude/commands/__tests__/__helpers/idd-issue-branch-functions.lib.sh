#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./.claude/commands/__tests__/__helpers/idd-issue-branch-functions.lib.sh
# @(#): Implementation functions for /idd:issue:branch command testing
#
# @file idd-issue-branch-functions.lib.sh
# @brief Provides implementation functions extracted from branch.md for testing
# @description
#   This library contains the actual implementation functions from branch.md
#   that are used in unit and integration tests.
#
#   Included functions:
#   - detect_domain (T3)
#   - route_subcommand (T2, simplified for testing)
#
# @example Basic usage
#   . .claude/commands/__tests__/__helpers/idd-issue-branch-functions.lib.sh
#   setup_branch_functions
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# =============================================================================
# Setup Function
# =============================================================================

##
# @description Setup all branch command implementation functions
# @noargs
# @exitcode 0 Always successful
setup_branch_functions() {
  # Functions are defined in this file and become available when sourced
  # This function exists for consistency with other libraries
  return 0
}

# =============================================================================
# T3: Domain Detection Functions
# =============================================================================

##
# @brief Detect domain from issue title or defaults
# @description Determines the domain (namespace) for branch naming:
#   1. If DOMAIN variable is set (--domain option), use it (highest priority)
#   2. If title contains [domain] pattern, extract it
#   3. Otherwise, map issue_type to default domain
# @param $1 Title string (may contain [domain] prefix)
# @param $2 Issue type (feature, bug, enhancement, task)
# @return 0 on success
# @stdout Domain string
# @example
#   domain=$(detect_domain "[scripts] Add xcp utility" "feature")
#   # Returns: "scripts"
#   domain=$(detect_domain "Fix validation bug" "bug")
#   # Returns: "bugfix"
##
detect_domain() {
  local title="$1"
  local issue_type="${2:-feature}"

  # Priority 1: --domain option override (DOMAIN variable)
  if [ -n "${DOMAIN:-}" ]; then
    echo "$DOMAIN"
    return 0
  fi

  # Priority 2: Extract from [domain] pattern in title
  if [[ "$title" =~ ^\[([a-zA-Z0-9_-]+)\] ]]; then
    local extracted="${BASH_REMATCH[1]}"
    echo "$extracted"
    return 0
  fi

  # Priority 3: Map issue_type to default domain
  case "$issue_type" in
    bug)
      echo "bugfix"
      ;;
    feature)
      echo "feature"
      ;;
    enhancement)
      echo "enhancement"
      ;;
    task)
      echo "task"
      ;;
    *)
      # Fallback to issue_type as-is
      echo "$issue_type"
      ;;
  esac

  return 0
}

# =============================================================================
# T2: Subcommand Routing Functions (Simplified for Testing)
# =============================================================================

##
# @brief Route subcommand for testing purposes
# @description Simplified routing logic for integration tests
# @param $1 Subcommand (new, commit, or empty for default)
# @return 0 for valid subcommand (new, commit), 1 for invalid
# @stdout Routed subcommand name
# @example
#   result=$(route_subcommand "new")
#   # Returns: "new"
#   result=$(route_subcommand "")
#   # Returns: "new" (default)
##
route_subcommand() {
  local subcommand="${1:-new}"

  case "$subcommand" in
    new)
      echo "new"
      return 0
      ;;
    commit)
      echo "commit"
      return 0
      ;;
    *)
      echo "Unknown subcommand: $subcommand" >&2
      return 1
      ;;
  esac
}
