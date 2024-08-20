#!/usr/bin/env bash
set -e

# Usage: build-intermediate-ca-certificate.sh

PROJECT_PATH="$( cd -- "$(dirname "$0")/.." >/dev/null 2>&1 ; pwd -P )"

# Main Folders
ROOT_CA_PATH="$PROJECT_PATH/root-ca"
ROOT_CA_CERTS_PATH="$ROOT_CA_PATH/certs"
INTERMEDIATE_CA_PATH="$PROJECT_PATH/intermediate-ca"

# OpenSSL Configuration
ROOT_CA_CONFIG="$ROOT_CA_PATH/openssl.cfg"
INTERMEDIATE_CA_CONFIG="$INTERMEDIATE_CA_PATH/openssl.cfg"

# Output Directories
INTERMEDIATE_CA_PRIVATE_PATH="$INTERMEDIATE_CA_PATH/private"
INTERMEDIATE_CA_CERTS_PATH="$INTERMEDIATE_CA_PATH/certs"
INTERMEDIATE_CA_NEWCERTS_PATH="$INTERMEDIATE_CA_PATH/newcerts"
INTERMEDIATE_CA_CRL_PATH="$INTERMEDIATE_CA_PATH/crl"
INTERMEDIATE_CA_CSR_PATH="$INTERMEDIATE_CA_PATH/csr"

# Files
INTERMEDIATE_CA_PRIVATE_KEY="$INTERMEDIATE_CA_PRIVATE_PATH/intermediate.key.pem"
INTERMEDIATE_CA_CERT="$INTERMEDIATE_CA_CERTS_PATH/intermediate.cert.pem"
INTERMEDIATE_CA_CSR="$INTERMEDIATE_CA_CSR_PATH/intermediate.csr.pem"
INTERMEDIATE_CA_INDEX="$INTERMEDIATE_CA_PATH/index.txt"
INTERMEDIATE_CA_SERIAL="$INTERMEDIATE_CA_PATH/serial"
INTERMEDIATE_CA_CRLNUMBER="$INTERMEDIATE_CA_PATH/crlnumber"
ROOT_CA_CERT="$ROOT_CA_CERTS_PATH/ca.cert.pem"
CA_CHAIN_CERT="$INTERMEDIATE_CA_CERTS_PATH/ca-chain.cert.pem"

# Initialize folders and files
mkdir -p "$INTERMEDIATE_CA_PRIVATE_PATH"
mkdir -p "$INTERMEDIATE_CA_CERTS_PATH"
mkdir -p "$INTERMEDIATE_CA_NEWCERTS_PATH"
mkdir -p "$INTERMEDIATE_CA_CRL_PATH"
mkdir -p "$INTERMEDIATE_CA_CSR_PATH"
chmod 700 "$INTERMEDIATE_CA_PRIVATE_PATH"
touch "$INTERMEDIATE_CA_INDEX"
echo 1000 > "$INTERMEDIATE_CA_SERIAL"
echo 1000 > "$INTERMEDIATE_CA_CRLNUMBER"

# Create Private Key for the Intermediate CA
openssl genrsa -out "$INTERMEDIATE_CA_PRIVATE_KEY" 3072
chmod 400 "$INTERMEDIATE_CA_PRIVATE_KEY"

# Create Certificate Signing Request
cd "$ROOT_CA_PATH" || exit 1
openssl req -config "$INTERMEDIATE_CA_CONFIG" \
      -new \
      -key "$INTERMEDIATE_CA_PRIVATE_KEY" \
      -out "$INTERMEDIATE_CA_CSR"

# Create Certificate for the Intermediate CA
cd "$ROOT_CA_PATH" || exit 1
openssl ca -config "$ROOT_CA_CONFIG" \
      -extensions v3_intermediate_ca \
      -batch -notext \
      -in "$INTERMEDIATE_CA_CSR" \
      -out "$INTERMEDIATE_CA_CERT"
chmod 444 "$INTERMEDIATE_CA_CERT"

# Checks
openssl x509 -noout -text -in "$INTERMEDIATE_CA_CERT"
openssl verify -CAfile "$ROOT_CA_CERT" "$INTERMEDIATE_CA_CERT"

# CA Chain
cat "$INTERMEDIATE_CA_CERT" "$ROOT_CA_CERT" > "$CA_CHAIN_CERT"
chmod 444 "$CA_CHAIN_CERT"