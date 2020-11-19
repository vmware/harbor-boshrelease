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

waitForDBReady

<%- if p("auth_mode") == "uaa_auth" %>
<%- if p("uaa.is_saml_backend") == true %>
$CONFIG_CMD -config-oidc -harbor-server https://<%= p("hostname") %> -password '<%= p("admin_password_for_smoketest") %>' -uaa-server <%= p("uaa.url") %>
<%- else %>
$CONFIG_CMD -config-uaa -harbor-server https://<%= p("hostname") %> -password '<%= p("admin_password_for_smoketest") %>' -uaa-server  <%= p("uaa.url") %> -verify-cert
<%- end %>

<%- end %>



exit 0