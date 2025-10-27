#!/usr/bin/env bash
# src: ./scripts/__tests__/run-e2e-tests.sh
# @(#): Wrapper for running E2E tests with ShellSpec
#
# @file run-e2e-tests.sh
# @brief Executes end-to-end specs for /idd:issue:push with required
#   environment variables configured.
#
# @description
#   This script ensures PROJECT_ROOT and SHELLSPEC_PROJECT_ROOT are set prior to
#   invoking ShellSpec. By default it targets the `.claude/commands/__tests__/e2e`
#   directory, while still allowing additional ShellSpec options to be passed
#   through.
#
# @example
#   scripts/__tests__/run-e2e-tests.sh                   # run all E2E specs
#   scripts/__tests__/run-e2e-tests.sh --fail-fast       # pass extra options
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

DEFAULT_PATH=".claude/commands/__tests__/e2e"

shellspec --default-path "$DEFAULT_PATH" "$@"
