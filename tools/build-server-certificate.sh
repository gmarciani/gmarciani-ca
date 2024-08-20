#!/usr/bin/env bash
set -e

# Usage: build-server-certificate.sh

PROJECT_PATH="$( cd -- "$(dirname "$0")/.." >/dev/null 2>&1 ; pwd -P )"

# Main Folders
ROOT_CA_PATH="$PROJECT_PATH/root-ca"
INTERMEDIATE_CA_PATH="$PROJECT_PATH/intermediate-ca"
INTERMEDIATE_CA_CERTS_PATH="$INTERMEDIATE_CA_PATH/certs"
SERVER_PATH="$PROJECT_PATH/server"

# OpenSSL Configuration
SERVER_CONFIG="$SERVER_PATH/openssl.cfg"
INTERMEDIATE_CA_CONFIG="$INTERMEDIATE_CA_PATH/openssl.cfg"

# Output Directories
SERVER_PRIVATE_PATH="$SERVER_PATH/private"
SERVER_CERTS_PATH="$SERVER_PATH/certs"
SERVER_CSR_PATH="$ROOT_CA_PATH/csr"

# Files
SERVER_PRIVATE_KEY="$SERVER_PRIVATE_PATH/yawa.com.key.pem"
SERVER_P12="$SERVER_PRIVATE_PATH/yawa.com.p12"
SERVER_CSR="$SERVER_CSR_PATH/yawa.com.csr.pem"
SERVER_CERT="$SERVER_CERTS_PATH/yawa.com.cert.pem"
CA_CHAIN_CERT="$INTERMEDIATE_CA_CERTS_PATH/ca-chain.cert.pem"

# Initialize folders and files
mkdir -p "$SERVER_PRIVATE_PATH"
mkdir -p "$SERVER_CERTS_PATH"
mkdir -p "$SERVER_CSR_PATH"
chmod 700 "$SERVER_PRIVATE_PATH"

# Create Private Key for the Server
openssl genrsa -out "$SERVER_PRIVATE_KEY" 3072
chmod 400 "$SERVER_PRIVATE_KEY"

# Create Certificate Signing Request
openssl req -config "$SERVER_CONFIG" \
      -new \
      -key "$SERVER_PRIVATE_KEY" \
      -out "$SERVER_CSR"

# Create Certificate for the Server
cd "$INTERMEDIATE_CA_PATH" || exit 1
openssl ca -config "$INTERMEDIATE_CA_CONFIG" \
      -extensions server_cert \
      -batch -notext \
      -in "$SERVER_CSR" \
      -out "$SERVER_CERT"
chmod 444 "$SERVER_CERT"

# Checks
openssl x509 -noout -text -in "$SERVER_CERT"
openssl verify -CAfile "$CA_CHAIN_CERT" "$SERVER_CERT"

# Export to PKCS12 format
openssl pkcs12 -export \
    -name "YAWA" \
    -in "$SERVER_CERT" \
    -inkey "$SERVER_PRIVATE_KEY" \
    -password "pass:yawapass" \
    -out "$SERVER_P12"