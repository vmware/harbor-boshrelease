#!/usr/bin/env bash

set -e

prepend_nameserver() {
  local CONFIG_FILE=$1
  local NAMESERVER="169.254.0.2"

  # prepend bosh dns server
  echo -e "nameserver ${NAMESERVER}\n$(cat ${CONFIG_FILE})" > ${CONFIG_FILE}

  # remove any duplicates, matters if this script gets executed multiple times
  echo "$(uniq ${CONFIG_FILE})" > ${CONFIG_FILE}
}
