#!/bin/bash

set -e -u

[ -z "${DEBUG:-}" ] || set -x

JOB_NAME=uaa-deregistration
UAA_DEREGISTRATION_JOB_DIR=/var/vcap/jobs/$JOB_NAME

#Import auth and UAA proeprties
AUTH_MODE='<%= link('harbor_uaa_reference').p('auth_mode') %>'
UAA_ADMIN_CLIENT_ID='<%= link('harbor_uaa_reference').p('uaa.admin.client_id') %>'

#If auth mode is not 'uaa_auth' or admin client is not existing, nothing need to do
if [ $AUTH_MODE != 'uaa_auth' ] || [[ -z "${UAA_ADMIN_CLIENT_ID// }" ]]; then
  exit 0
fi

#Import util script libs
source /var/vcap/packages/common/utils.sh
source ${PACKAGE_DIR}/uaa/uaa.sh

#Need to do deregistration
#Related properties from bosh link
UAA_CA_FILE=${UAA_DEREGISTRATION_JOB_DIR}/config/uaa_ca.crt
#Convert UAA server FQDN to lowercase
UAA_SERVER_ADDRESS='<%= link('harbor_uaa_reference').p('uaa.url').downcase %>'
UAA_VERIFY_CERT='<%= link('harbor_uaa_reference').p('uaa.verify_cert') %>'
HARBOR_UAA_CLIENT_ID='<%= link('harbor_uaa_reference').p('uaa.client_id') %>'
UAA_ADMIN_CLIENT_SECRET='<%= link('harbor_uaa_reference').p('uaa.admin.client_secret') %>'

#Start to unregister Harbor UAA client
handle_harbor_uaa_client \
  unregister \
  $UAA_VERIFY_CERT \
  $UAA_CA_FILE \
  $UAA_SERVER_ADDRESS \
  $UAA_ADMIN_CLIENT_ID \
  $UAA_ADMIN_CLIENT_SECRET \
  $HARBOR_UAA_CLIENT_ID

exit 0

