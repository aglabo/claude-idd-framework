#!/usr/bin/env bash
#
# @(#) filename-utils.lib.sh
# @description Filename generation utilities for IDD framework
# @version 1.0.0
# @created 2025-10-19
# @author atsushifx
#

##
# @brief Generate URL-safe slug from text
# @description Converts text to lowercase, replaces spaces/special chars with hyphens, removes consecutive hyphens
# @param $1 Input text (e.g., title, summary)
# @param $2 Max length (optional, default: 50)
# @return 0 on success
# @stdout Generated slug (lowercase, hyphens only)
# @example
#   slug=$(generate_slug "Add User Authentication Feature")
#   echo "$slug"  # "add-user-authentication-feature"
##
generate_slug() {
  local text="$1"
  local max_length="${2:-50}"

  # Convert to lowercase, replace spaces and special chars with hyphens
  local slug
  slug=$(echo "$text" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//; s/-$//')

  # Truncate to max length
  slug="${slug:0:$max_length}"

  # Remove trailing hyphen if truncated
  slug="${slug%-}"

  echo "$slug"
}

##
# @brief Generate ISO8601 timestamp
# @description Returns current timestamp in format YYYYMMDD-HHMMSS
# @return 0 on success
# @stdout Timestamp string (e.g., "20251019-143052")
# @example
#   timestamp=$(generate_timestamp)
#   echo "$timestamp"  # "20251019-143052"
##
generate_timestamp() {
  date +"%Y%m%d-%H%M%S"
}

##
# @brief Generate issue draft filename
# @description Creates filename: {issue_no}-{timestamp}-{issue_type}-{slug}.md
#              For new issues: new-{timestamp}-{issue_type}-{slug}.md
# @param $1 Issue title
# @param $2 Issue type (feature|bug|enhancement|task|release|open_topic)
# @param $3 Issue number (optional, default: "new")
# @return 0 on success
# @stdout Generated filename
# @example
#   # New issue
#   filename=$(generate_issue_filename "Add User Auth" "feature")
#   echo "$filename"  # "new-20251019-143052-feature-add-user-auth.md"
#
#   # Existing issue
#   filename=$(generate_issue_filename "Add User Auth" "feature" "42")
#   echo "$filename"  # "42-20251019-143052-feature-add-user-auth.md"
##
generate_issue_filename() {
  local title="$1"
  local issue_type="$2"
  local issue_no="${3:-new}"

  local timestamp
  timestamp=$(generate_timestamp)

  local slug
  slug=$(generate_slug "$title" 30)

  echo "${issue_no}-${timestamp}-${issue_type}-${slug}.md"
}

##
# @brief Generate full path for issue draft file
# @description Combines directory, issue number, timestamp, issue type, and slug into full path
# @param $1 Issue title
# @param $2 Issue type
# @param $3 Issue number (optional, default: "new")
# @param $4 Directory (optional, default: temp/idd/issues)
# @return 0 on success
# @stdout Full file path
# @example
#   # New issue
#   filepath=$(generate_issue_filepath "Add Auth" "feature")
#   echo "$filepath"  # "temp/idd/issues/new-20251019-143052-feature-add-auth.md"
#
#   # Existing issue
#   filepath=$(generate_issue_filepath "Fix Bug" "bug" "123")
#   echo "$filepath"  # "temp/idd/issues/123-20251019-143052-bug-fix-bug.md"
##
generate_issue_filepath() {
  local title="$1"
  local issue_type="$2"
  local issue_no="${3:-new}"
  local dir="${4:-temp/idd/issues}"

  local filename
  filename=$(generate_issue_filename "$title" "$issue_type" "$issue_no")

  echo "${dir}/${filename}"
}
