#!/bin/bash

set -eou pipefail

CURRENT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${CURRENT_SCRIPT_DIR}/common.sh"

HEATMISER_BRIDGE_IP="192.168.4.255"
HEATMISER_BRIDGE_PORT="4242"
SHED_ZONE_NAME="Shed"
SHED_PLUG_ZONE_NAME="Shed Plug"
HEATING_TEMPERATURE_DELTA="-1.0"
OVERHEAT_TEMPERATURE_DELTA="0.3"

function run_bridge_command() {
    local command="$1"
    printf "${command}\0" | nc -q 0 "${HEATMISER_BRIDGE_IP}" "${HEATMISER_BRIDGE_PORT}"
}

function get_actual_temperature() {
    run_bridge_command '{"GET_LIVE_DATA": 0}' | jq -r '.devices[] | select(.ZONE_NAME=="'"${SHED_ZONE_NAME}"'") | .ACTUAL_TEMP'
}

function get_set_temperature() {
    run_bridge_command '{"GET_LIVE_DATA": 0}' | jq -r '.devices[] | select(.ZONE_NAME=="'"${SHED_ZONE_NAME}"'") | .SET_TEMP'
}

function switch_plug_on_with_timer() {
    run_bridge_command '{"TIMER_HOLD_ON":[5, "'"${SHED_PLUG_ZONE_NAME}"'"]}'
    echo ""
}

function switch_plug_off() {
    run_bridge_command '{"TIMER_OFF": "'"${SHED_PLUG_ZONE_NAME}"'"}'
    echo ""
}

function needs_heating() {
    set_temperature="$(get_set_temperature)"
    log "Set temperature: ${set_temperature}"
    actual_temperature="$(get_actual_temperature)"
    log "Actual temperature: ${actual_temperature}"

    echo "${actual_temperature} - ${set_temperature} < ${HEATING_TEMPERATURE_DELTA}" | bc -l
}

function heat() {
    log_notable "Switching to heating mode"
    while true; do
        log "$(date)"
        set_temperature="$(get_set_temperature)"
        log "Set temperature: ${set_temperature}"
        actual_temperature="$(get_actual_temperature)"
        log "Actual temperature: ${actual_temperature}"

        needs_heating="$(echo "${actual_temperature} - ${set_temperature} < ${OVERHEAT_TEMPERATURE_DELTA}" | bc -l)"
        log "Needs heating in heating mode: ${needs_heating}"
        if (( needs_heating <= 0)); then 
            log_notable "Ending heating mode"
            switch_plug_off
            break
        fi
        switch_plug_on_with_timer

        sleep 10
    done
}

if (( $(echo "${HEATING_TEMPERATURE_DELTA} > ${OVERHEAT_TEMPERATURE_DELTA}" | bc -l) )); then
    fatal "HEATING_TEMPERATURE_DELTA: ${HEATING_TEMPERATURE_DELTA} musn't be bigger than OVERHEAT_TEMPERATURE_DELTA: ${OVERHEAT_TEMPERATURE_DELTA}"
fi

while true; do
    log "$(date)"
    needs_heating=$(needs_heating)
    if (( needs_heating > 0 )); then
        heat
    fi
    sleep 1
done

