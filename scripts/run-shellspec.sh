#!/usr/bin/env bash

# get test typr from 1st argument
TYPE="$1"
OPTION=""

case "$TYPE" in
  unit)
    OPTION='--default-path scripts/__tests__/unit'
    shift
    ;;
  functional)
    OPTION='--default-path scripts/__tests__/functional'
    shift
    ;;
  integration)
    OPTION='--default-path scripts/__tests__/integration'
    shift
    ;;
  e2e)
    OPTION='--default-path scripts/__tests__/e2e'
    shift
    ;;
  *)
    ;;
esac

shellspec ${OPTION} "$@"

