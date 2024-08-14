#!/usr/bin/env bash

# Usage: build-intermediate-ca-certificate.sh

CURRENT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_PATH="$CURRENT_PATH/.."
ROOT_CA_PATH="$PROJECT_PATH/root-ca"
INTERMEDIATE_CA_PATH="$PROJECT_PATH/intermediate-ca"

cd "$INTERMEDIATE_CA_PATH" || exit 1

mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
openssl genrsa -out private/intermediate.key.pem 2048
chmod 400 private/intermediate.key.pem

cd "$ROOT_CA_PATH" || exit 1

openssl req -config "$INTERMEDIATE_CA_PATH/openssl.cfg" -new -sha256 \
      -key "$INTERMEDIATE_CA_PATH/private/intermediate.key.pem" \
      -out "$INTERMEDIATE_CA_PATH/csr/intermediate.csr.pem"

cd "$ROOT_CA_PATH" || exit 1
openssl ca -config openssl.cfg -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in "$INTERMEDIATE_CA_PATH/csr/intermediate.csr.pem" \
      -out "$INTERMEDIATE_CA_PATH/certs/intermediate.cert.pem"
chmod 444 "$INTERMEDIATE_CA_PATH/certs/intermediate.cert.pem"

openssl x509 -noout -text \
      -in "$INTERMEDIATE_CA_PATH/certs/intermediate.cert.pem"

openssl verify -CAfile "$ROOT_CA_PATH/certs/ca.cert.pem" \
      "$INTERMEDIATE_CA_PATH/certs/intermediate.cert.pem"

cat "$INTERMEDIATE_CA_PATH/certs/intermediate.cert.pem" \
      "$ROOT_CA_PATH/certs/ca.cert.pem" > "$INTERMEDIATE_CA_PATH/certs/gmarciani-ca-chain.cert.pem"
chmod 444 "$INTERMEDIATE_CA_PATH/certs/gmarciani-ca-chain.cert.pem"