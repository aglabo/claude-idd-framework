#!/usr/bin/env bash
# src: ./scripts/__tests__/run-integration-tests.sh
# @(#): Wrapper for running integration tests with ShellSpec
#
# @file run-integration-tests.sh
# @brief Provides a convenience wrapper to execute integration specs with the
#   required environment variables pre-configured.
#
# @description
#   This script initializes environment variables expected by the integration
#   specs (e.g., PROJECT_ROOT, SHELLSPEC_PROJECT_ROOT) and then invokes
#   ShellSpec with the integration test directory as the default path.
#
# @example
#   scripts/__tests__/run-integration-tests.sh               # run all specs
#   scripts/__tests__/run-integration-tests.sh --fail-fast   # pass options
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export PROJECT_ROOT
export SHELLSPEC_PROJECT_ROOT="${SHELLSPEC_PROJECT_ROOT:-$PROJECT_ROOT}"

cd "$PROJECT_ROOT"

DEFAULT_PATH=".claude/commands/__tests__/integration"

shellspec --default-path "$DEFAULT_PATH" "$@"
