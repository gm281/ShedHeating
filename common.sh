#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf -- "%s\n" "$*" >&2; }
log_notable() { printf -- "** %s\n" "$*" >&2; }
warn() { printf -- "** WARN: %s\n" "$*" >&2; }
error() { printf -- "** ERROR: %s\n" "$*" >&2; }
fatal() { error "$@"; exit 1; }

trap 'error "command failed (line ${LINENO})"' ERR

function on_exit {
    # shellcheck disable=2089,2124
    cleanup_cmd="eval '$@'${cleanup_cmd:+"; "}${cleanup_cmd:-}"
}
# shellcheck disable=2090
trap 'eval ${cleanup_cmd:-}' EXIT
on_exit log "Finished cleanup..."


