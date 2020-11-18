#Import UAA util functions
source /var/vcap/packages/uaa/uaa.sh

#Function is used to register UAA client for harbor
register_harbor_uaa_client() {
  #Related files
  UAA_JSON_FILE=${HARBOR_JOB_DIR}/config/uaa.json
  UAA_CA_FILE=${HARBOR_JOB_DIR}/config/uaa_ca.crt

  #Start to register Harbor UAA client
  handle_harbor_uaa_client \
    register \
    $UAA_VERIFY_CERT \
    $UAA_CA_FILE \
    $UAA_SERVER_ADDRESS \
    $UAA_ADMIN \
    $UAA_ADMIN_SECRET \
    $HARBOR_UAA_CLIENT_ID \
    $UAA_JSON_FILE
}