#!/bin/bash

RUN_DIR=/var/vcap/sys/run
LOG_DIR=/var/vcap/sys/log
JOB_DIR=/var/vcap/jobs
PACKAGE_DIR=/var/vcap/packages

DOCKER_RUN_DIR=$RUN_DIR/docker
DOCKER_PACKAGE_DIR=${PACKAGE_DIR}/docker
DOCKER_DAEMON_SOCK=${DOCKER_RUN_DIR}/dockerd.sock
DOCKER_HOST="unix://$DOCKER_DAEMON_SOCK"
DOCKER_CMD="${DOCKER_PACKAGE_DIR}/bin/docker -H $DOCKER_HOST"

log() {
  echo [`date`] $*
}

waitForDockerd() {
  sleep_time=3
  timeout=60
  count=0
  while ! $DOCKER_CMD version 2>&1
  do
    log "Docker daemon is not running. Waiting for $sleep_time seconds then check again."
    sleep $sleep_time
    count=$((count + sleep_time));
    if [ $count -ge $timeout ]; then
      log "Error: Docker daemon is still not running after $timeout seconds."
      exit 1
    fi
  done
  log "Docker daemon is running"
}

