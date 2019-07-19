#!/usr/bin/env bash

set -e # exit immediately if a simple command exits with a non-zero status

source /var/vcap/packages/common/utils.sh

waitForDBReady() {
    set +e
    TIMEOUT=12
    while [ $TIMEOUT -gt 0 ]; do
        $DOCKER_CMD exec harbor-db pg_isready | grep "accepting connections"
        if [ $? -eq 0 ]; then
                break
        fi
        TIMEOUT=$((TIMEOUT - 1))
        sleep 5
    done
    if [ $TIMEOUT -eq 0 ]; then
        echo "Harbor DB cannot reach within one minute."
        clean_db
        exit 1
    fi
    set -e
}

changeUserConfigSetting() {
    key=$1
    value=$2
    $DOCKER_CMD exec harbor-db psql -U postgres -d registry -c "insert into properties (k, v) values ('$key', '$value') on conflict (k) do update set v = '$value';"
}

waitForDBReady

changeUserConfigSetting auth_mode <%= p("auth_mode") %>

<%- if p("auth_mode") == "uaa_auth" %>


<%- if p("uaa.is_saml_backend") == true %>
changeUserConfigSetting auth_mode oidc_auth
changeUserConfigSetting oidc_name uaa
changeUserConfigSetting oidc_endpoint <%= p("uaa.url") %>/auth/token
changeUserConfigSetting oidc_client_id <%= p("uaa.client_id") %>
changeUserConfigSetting oidc_client_secret <%= p("uaa.client_secret") %>
changeUserConfigSetting oidc_scope openid
changeUserConfigSetting oidc_verify_cert <%= p("uaa.verify_cert") %>
<%- else %>
changeUserConfigSetting uaa_endpoint <%= p("uaa.url") %>
changeUserConfigSetting uaa_client_id <%= p("uaa.client_id") %>
changeUserConfigSetting uaa_client_secret <%= p("uaa.client_secret") %>
changeUserConfigSetting uaa_verify_cert <%= p("uaa.verify_cert") %>
<%- end %>

<%- end %>



exit 0