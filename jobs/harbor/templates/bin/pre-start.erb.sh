#!/usr/bin/env bash

set -e # exit immediately if a simple command exits with a non-zero status

[ -z "${DEBUG:-}" ] || set -x

source /var/vcap/packages/common/utils.sh

NFS_PKG_DIR=/var/vcap/packages/nfs-common
PACKAGE_DIR=/var/vcap/packages
JOB_NAME=harbor
HARBOR_JOB_DIR=/var/vcap/jobs/$JOB_NAME
HARBOR_PACKAGE_DIR=${PACKAGE_DIR}/harbor-app
HARBOR_PERSISTED_DATA=/var/vcap/store/$JOB_NAME
HARBOR_IMAGES_TAR_PATH=${HARBOR_PACKAGE_DIR}/harbor*.tar
HARBOR_DATA=/data
HARBOR_DB_BACKUP_DIR=$HARBOR_DATA/db_backup
HARBOR_VERSION_FILE=$HARBOR_PERSISTED_DATA/harbor_version
CFG_FILE=${HARBOR_JOB_DIR}/config/harbor.cfg
CRON_PATH=/etc/cron.d/$JOB_NAME
CERTS_D=/etc/docker/certs.d
PYTHON_CMD=${PACKAGE_DIR}/python/python2.7/bin/python
HARBOR_LOG_DIR=$LOG_DIR/$JOB_NAME
HARBOR_BUNDLE_DIR=/var/vcap/packages/harbor-app
COMPOSE_PACKAGE_DIR=${PACKAGE_DIR}/docker-compose
COMPOSE_CMD=${COMPOSE_PACKAGE_DIR}/bin/docker-compose
HARBOR_YAML=${HARBOR_PACKAGE_DIR}/docker-compose.yml
INTIAL_DELAY_MINUTES_TIMEOUT=<%= p("initial_delay_minutes") %>
source $PACKAGE_DIR/harbor-common/common.sh
source $HARBOR_JOB_DIR/bin/properties.sh

if [ -f $HARBOR_VERSION_FILE ]; then
  INSTALLED_HARBOR_VERSION=$(cat ${HARBOR_VERSION_FILE} )
else 
  log "/data/harbor_version file not found!"
fi

# Add FQDN to /etc/hosts, for monit_status script to access Harbor
function populateHostname() {
  :
  <%- if p("populate_etc_hosts") %>
  #Populate /etc/hosts
  fqdn=<%= p("hostname") %>
  ip=<%= spec.ip %>
  sed -i -e "/$ip/d" /etc/hosts
  <%-   if spec.ip != p("hostname") %>
  sed -i -e "/$fqdn/d" /etc/hosts
  echo "$ip $fqdn" >> /etc/hosts
  <%-   end %>
  <%- end %>
}

# Create all directories need to run harbor
function prepareFolderAndFile() {
  # Make sure folders are ready
  for dir in $HARBOR_PERSISTED_DATA ; do
    mkdir -p ${dir}
    chown vcap:vcap ${dir}
    chmod 755 ${dir}
  done

  #Link Harbor Data dir to Bosh Persistent Disk
  #See https://bosh.io/docs/persistent-disks.html
  ln -sfT $HARBOR_PERSISTED_DATA $HARBOR_DATA

  #Add symbol link to harbor logs dir, then 'bosh logs' can collect them.
  ln -sfT /var/log/harbor $HARBOR_LOG_DIR/harbor-app-logs

  if [ ! -f $HARBOR_VERSION_FILE ]; then
      touch $HARBOR_VERSION_FILE
  fi

  cp -f ${HARBOR_JOB_DIR}/config/harbor.yml  ${HARBOR_PACKAGE_DIR}/harbor.yml

  #Workaround to resolve the docker-compose libz issue
  sudo mount /tmp -o remount,exec
}

# Process container network settings, such as ip address pool
function customizeContainerNetworkSettings() {
  :
  mkdir -p /etc/docker/
  cp ${HARBOR_JOB_DIR}/config/daemon.json /etc/docker/daemon.json -f
}

function prepareCert() {
  if [ "$HARBOR_PROTOCOL" = "https" ]; then
    #Copy cert to the right place
    mkdir -p $HARBOR_DATA/cert
    mkdir -p $HARBOR_DATA/ca_download

    cp ${HARBOR_JOB_DIR}/config/server.crt /tmp/
    cp ${HARBOR_JOB_DIR}/config/server.key /tmp/
    cp ${HARBOR_JOB_DIR}/config/uaa_ca.crt $HARBOR_DATA/cert/
    cp ${HARBOR_JOB_DIR}/config/trusted_certificates.crt /tmp/
    chmod 644 /tmp/trusted_certificates.crt
    chmod 644 $HARBOR_DATA/cert/*

    cp ${HARBOR_JOB_DIR}/config/ca.crt $HARBOR_DATA/ca_download
    chmod 644  $HARBOR_DATA/ca_download/ca.crt
    #For status checking script usage
    CERT_PATH=$CERTS_D/${HARBOR_HOSTNAME}
    mkdir -p $CERT_PATH
    chown vcap:vcap ${CERT_PATH}
    chmod 755 ${CERT_PATH}
    cp $HARBOR_DATA/ca_download/ca.crt ${CERT_PATH}
  fi
}

# Copy GCS file file to registry config dir
setupGCSKeyFile() {
  if [ ! -z "$(cat ${HARBOR_JOB_DIR}/config/gcs_keyfile)" ]; then
    log 'Copy GCS keyfile to registry'
    cp ${HARBOR_JOB_DIR}/config/gcs_keyfile ${HARBOR_PACKAGE_DIR}/common/config/registry/
    chmod 644 ${HARBOR_PACKAGE_DIR}/common/config/registry/*
  fi
}

function getPrepareOption() {
  
  if [ -n "$WITH_TRIVY" ]; then
    echo " --with-trivy"
  fi
  
}

# Run prepare 
function installHarbor() {
  docker() {
      ${DOCKER_PACKAGE_DIR}/bin/docker -H $DOCKER_HOST $*
  }
  docker-compose() {
      ${PACKAGE_DIR}/docker-compose/bin/docker-compose -H $DOCKER_HOST  $*
  }
  prepareOps=$(getPrepareOption)

  source ${HARBOR_PACKAGE_DIR}/prepare ${prepareOps}

  unset -f docker
  unset -f docker-compose
}

# Check existing Harbor Version
checkHarborVersion() {
  if [ -z "$INSTALLED_HARBOR_VERSION" ]; then
       # Harbor was not installed on this machine before.
       echo 2
  else
    compareVersion $INSTALLED_HARBOR_VERSION $HARBOR_FULL_VERSION
  fi
}

backupHarborDB() {
  timestamp=$(date +"%Y-%m-%d-%H-%M")
  rm -rf /data/database_backup*
  log "Start to backup database..." 
  cp -r /data/database /data/database_backup_${INSTALLED_HARBOR_VERSION}_$timestamp
  log "Backup database data to directory /data/database_backup_${INSTALLED_HARBOR_VERSION}_$timestamp, done" 
}

#Load Harbor images
loadImages() {
  result=$(checkHarborVersion)
  if [ $result -eq 0 ]; then
    # No need to load the same images twice for same version
    return
  fi
  waitForDockerd
  log "clean up docker images before load"
  $DOCKER_CMD image prune -a -f
  #Load images
  log "Loading docker images ..."
  $DOCKER_CMD load -i $HARBOR_IMAGES_TAR_PATH 2>&1
}

# Setup NFS directory and update docker-compose.yml
function setupNFS() {
  :
  <%- if_p("registry_storage_provider.nfs.server_uri") do |uri| -%>
  mount_point='<%= p("registry_storage_provider.nfs.mount_point") %>'
  # Change default storage for registry container to the mount_point.
  # /data is linked to /var/vcap/store/harbor which mounts /dev/sdc1. Need to mount NFS to a directory outside /data.
  # Otherwise when bosh recreates Harbor VM, 'umount /var/vcap/store' on existing VM wll fail.
  sed -i "s|/data/registry:/storage|$mount_point:/storage|" ${HARBOR_PACKAGE_DIR}/docker-compose.yml
  # Ensure the replacement succeeded
  if ! grep -q "$mount_point:/storage" ${HARBOR_PACKAGE_DIR}/docker-compose.yml ; then
    log "Failed to config NFS storage mapping for registry container."
    exit 1
  fi
  # Mount NFS Server
  nfs_uri='<%= uri %>'
  mkdir -p $mount_point
  if ! mount | grep -q $nfs_uri ; then
    set +e
    source ${NFS_PKG_DIR}/install_nfs_common.sh    
    mount $nfs_uri $mount_point
    
    set -e
  fi
  <%- end -%>
}

# Register UAA client
function registerUAA() {
    #If auth mode is 'uaa_auth' and admin client existing, try to register UAA client for Harbor registry
    if [ $AUTH_MODE = 'uaa_auth' ] && [[ ! -z "${UAA_ADMIN// }" ]]; then
      source $HARBOR_JOB_DIR/bin/uaa.sh
      register_harbor_uaa_client
    fi
}

function startDockerDaemon() {
    #Start docker daemon
    /var/vcap/jobs/docker/bin/ctl start
}

function waitForBoshDNS() {
    #Wait for bosh dns service. uaa.sh depends on it to resolve PKS/PAS UAA FQDN.
    /var/vcap/jobs/bosh-dns/bin/wait
}

function updateVersionFile() {
   #Save installed harbor version to file
   echo $HARBOR_FULL_VERSION > $HARBOR_VERSION_FILE
}

function cleanCertFile(){
  rm -rf /tmp/server.key /tmp/server.crt /tmp/trusted_certificates.crt
}

# It might take long time to do in-container migrate, 
# if do this process in ctl start, it will expire the status check (300 seconds) 
# put it in prestart script  
function warmUpHarbor(){
  result=$(checkHarborVersion)
  if [ $result -ge 0 ]; then
    log "Skip to warm up Harbor for fresh install or same version"
    return
  fi
  
  backupHarborDB

  waitForDockerd
  $COMPOSE_CMD -H ${DOCKER_HOST} -f ${HARBOR_YAML} up -d
  waitForHarborReady
  $COMPOSE_CMD -H ${DOCKER_HOST} -f ${HARBOR_YAML} down -v
}

function waitForHarborReady() {
    set +e
    TIMEOUT=${INTIAL_DELAY_MINUTES_TIMEOUT}
    harbor_url=${HARBOR_HOSTNAME}
    protocol='<%= p("ui_url_protocol") %>'

    curl_command="curl -s"
    if [ "$protocol" = "https" ]; then
      curl_command="$curl_command --cacert $HARBOR_JOB_DIR/config/ca.crt"
    fi
    # Wait for /api/v2.0/systeminfo return 200
    while [ "$(${curl_command}  -o /dev/null -w '%{http_code}' ${protocol}://${harbor_url}/api/v2.0/systeminfo)" != "200" ]; do
      TIMEOUT=$((TIMEOUT - 1))
      sleep 60
      echo "waiting for harbor ready ..."
      if [ $TIMEOUT -eq 0 ]; then
        echo "Harbor can not start in time"
        exit 1
      fi
    done

    set -e
}
log "Installing Harbor $HARBOR_FULL_VERSION"

prepareFolderAndFile
populateHostname 
customizeContainerNetworkSettings
startDockerDaemon
prepareCert
loadImages
installHarbor
setupGCSKeyFile
setupNFS
registerUAA
waitForBoshDNS
cleanCertFile
warmUpHarbor
updateVersionFile

log "Successfully done!"
exit 0
