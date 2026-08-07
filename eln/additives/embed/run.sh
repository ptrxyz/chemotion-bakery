#!/bin/bash
[[ -n ${STARTUPDELAY} ]] && sleep "${STARTUPDELAY}"
[[ -f /embed/lib/env ]] && source /embed/lib/env

function cleanup() {
    rm -rf "${PIDFILE}"
    local pids
    mapfile -t pids < <(jobs -rp)
    if [[ ${#pids[@]} -gt 0 ]]; then
        kill "${pids[@]}" &>/dev/null
    fi
}

trap cleanup EXIT
trap cleanup SIGTERM
trap cleanup SIGINT

cd /chemotion/app || exit 1
[[ -n ${DROP_UID} && -n ${DROP_GID} ]] && {
    DROP="/embed/bin/drop"
}

if [[ "${CONFIG_ROLE}" == "eln" ]]; then
    (cd /embed/ && make all-eln)
    [[ -n ${DROP} ]] && export HOME=/chemotion/app
    exec ${DROP} bundle exec rails s -b 0.0.0.0 -p4000 --pid "${PIDFILE}"
    # exec passenger start -b 0.0.0.0 --pid-file "${PIDFILE}" --port 4000 --max-pool-size 5
elif [[ "${CONFIG_ROLE}" == "worker" ]]; then
    # Wait a bit. give the ELN some time to delete it's lock in case it's still present
    sleep 3
    (cd /embed/ && make all-worker)
    [[ -n ${DROP} ]] && export HOME=/chemotion/app
    exec ${DROP} bundle exec bin/delayed_job ${DELAYED_JOB_ARGS} run
elif [[ "${CONFIG_ROLE}" == "combine" ]]; then
    # Wait a bit. give the ELN some time to delete it's lock in case it's still present
    sleep 3
    (cd /embed/ && make all-eln)
    [[ -n ${DROP} ]] && export HOME=/chemotion/app
    echo "Initializing delayed job..."
    nohup ${DROP} bundle exec bin/delayed_job start
    # if environement variable DO_NOT_SEED is set to true, do not run the seeds
    if [[ -n ${DO_NOT_SEED} && ${DO_NOT_SEED} == "true" ]]; then
        echo "Skipping seeds as DO_NOT_SEED is set to true."
    else
        echo "Running initial seeding in background..."
        nohup ${DROP} /initialize.sh &> /chemotion/app/log/initialize.p2d.log &
    fi
    echo "Starting ELN server..."
    exec ${DROP} bundle exec rails s -b 0.0.0.0 -p4000 --pid "${PIDFILE}"
else
    echo "ERROR: Please specify CONFIG_ROLE ('eln'/'worker'/'combine')."
fi
