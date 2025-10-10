#!/usr/bin/env bash
# shellcheck shell=bash
# src: ./scripts/__tests__/unit/prepare-commit-msg-parse.unit.spec.sh
# @(#): Unit tests for parse_options() in prepare-commit-msg.sh
#
# @file prepare-commit-msg-parse.unit.spec.sh
# @brief Unit tests for command-line argument parsing
# @description
#   Tests the parse_options() function in isolation.
#   Validates flag settings and argument handling logic.
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

Describe 'prepare-commit-msg.sh - parse_options()'
  # Source the actual script to get function definitions
  Include scripts/prepare-commit-msg.sh

  Describe 'parse_options()'
    setup() {
      FLAG_OUTPUT_TO_STDOUT=true
      GIT_COMMIT_MSG=".git/COMMIT_EDITMSG"
    }

    BeforeEach 'setup'

    Context 'Given: default state'
      It 'Then: [正常] - FLAG_OUTPUT_TO_STDOUT is true by default'
        When call parse_options
        The variable FLAG_OUTPUT_TO_STDOUT should equal "true"
      End

      It 'Then: [正常] - GIT_COMMIT_MSG has default value'
        When call parse_options
        The variable GIT_COMMIT_MSG should equal ".git/COMMIT_EDITMSG"
      End
    End

    Context 'Given: --git-buffer option'
      It 'Then: [正常] - sets FLAG_OUTPUT_TO_STDOUT to false'
        When call parse_options --git-buffer
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
      End

      It 'Then: [正常] - keeps default GIT_COMMIT_MSG'
        When call parse_options --git-buffer
        The variable GIT_COMMIT_MSG should equal ".git/COMMIT_EDITMSG"
      End
    End

    Context 'Given: --to-buffer option'
      It 'Then: [正常] - sets FLAG_OUTPUT_TO_STDOUT to false'
        When call parse_options --to-buffer
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
      End
    End

    Context 'Given: custom commit message file'
      It 'Then: [正常] - sets GIT_COMMIT_MSG to custom path'
        When call parse_options "custom/path/COMMIT_MSG"
        The variable GIT_COMMIT_MSG should equal "custom/path/COMMIT_MSG"
      End

      It 'Then: [正常] - keeps FLAG_OUTPUT_TO_STDOUT as true'
        When call parse_options "custom/path/COMMIT_MSG"
        The variable FLAG_OUTPUT_TO_STDOUT should equal "true"
      End
    End

    Context 'Given: combination of options and file path'
      It 'Then: [正常] - handles --git-buffer with custom file'
        When call parse_options --git-buffer "temp/test_commit"
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
        The variable GIT_COMMIT_MSG should equal "temp/test_commit"
      End

      It 'Then: [正常] - handles --to-buffer with custom file'
        When call parse_options --to-buffer "temp/test_commit"
        The variable FLAG_OUTPUT_TO_STDOUT should equal "false"
        The variable GIT_COMMIT_MSG should equal "temp/test_commit"
      End
    End

    Context 'Given: unknown option'
      It 'Then: [異常] - exits with error for unknown option'
        When run parse_options --unknown-option
        The status should equal 1
        The stderr should include "Unknown option: --unknown-option"
      End

      It 'Then: [異常] - exits with error for invalid flag'
        When run parse_options -x
        The status should equal 1
        The stderr should include "Unknown option: -x"
      End
    End

    Context 'Given: help option'
      It 'Then: [正常] - displays usage with --help'
        When run parse_options --help
        The status should equal 0
        The output should include "Usage:"
        The output should include "--git-buffer"
      End

      It 'Then: [正常] - displays usage with -h'
        When run parse_options -h
        The status should equal 0
        The output should include "Usage:"
      End
    End
  End
End
