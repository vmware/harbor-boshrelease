#!/usr/bin/env bash
generateCerts() {
    if [ "$#" -le 1 ]; then
        echo "USAGE: command IP"
        return 1
    fi

    IP=$1
    LOCATION=$2
    ORG=$3
    CN_CA=$4
    CN_CERT=$5
    OPENSSLCNF=

    if [[ -z ${IP} ]]; then
        echo "IP should not be empty"
        return 2
    fi

    #Check parameters
    if [[ -z ${LOCATION} ]]; then
        LOCATION="Bei Jing"
    fi

    if [[ -z ${ORG} ]]; then
        ORG="VMware"
    fi

    if [[ -z ${CN_CA} ]]; then
        CN_CA="HarborCA"
    fi

    if [[ -z ${CN_CERT} ]]; then
        CN_CERT="HarborManager"
    fi

    #Check and set OPENSSLCNF
    for path in /etc/openssl/openssl.cnf /etc/ssl/openssl.cnf /usr/local/etc/openssl/openssl.cnf; do
        if [[ -e ${path} ]]; then
            OPENSSLCNF=${path}
        fi
    done

    if [[ -z ${OPENSSLCNF} ]]; then
        echo "Could not find openssl.cnf"
        return 3
    fi

    # Create CA certificate
    openssl req \
        -newkey rsa:4096 -nodes -sha256 -keyout harbor_ca.key \
        -x509 -days 365 -out harbor_ca.crt -subj "/C=CN/ST=PEK/L=${LOCATION}/O=${ORG}/CN=${CN_CA}"
    
    if [[ $? != 0 ]] ; then
        return 4
    fi
    
    # Generate a Certificate Signing Request
    openssl req \
        -newkey rsa:4096 -nodes -sha256 -keyout $IP.key \
        -out $IP.csr -subj "/C=CN/ST=PEK/L=${LOCATION}/O=${ORG}/CN=${CN_CERT}"

    if [[ $? != 0 ]] ; then
        return 5
    fi

    # Generate the certificate of local registry host
    echo subjectAltName = IP:$IP > extfile.cnf
    openssl x509 -req -days 365 -in $IP.csr -CA harbor_ca.crt \
        -CAkey harbor_ca.key -CAcreateserial -extfile extfile.cnf -out $IP.crt

    if [[ $? != 0 ]] ; then
        return 6
    fi

    return 0
}
