#readJson is util function in common package

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

