#!/usr/bin/env bash

# Usage: build-server-certificate.sh

CURRENT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_PATH="$CURRENT_PATH/.."
ROOT_CA_PATH="$PROJECT_PATH/root-ca"
INTERMEDIATE_CA_PATH="$PROJECT_PATH/intermediate-ca"
SERVER_PATH="$PROJECT_PATH/server"


openssl genrsa -out "$SERVER_PATH/private/yawa.com.key.pem" 2048
chmod 400 "$SERVER_PATH/private/yawa.com.key.pem"

openssl req -config "$SERVER_PATH/openssl.cfg" \
      -key "$SERVER_PATH/private/yawa.com.key.pem" \
      -new -sha256 -out "$SERVER_PATH/csr/yawa.com.csr.pem"

cd "$INTERMEDIATE_CA_PATH" || exit 1
openssl ca -config openssl.cfg \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in "$SERVER_PATH/csr/yawa.com.csr.pem" \
      -out "$SERVER_PATH/certs/yawa.com.cert.pem"
chmod 444 "$SERVER_PATH/certs/yawa.com.cert.pem"

cd ..
openssl x509 -noout -text \
      -in "$SERVER_PATH/certs/yawa.com.cert.pem"

openssl verify -CAfile "$INTERMEDIATE_CA_PATH/certs/ca-chain.cert.pem" \
      "$SERVER_PATH/certs/yawa.com.cert.pem"

openssl pkcs12 -export \
    -name "YAWA" \
    -in "$SERVER_PATH/certs/yawa.com.cert.pem" \
    -inkey "$SERVER_PATH/private/yawa.com.key.pem" \
    -out "$SERVER_PATH/private/yawa.p12"