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

#Read json from stdin
readJson(){
  #At least one argument
  if [ $# -lt 1 ]; then
    exit 1
  fi

  #Generate the key accessor
  accessor="doc"
  for key in $@; do
    accessor="$accessor['$key']"
  done

  #Read value
  python -c "import sys, json; doc = json.load(sys.stdin); print $accessor"
}

#Compare two version strings. Return value is -1, 0, or 1.
compareVersion() {
  v1="${1:-0.0.1}"
  v2="${2:-0.0.1}"
  cmd="
import sys
from distutils.version import StrictVersion

v1 = StrictVersion(sys.argv[1])
v2 = StrictVersion(sys.argv[2])

if v1 < v2:
  print -1
elif v1 > v2:
  print 1
else:
  print 0
"
  python -c "$cmd" $v1 $v2
}
