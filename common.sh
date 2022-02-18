#!/usr/bin/env bash

CURRENT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
log() { printf -- "${BRIGHT}${CYAN}** %s\n${NORMAL}" "$*" >&2; }
log_notable() { printf -- "${BRIGHT}${RED}** %s\n${NORMAL}" "$*" >&2; }
warn() { printf -- "${BRIGHT}${YELLOW}** WARN: %s\n${NORMAL}" "$*" >&2; }
error() { printf -- "${BRIGHT}${RED}** ERROR: %s\n${NORMAL}" "$*" >&2; }
fatal() { error "$@"; exit 1; }

trap 'error "command failed (line ${LINENO})"' ERR

function on_exit {
    # shellcheck disable=2089,2124
    cleanup_cmd="eval '$@'${cleanup_cmd:+"; "}${cleanup_cmd:-}"
}
# shellcheck disable=2090
trap 'eval ${cleanup_cmd:-}' EXIT
on_exit log "Finished cleanup..."


