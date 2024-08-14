#!/usr/bin/env bash

# Usage: build-root-ca-certificate.sh

CURRENT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJECT_PATH="$CURRENT_PATH/.."
ROOT_CA_PATH="$PROJECT_PATH/root-ca"

cd "$ROOT_CA_PATH" || exit 1

mkdir -p certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
openssl genrsa -out private/ca.key.pem 2048
chmod 400 private/ca.key.pem
openssl req -config openssl.cfg \
      -key private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem
chmod 444 certs/ca.cert.pem