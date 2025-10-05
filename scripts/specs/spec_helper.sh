#!/usr/bin/env bash
# src: ./spec_helper.sh
# @(#) : ShellSpec spec helper - common test utilities
#
# Copyright (c) 2025 atsushifx
# Released under the MIT License.
# https://opensource.org/licenses/MIT

# ShellSpec configuration
# shellcheck shell=bash

# Set project root for all tests
SHELLSPEC_PROJECT_ROOT="${SHELLSPEC_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export SHELLSPEC_PROJECT_ROOT

# Common test utilities can be added here
# Example: setup_temp_dir() { ... }
# Example: cleanup_temp_dir() { ... }
