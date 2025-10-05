#!/usr/bin/env bash
# src: ./scripts/xcp.sh
# @(#): eXtended CoPy utility
#
# @file xcp.sh
# @brief eXtended CoPy utility with advanced file handling capabilities
# @description
#   Advanced copy utility that extends standard cp with additional features:
#   - Multiple operation modes (skip, overwrite, update, backup)
#   - Dry-run mode for safe testing
#   - Recursive copying with pattern matching
#   - Automatic directory creation (-p flag)
#   - Symlink handling options
#   - Error tracking and fail-fast mode
#
# @example
#   # Copy with parent directory creation
#   xcp.sh -p source.txt /path/to/dest/
#
#   # Dry-run mode
#   xcp.sh --dry-run -R source/ dest/
#
#   # Verbose output
#   xcp.sh -v source.txt dest.txt
#
# @author atsushifx
# @version 1.0.0
# @license MIT
#
# Copyright (c) 2025 atsushifx <https://github.com/atsushifx>
# Released under the MIT License.
# https://opensource.org/licenses/MIT
#

# Enable strict mode for safer scripting
set -euo pipefail

# ============================================================================
# Dependencies
# ============================================================================

##
# @description Script directory path (absolute)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source logger library
. "${SCRIPT_DIR}/libs/logger.lib.sh"

# Initialize logger
logger_init

# ============================================================================
# Configuration & Global Variables
# ============================================================================

##
# @description Skip existing files (operation mode)
# @default 0
readonly MODE_SKIP=0

##
# @description Overwrite existing files (operation mode)
# shellcheck disable=SC2034
readonly MODE_OVERWRITE=1

##
# @description Update only if source is newer (operation mode)
# shellcheck disable=SC2034
readonly MODE_UPDATE=2

##
# @description Create backup of existing files (operation mode)
# shellcheck disable=SC2034
readonly MODE_BACKUP=3

##
# @description Current operation mode (default: skip existing files)
# @default MODE_SKIP
# shellcheck disable=SC2034
OPERATION_MODE=$MODE_SKIP

##
# @description Enable dry-run mode (0=disabled, 1=enabled)
# @default 0
# shellcheck disable=SC2034
FLAG_DRY_RUN=0

##
# @description Enable recursive copying (0=disabled, 1=enabled)
# @default 0
# shellcheck disable=SC2034
FLAG_RECURSIVE=0

##
# @description Create parent directories as needed (0=disabled, 1=enabled)
# @default 0
FLAG_PARENTS=0

##
# @description Dereference symbolic links (0=disabled, 1=enabled)
# @default 0
# shellcheck disable=SC2034
FLAG_DEREFERENCE=0

##
# @description Stop on first error (0=continue, 1=stop)
# @default 0
# shellcheck disable=SC2034
FLAG_FAIL_FAST=0

##
# @description Indicates fail-fast abort requested after error
# @default 0
# shellcheck disable=SC2034
FLAG_ABORT_REQUESTED=0

##
# @description Script version
# shellcheck disable=SC2034
readonly VERSION="1.0.0"

##
# @description Script name (from $0)
# shellcheck disable=SC2034
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME

# ============================================================================
# Utility Functions - Validation
# ============================================================================

##
# @description Check if source file or directory exists and is accessible
# @arg $1 string Path to source file or directory
# @example
#   if validate_source "/path/to/file"; then
#     echo "Source is valid"
#   fi
# @exitcode 0 If source exists and is readable
# @exitcode 1 If source not found or not readable
# @see log_error
validate_source() {
  local source="$1"

  if [[ ! -e "$source" ]]; then
    log_error "Source not found: $source"
    return 1
  fi

  if [[ ! -r "$source" ]]; then
    log_error "Source not readable: $source"
    return 1
  fi

  return 0
}

##
# @description Validate destination directory for copy operation
# @arg $1 string Path to destination directory
# @example
#   FLAG_PARENTS=1
#   if validate_dest_dir "/path/to/dest"; then
#     echo "Destination is ready"
#   fi
# @exitcode 0 If directory exists+writable OR created with FLAG_PARENTS=1
# @exitcode 1 If path empty, not writable, or creation failed
# @see FLAG_PARENTS
# @see log_error
# @see log_verbose
validate_dest_dir() {
  local dest_dir="$1"

  # Check for empty path
  if [[ -z "$dest_dir" ]]; then
    log_error "Destination path is empty"
    return 1
  fi

  # Check if directory exists
  if [[ -d "$dest_dir" ]]; then
    # Directory exists - verify it's writable
    if [[ -w "$dest_dir" ]]; then
      return 0
    else
      log_error "Destination directory not writable: $dest_dir"
      return 1
    fi
  fi

  # Directory doesn't exist - check if FLAG_PARENTS allows creation
  if [[ $FLAG_PARENTS -eq 1 ]]; then
    # Attempt to create directory
    if mkdir -p "$dest_dir" 2>/dev/null; then
      log_verbose "Created directory: $dest_dir"
      return 0
    else
      log_error "Failed to create directory: $dest_dir"
      return 1
    fi
  fi

  # Directory doesn't exist and FLAG_PARENTS disabled
  log_error "Destination directory does not exist: $dest_dir (use -p to create)"
  return 1
}

##
# @description Check if path is a directory
# @arg $1 string Path to check
# @example
#   if is_directory "/path/to/dir"; then
#     echo "It's a directory"
#   fi
# @exitcode 0 If path is a directory
# @exitcode 1 If path is not a directory
is_directory() {
  [[ -d "$1" ]]
}

##
# @description Check if path is a regular file
# @arg $1 string Path to check
# @example
#   if is_file "config.yaml"; then
#     echo "It's a regular file"
#   fi
# @exitcode 0 If path is a regular file
# @exitcode 1 If path is not a regular file
is_file() {
  [[ -f "$1" ]]
}

##
# @description Check if path is a symbolic link
# @arg $1 string Path to check
# @example
#   if is_symlink "mylink"; then
#     echo "It's a symlink"
#   fi
# @exitcode 0 If path is a symbolic link
# @exitcode 1 If path is not a symbolic link
is_symlink() {
  [[ -L "$1" ]]
}

# ============================================================================
# Utility Functions - Directory Handling
# ============================================================================

##
# @description Ensure destination directory exists, creating it when permitted
# @arg $1 string Destination directory path
# @example
#   FLAG_PARENTS=1
#   ensure_dest_dir "/path/to/dir"
# @exitcode 0 If directory exists or creation succeeds
# @exitcode 1 If directory cannot be created or path invalid
# @see log_error log_verbose log_info log_dry_run
ensure_dest_dir() {
  local dest_dir="$1"

  if [[ -z "$dest_dir" ]]; then
    log_error "Destination directory path is empty"
    return 1
  fi

  if [[ -d "$dest_dir" ]]; then
    return 0
  fi

  if [[ -e "$dest_dir" && ! -d "$dest_dir" ]]; then
    log_error "Destination path exists but is not a directory: $dest_dir"
    return 1
  fi

  if [[ $FLAG_PARENTS -eq 0 ]]; then
    log_error "Destination directory does not exist: $dest_dir (use -p to create)"
    return 1
  fi

  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    log_dry_run "mkdir -p \"$dest_dir\""
    return 0
  fi

  log_verbose "Creating directory: $dest_dir"
  if mkdir -p "$dest_dir" 2>/dev/null; then
    log_info "Created directory: $dest_dir"
    return 0
  else
    log_error "Failed to create directory: $dest_dir"
    return 1
  fi
}

# ============================================================================
# Utility Functions - Timestamp Operations
# ============================================================================

##
# @description Return current timestamp in YYMMDDHHMMSS format
# @example
#   timestamp=$(get_timestamp)
#   backup_file="config.${timestamp}.bak"
# @stdout Timestamp string in YYMMDDHHMMSS format (e.g., "250108153045")
# @exitcode 0 Always succeeds
# @see date(1)
get_timestamp() {
  date +%y%m%d%H%M%S
}

##
# @description Get modification time of file as Unix timestamp
# @arg $1 string File path
# @example
#   mtime=$(get_mtime "/path/to/file")
#   if [[ -n "$mtime" ]]; then
#     echo "File modified at: $mtime"
#   fi
# @stdout Unix timestamp (seconds since epoch) or empty string on error
# @exitcode 0 Always succeeds (errors return empty string)
# @see stat(1)
get_mtime() {
  local file="$1"

  if command -v stat &>/dev/null; then
    # Try GNU stat first, then BSD stat, suppress all errors
    stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || true
  else
    # Fallback: return empty string when stat unavailable
    echo ""
  fi
}

##
# @description Determine if source file is newer than destination file
# @arg $1 string Source file path
# @arg $2 string Destination file path
# @example
#   if is_newer "$src" "$dest"; then
#     echo "Update required"
#   fi
# @exitcode 0 If source is newer or comparison unavailable
# @exitcode 1 If source is not newer than destination
# @see get_mtime log_verbose
is_newer() {
  local src="$1"
  local dest="$2"

  local src_time dest_time
  src_time="$(get_mtime "$src")"
  dest_time="$(get_mtime "$dest")"

  if [[ -z "$src_time" || -z "$dest_time" ]]; then
    log_verbose "mtime unavailable: src=$src_time dest=$dest_time"
    return 0
  fi

  if [[ $src_time -gt $dest_time ]]; then
    log_verbose "Source newer: $src_time > $dest_time"
    return 0
  fi

  log_verbose "Source not newer: $src_time <= $dest_time"
  return 1
}

##
# @description Create timestamped backup of existing file
# @arg $1 string File path to backup
# @example
#   backup_file "/path/to/file.txt"
# @exitcode 0 If backup created successfully
# @exitcode 1 If backup failed
# @see get_timestamp log_info log_verbose log_error log_dry_run
backup_file() {
  local file="$1"
  local timestamp backup_path

  timestamp="$(get_timestamp)"
  backup_path="${file}.bak.${timestamp}"

  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    log_dry_run "mv \"$file\" \"$backup_path\""
    return 0
  fi

  log_verbose "Backing up: $file -> $backup_path"
  if mv "$file" "$backup_path" 2>/dev/null; then
    log_info "Backed up: $file -> $backup_path"
    return 0
  fi

  log_error "Failed to backup: $file"
  return 1
}

# ============================================================================
# Core Operations - File Copy
# ============================================================================

##
# @description Copy file with operation mode handling
# @arg $1 string Source file path
# @arg $2 string Destination path (file or directory)
# @example
#   OPERATION_MODE=$MODE_SKIP
#   copy_file "/path/to/source.txt" "/path/to/dest.txt"
# @exitcode 0 If copy succeeds or file skipped
# @exitcode 1 If copy fails or validation fails
# @see OPERATION_MODE MODE_SKIP MODE_OVERWRITE MODE_UPDATE MODE_BACKUP
# @see log_info log_verbose log_error log_dry_run
copy_file() {
  local src="$1"
  local dest="$2"
  local dest_file
  local -a cp_flags=("-p")

  # Determine actual destination file path
  if is_directory "$dest"; then
    dest_file="${dest}/$(basename "$src")"
  else
    dest_file="$dest"
  fi

  # Handle existing destination file based on operation mode
  if [[ -e "$dest_file" ]]; then
    case $OPERATION_MODE in
      "$MODE_SKIP")
        log_info "Skipped (exists): $dest_file"
        return 0
        ;;
      "$MODE_OVERWRITE")
        log_verbose "Overwriting: $dest_file"
        # Fall through to copy operation
        ;;
      "$MODE_UPDATE")
        if is_newer "$src" "$dest_file"; then
          log_verbose "Updating: $src -> $dest_file"
          # Fall through to copy operation
        else
          log_info "Skipped (not newer): $dest_file"
          return 0
        fi
        ;;
      "$MODE_BACKUP")
        if ! backup_file "$dest_file"; then
          return 1
        fi
        # Fall through to copy operation
        ;;
      *)
        # Other modes not implemented yet
        return 0
        ;;
    esac
  fi

  if [[ $FLAG_DEREFERENCE -eq 1 ]]; then
    cp_flags+=("-L")
    log_verbose "Dereferencing symlink: $src"
  else
    cp_flags+=("-P")
    log_verbose "Preserving symlink: $src"
  fi

  # Perform actual copy operation
  log_verbose "Copying: $src -> $dest_file"
  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    # shellcheck disable=SC2145
    log_dry_run "cp ${cp_flags[*]} \"$src\" \"$dest_file\""
    return 0
  fi

  if cp "${cp_flags[@]}" "$src" "$dest_file" 2>/dev/null; then
    return 0
  else
    log_error "Failed to copy: $src -> $dest_file"
    if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
      FLAG_ABORT_REQUESTED=1
      log_verbose "Fail-fast requested after copy failure"
    fi
    return 1
  fi
}

# ============================================================================
# Core Operations - Directory Copy
# ============================================================================

##
# @description Recursively copy directory contents using copy_file
# @arg $1 string Source directory path
# @arg $2 string Destination directory path
# @example
#   FLAG_RECURSIVE=1
#   copy_directory "/path/to/src" "/path/to/dest"
# @exitcode 0 If all entries copied successfully
# @exitcode 1 If any copy operation fails
# @see ensure_dest_dir copy_file
copy_directory() {
  local src="$1"
  local dest="$2"
  local path rel_path dest_dir dest_file
  local status=0
  local -a find_flags=()

  if ! validate_source "$src"; then
    return 1
  fi

  if ! is_directory "$src"; then
    log_error "Source is not a directory: $src"
    return 1
  fi

  if ! ensure_dest_dir "$dest"; then
    return 1
  fi

  if [[ $FLAG_DEREFERENCE -eq 1 ]]; then
    find_flags+=("-L")
  else
    find_flags+=("-P")
  fi

  if [[ $FLAG_DRY_RUN -eq 1 ]]; then
    log_dry_run "find ${find_flags[*]} \"$src\" -type d -print0"
    log_dry_run "find ${find_flags[*]} \"$src\" \\( -type f -o -type l \\) -print0"
  fi

  while IFS= read -r -d '' path; do
    if [[ "$path" == "$src" ]]; then
      continue
    fi

    rel_path="${path#"$src"/}"
    dest_dir="${dest}/${rel_path}"

    if ! ensure_dest_dir "$dest_dir"; then
      status=1
      if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
        return 1
      fi
    fi
  done < <(command find "${find_flags[@]}" "$src" -type d -print0 2>/dev/null)

  while IFS= read -r -d '' path; do
    rel_path="${path#"$src"/}"
    dest_file="${dest}/${rel_path}"
    dest_dir="$(dirname "$dest_file")"

    if [[ $FLAG_DRY_RUN -eq 0 && ! -d "$dest_dir" ]]; then
      if ! ensure_dest_dir "$dest_dir"; then
        status=1
        if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
          return 1
        fi
        continue
      fi
    fi

    if ! copy_file "$path" "$dest_file"; then
      status=1
      if [[ $FLAG_FAIL_FAST -eq 1 && $FLAG_ABORT_REQUESTED -eq 1 ]]; then
        log_verbose "Aborting directory copy due to fail-fast"
        return 1
      fi
    fi
  done < <(command find "${find_flags[@]}" "$src" \( -type f -o -type l \) -print0 2>/dev/null)

  return $status
}

# ============================================================================
# Main Processing Functions
# ============================================================================

##
# @description Main entry point for xcp.sh
# @arg $@ All command-line arguments
# @example
#   main "$@"
# @exitcode 0 If all operations succeeded
# @exitcode 1 If any errors occurred
# @see parse_args validate_dest_dir validate_source copy_file copy_directory
main() {
  # Parse arguments
  if ! parse_args "$@"; then
    return 1
  fi

  # Validate destination
  local dest_dir
  if is_directory "$DEST_ARG"; then
    dest_dir="$DEST_ARG"
  else
    dest_dir="$(dirname "$DEST_ARG")"
  fi

  if ! validate_dest_dir "$dest_dir"; then
    return 1
  fi

  # Ensure destination directory
  if ! ensure_dest_dir "$dest_dir"; then
    return 1
  fi

  # Process each source
  local src
  for src in "${SOURCE_ARGS[@]}"; do
    if ! validate_source "$src"; then
      if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
        return 1
      fi
      continue
    fi

    if is_directory "$src"; then
      if [[ $FLAG_RECURSIVE -eq 0 ]]; then
        log_error "Skipping directory (use -r): $src"
        if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
          return 1
        fi
        continue
      fi

      # Determine destination path for directory
      local dest_path
      if is_directory "$DEST_ARG"; then
        dest_path="$DEST_ARG/$(basename "$src")"
      else
        dest_path="$DEST_ARG"
      fi

      if ! copy_directory "$src" "$dest_path"; then
        if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
          return 1
        fi
      fi
    else
      if ! copy_file "$src" "$DEST_ARG"; then
        if [[ $FLAG_FAIL_FAST -eq 1 ]]; then
          return 1
        fi
      fi
    fi
  done

  # Report errors if any
  local error_count
  error_count=$(logger_get_error_count)
  if [[ $error_count -gt 0 ]]; then
    log_error "Completed with $error_count error(s)"
    return 1
  fi

  return 0
}
