#!/bin/bash

set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

source /var/vcap/packages/common/utils.sh

JOB_NAME=harbor
HARBOR_JOB_DIR=/var/vcap/jobs/$JOB_NAME
CFG_FILE=${HARBOR_JOB_DIR}/config/harbor.cfg
DOCKER_PACKAGE_DIR=${HARBOR_JOB_DIR}/packages/docker
RUN_DIR=/var/vcap/sys/run
HARBOR_RUN_DIR=$RUN_DIR/$JOB_NAME
PIDFILE=${HARBOR_RUN_DIR}/harbor.pid
DAEMON_SOCK=${RUN_DIR}/docker/dockerd.sock
PYTHON_DIR=${PACKAGE_DIR}/python/python2.7/bin
source $HARBOR_JOB_DIR/bin/properties.sh
export PATH=$PATH:${DOCKER_PACKAGE_DIR}/bin:${PYTHON_DIR}

#Exit function with pid file deletion
myExit() {
  log "Harbor status check: [FAILED]"
  parseOpts
  if [ "$RESTART_HARBOR" = true ]; then
    log "Now restart harbor job"
    rm -f /etc/cron.d/harbor
    /var/vcap/bosh/bin/monit restart harbor
  fi
  exit $1
}

parseOpts() {
  RESTART_HARBOR=false
  while getopts "r" opt; do
    case $opt in
      r)
        RESTART_HARBOR=true
        ;;
    esac
  done
}

parseOpts $@

#Check if containers existing
harbor_containers=$(docker -H "unix://$DAEMON_SOCK" ps | awk '{print $2}' | grep goharbor)
if [ -z "$harbor_containers" ]; then
  myExit 1
fi

#Check the status of Harbor containers
if docker -H "unix://$DAEMON_SOCK" ps --filter "status=restarting" | grep 'goharbor'; then
  myExit 2
fi

#Check the API
harbor_url=${HARBOR_HOSTNAME}
protocol='<%= p("ui_url_protocol") %>'

curl_command="curl -s"
if [ "$protocol" = "https" ]; then
  curl_command="$curl_command --cacert $HARBOR_JOB_DIR/config/ca.crt"
fi

set +e

echo "${curl_command} ${protocol}://${harbor_url}/api/v2.0/systeminfo"
version=`${curl_command} ${protocol}://${harbor_url}/api/v2.0/systeminfo | python -c "import sys, json; print json.load(sys.stdin)['harbor_version']"`
if [ $? != 0 ] ; then
  myExit 3
fi

if [ -z "$version" ]; then
  myExit 4
fi

#Check Docker Registry connectivity
password='<%= p("admin_password") %>'
login=$(docker -H "unix://$DAEMON_SOCK" login -u admin -p $password $harbor_url 2>&1 )
if [ $? != 0 ] ; then
  # In case the admin password is modified on Harbor UI,
  # the login will fail, but it means the Registry is working well.
  echo $login | grep -q "unauthorized"
  if [ $? != 0 ] ; then
    myExit 5
  fi
fi

log "Harbor status check: [PASSED]"
exit 0
