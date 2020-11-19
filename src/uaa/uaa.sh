#readJson is util function in common package
#log is util function in common package

#Get access token of UAA
#Access token will be returned if succeed
#e.g: get_uaa_access_token 'curl -k' 'http://localhost/uaa' 'admin' 'secret'
get_uaa_access_token() {
  #Four parameters
  #curl command, UAA address, UAA admin client and admin client secret are requried
  if [ $# -lt 4 ]; then
    return 1
  fi

  curl_command=$1
  uaa_address=$2
  uaa_admin=$3
  uaa_admin_secret=$4

  access_token=$($curl_command "$uaa_address/oauth/token" -X POST \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept: application/json' \
  -d "client_id=$uaa_admin&client_secret=$uaa_admin_secret&grant_type=client_credentials&token_format=opaque&response_type=token" | \
  readJson "access_token")

  ret=$?
  echo $access_token
  return $ret
}

#Get info of specified client ID
#Client ID or empty string will be returned
#e.g: get_uaa_client_info 'curl -k' 'http://localhost/uaa' 'harbor_uaa_client_id' '5166910e847b4401a91f88e65e76c366'
get_uaa_client_info() {
  #Four parameters
  #curl command, UAA address, client ID and bearer token are requried
  if [ $# -lt 4 ]; then
    return 1
  fi

  curl_command=$1
  uaa_address=$2
  client_id=$3
  bearer_token=$4

  client_id_curled=$($curl_command "$uaa_address/oauth/clients/$client_id" \
  -H "Authorization: Bearer $bearer_token" \
  -H 'Accept: application/json' | \
  readJson "client_id")

  echo $client_id_curled
}

#Delete the specified client from UAA server
#e.g: delete_uaa_client 'curl -k' 'http://localhost/uaa' 'harbor_uaa_client_id' '5166910e847b4401a91f88e65e76c366'
delete_uaa_client() {
  #Four parameters
  #curl command, UAA address, client ID and bearer token are requried
  if [ $# -lt 4 ]; then
    return 1
  fi

  curl_command=$1
  uaa_address=$2
  client_id=$3
  bearer_token=$4

  $curl_command "$uaa_address/oauth/clients/$client_id" -X DELETE \
  -H "Authorization: Bearer $bearer_token" \
  -H 'Accept: application/json' | readJson "client_id" >/dev/null

  return $?
}

#Register the UAA client to UAA server
#e.g: register_uaa_client 'curl -k' 'http://localhost/uaa' '5166910e847b4401a91f88e65e76c366' '{}'
register_uaa_client() {
  #Four parameters
  #curl command, UAA address, bearer token and uaa properties json are requried
  if [ $# -lt 4 ]; then
    return 1
  fi

  curl_command=$1
  uaa_address=$2
  bearer_token=$3
  uaa_properties=$4

  $curl_command "$uaa_address/oauth/clients" -X POST \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $bearer_token" \
  -H 'Accept: application/json' \
  -d "$uaa_properties" | readJson "client_id" >/dev/null

  return $?
}

# Register or unregister the Harbor UAA client if exist
# e.g: register a uaa client
#  handle_harbor_uaa_client \
#      register
#      true \
#      "/var/vcap/jobs/harbor/config/uaa_ca.crt" \
#      "https://api.pks.local/uaa" \
#      "admin" \
#      "secret" \
#      "harbor_uaa_client" \
#      "/var/vcap/jobs/harbor/config/uaa.json" #If registering needed
#
# To unregister a uaa client
#  handle_harbor_uaa_client
#     unregister \
#     true   \
#     "/var/vcap/jobs/harbor/config/uaa_ca.crt" \
#     "https://api.pks.local/uaa" \
#      "admin" \
#      "secret" \
#      "harbor_uaa_client"

handle_harbor_uaa_client() {
  # operation can be register/unregister
  operation=$1;shift;
  # Check verify cert parameter
  uaa_verify_cert=$1;shift;
  uaa_ca_file=$1;shift;

  #Build curl command prefix
  curl_cmd="curl -k"
  if [ "$uaa_verify_cert" = "true" ] && [ -f "$uaa_ca_file" ]; then
    curl_cmd="curl --cacert $uaa_ca_file"
  fi

  #Required parameters
  uaa_server_address=$1;shift;
  uaa_admin=$1;shift;
  uaa_admin_secret=$1;shift;
  harbor_uaa_client_id=$1;shift;

  #Get OAuth admin token
  log "Getting access token from UAA server..."
  access_token=$(get_uaa_access_token "$curl_cmd" $uaa_server_address $uaa_admin $uaa_admin_secret)

  #Try to get and check if the specified harbor uaa client existing
  log "Checking if Harbor UAA client id '$harbor_uaa_client_id' exists"
  harbor_uaa_client_curled=$(get_uaa_client_info "$curl_cmd" $uaa_server_address $harbor_uaa_client_id $access_token)

  #Existing
  if [ "x$harbor_uaa_client_curled" = "x$harbor_uaa_client_id" ]; then
    if [ "$operation" = "unregister" ]; then
      log "Harbor UAA client id '$harbor_uaa_client_id' existing, unregister it"
      delete_uaa_client "$curl_cmd" $uaa_server_address $harbor_uaa_client_id $access_token
    fi
    return $?
  fi

  if [ $# -gt 0 ]; then
    uaa_json_file=$1
    if [ -f $uaa_json_file ]; then
      #Create harbor UAA client
      uaa_properties=$($CONFIG_CMD -show-uaa -uaa-json $uaa_json_file)

      log "Registering Harbor UAA client '$harbor_uaa_client_id'..."
      register_uaa_client "$curl_cmd" $uaa_server_address $access_token "$uaa_properties"

      log "Harbor UAA client '$harbor_uaa_client_id' is successfully registered!"
    fi
  fi
  
}

