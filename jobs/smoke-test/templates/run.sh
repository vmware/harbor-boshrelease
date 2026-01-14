#!/bin/bash

set -e -u -x

JOB_NAME=smoke-test

# Prepare directories
RUN_DIR="/var/vcap/sys/run/docker" # For docker daemon
mkdir -p ${RUN_DIR}
chown -R vcap:vcap ${RUN_DIR}
chmod 755 ${RUN_DIR}

# Set package dependencies paths
PACKAGES_DIR=${BOSH_PACKAGES_DIR:-/var/vcap/packages}
SMOKE_TEST_JOB_DIR=/var/vcap/jobs/$JOB_NAME

DOCKER_PACKAGE_DIR=$PACKAGES_DIR/docker
DOCKERD=$DOCKER_PACKAGE_DIR/bin/dockerd
export PATH=$PATH:${DOCKER_PACKAGE_DIR}/bin

CASE_BASE_DIR=${PACKAGES_DIR}/smoke-test
TEST_ENTRYPOINT=$CASE_BASE_DIR/bin/smoke-test

# Set docker runtime files
DOCKER_DAEMON_PIDFILE=$RUN_DIR/dockerd.pid
DOCKER_DAEMON_SOCK=$RUN_DIR/dockerd.sock
DATA_ROOT_DIR="/var/vcap/store"
DOCKER_HOST="unix://$DOCKER_DAEMON_SOCK"

#### Utility functions
# Prepare docker environment
prepareDockerEnv() {
  ulimit -n 8192

  if grep -v '^#' /etc/fstab | grep -q cgroup || [ ! -e /proc/cgroups ] || [ ! -d /sys/fs/cgroup ]; then
    mkdir -p /sys/fs/cgroup
  fi
  if ! mountpoint -q /sys/fs/cgroup; then
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup
  fi
  (cd /sys/fs/cgroup
  for sys in $(awk '!/^#/ { if ($4 == 1) print $1 }' /proc/cgroups); do
    mkdir -p $sys
    if ! mountpoint -q $sys; then
      if ! mount -n -t cgroup -o $sys cgroup $sys; then
        rmdir $sys || true
      fi
    fi
  done)
}

# Start docker daemon
startDockerd() {
  OPT="--data-root ${DATA_ROOT_DIR} --host $DOCKER_HOST"

  /sbin/start-stop-daemon \
  --pidfile $DOCKER_DAEMON_PIDFILE \
  --make-pidfile \
  --background \
  --exec $DOCKERD \
  --oknodo \
  --start \
  -- $OPT

  echo "Docker daemon started"
}

# Stop the dockerd process
stopDockerd() {
  if /sbin/start-stop-daemon --pidfile $DOCKER_DAEMON_PIDFILE --retry TERM/30/QUIT/5/KILL --oknodo --stop; then
    rm -f $DOCKER_DAEMON_PIDFILE
    rm -f $DOCKER_DAEMON_SOCK
  fi

  echo "Docker daemon stopped"
}

# Waiting for docker daemon started
waitForDockerd() {
  sleep_time=3
  timeout=60
  count=0
  while ! docker -H $DOCKER_HOST version >/dev/null
  do
    echo "Docker daemon is not running. Waiting for $sleep_time seconds then check again."
    sleep $sleep_time
    count=$((count + sleep_time));
    if [ $count -ge $timeout ]; then
      echo "Error: Docker daemon is still not running after $timeout seconds."
      exit 1
    fi
  done
  echo "Docker daemon is running"
}

# Start docker daemon for testing if it is not running (for run on a separate node)
SHOULD_STOP="NO"
if ! docker -H $DOCKER_HOST version >/dev/null; then
  prepareDockerEnv
  startDockerd
  #Check and wait
  waitForDockerd

  SHOULD_STOP="YES"
fi

# Load testing image : busybox
BUSYBOX_PATH=$PACKAGES_DIR/busybox/busybox-1.37.0.tar
docker -H $DOCKER_HOST load -i $BUSYBOX_PATH

# Set testing environment
export APP_HOST_IP='<%= link('harbor_reference').instances[0].address %>'
export HTTP_PROTOCOL='<%= link('harbor_reference').p('ui_url_protocol') %>'
export TESTING_ENV_HOSTNAME='<%= link('harbor_reference').p('hostname').downcase %>'
export TESTING_ENV_ADMIN_PASS='<%= link('harbor_reference').p('admin_password_for_smoketest') %>'
export TESTING_ENV_PASSWORD='<%= link('harbor_reference').p('admin_password_for_smoketest') %>'
export POPULATE_ETC_HOSTS='<%= link('harbor_reference').p('populate_etc_hosts') %>'
export CA_FILE_PATH=$SMOKE_TEST_JOB_DIR/config/ca.crt
export CERT_FILE_PATH=$SMOKE_TEST_JOB_DIR/config/cert.crt
export KEY_FILE_PATH=$SMOKE_TEST_JOB_DIR/config/key.crt
export TESTING_DOCKER_HOST=$DOCKER_HOST
export TESTING_IMAGE_NAME="busybox"
export TESTING_IMAGE_TAG="latest"

if [ "$POPULATE_ETC_HOSTS" = "true" ]; then
  if [ "$APP_HOST_IP" != "$TESTING_ENV_HOSTNAME" ]; then
    sed -i -e "/$APP_HOST_IP/d" /etc/hosts
    sed -i -e "/$TESTING_ENV_HOSTNAME/d" /etc/hosts

    echo "$APP_HOST_IP    $TESTING_ENV_HOSTNAME" >> /etc/hosts
  fi
fi

mkdir -p /etc/docker/certs.d/${TESTING_ENV_HOSTNAME}/
cp $CA_FILE_PATH /etc/docker/certs.d/${TESTING_ENV_HOSTNAME}/

# Enable bosh dns
/var/vcap/jobs/bosh-dns/bin/bosh_dns_resolvconf_ctl start

# Run smoke test
set +e
$TEST_ENTRYPOINT
RET=$?
set -e

# Stop docker daemon
if [ SHOULD_STOP = "YES" ]; then
  stopDockerd
fi

# Return result
exit $RET
