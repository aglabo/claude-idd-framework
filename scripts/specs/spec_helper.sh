#!/usr/bin/env bash
# src: ./scripts/specs/spec_helper.sh
# @(#): ShellSpec spec helper - common test utilities
#
# @file spec_helper.sh
# @brief ShellSpec spec helper - common test utilities
# @description
#   Provides common configuration and utility functions for ShellSpec test suites.
#
#   Features:
#   - Sets SHELLSPEC_PROJECT_ROOT for all tests
#   - Provides extensible utilities for test setup/teardown
#   - Configures ShellSpec shell mode
#
# @example
#   # Include in your spec file
#   Include scripts/specs/spec_helper.sh
#
#   # Use project root in tests
#   echo "Project root: $SHELLSPEC_PROJECT_ROOT"
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# ShellSpec configuration
# shellcheck shell=bash

# Set project root for all tests
SHELLSPEC_PROJECT_ROOT="${SHELLSPEC_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export SHELLSPEC_PROJECT_ROOT

# Set PROJECT_ROOT and change to repository root
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
export PROJECT_ROOT
cd "$PROJECT_ROOT" || exit 1

if [ -d /w/temp ]; then
  export TMPDIR=/w/temp
  export SHELLSPEC_TMPBASE=/w/temp
fi

# Common test utilities can be added here
# Example: setup_temp_dir() { ... }
# Example: cleanup_temp_dir() { ... }
