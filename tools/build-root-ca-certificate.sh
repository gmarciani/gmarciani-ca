#!/usr/bin/env bash
set -e

# Usage: build-root-ca-certificate.sh

PROJECT_PATH="$( cd -- "$(dirname "$0")/.." >/dev/null 2>&1 ; pwd -P )"

# Main Folders
ROOT_CA_PATH="$PROJECT_PATH/root-ca"

# OpenSSL Configuration
ROOT_CA_CONFIG="$ROOT_CA_PATH/openssl.cfg"

# Output Directories
ROOT_CA_PRIVATE_PATH="$ROOT_CA_PATH/private"
ROOT_CA_CERTS_PATH="$ROOT_CA_PATH/certs"
ROOT_CA_NEWCERTS_PATH="$ROOT_CA_PATH/newcerts"
ROOT_CA_CRL_PATH="$ROOT_CA_PATH/crl"

# Files
ROOT_CA_PRIVATE_KEY="$ROOT_CA_PRIVATE_PATH/ca.key.pem"
ROOT_CA_CERT="$ROOT_CA_CERTS_PATH/ca.cert.pem"
ROOT_CA_INDEX="$ROOT_CA_PATH/index.txt"
ROOT_CA_SERIAL="$ROOT_CA_PATH/serial"

# Initialize folders and files
mkdir -p "$ROOT_CA_PRIVATE_PATH"
mkdir -p "$ROOT_CA_CERTS_PATH"
mkdir -p "$ROOT_CA_NEWCERTS_PATH"
mkdir -p "$ROOT_CA_CRL_PATH"
chmod 700 "$ROOT_CA_PRIVATE_PATH"
touch "$ROOT_CA_INDEX"
echo 1000 > "$ROOT_CA_SERIAL"

# Create Private Key for the Root CA
openssl genrsa -out "$ROOT_CA_PRIVATE_KEY" 3072
chmod 400 "$ROOT_CA_PRIVATE_KEY"

# Create Certificate for the Root CA
# When a certificate is self-signed with prompt=no,
# the expiration time (-days) must be explicitly passed as openssl argument
# because the default_days option is not honored.
# This is a known issue in OpenSSL.
openssl req -config "$ROOT_CA_CONFIG" \
      -new -x509 \
      -key "$ROOT_CA_PRIVATE_KEY" \
      -out "$ROOT_CA_CERT" \
      -days 3650
chmod 444 "$ROOT_CA_CERT"

# Checks
openssl x509 -noout -text -in "$ROOT_CA_CERT"