#!/usr/bin/env bash

# Common functions and utilities for CA certificate generation scripts
# This file should be sourced by other scripts, not executed directly

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Check file exists or exit with error
require_file() {
    local file="$1" msg="${2:-File not found}"
    [[ -f "$file" ]] || { error "$msg: $file"; exit 1; }
}

# Run openssl command with standard error handling
run_openssl() {
    local description="$1"; shift
    info "$description..."
    if ! openssl "$@"; then
        error "Failed: $description"
        exit 1
    fi
}

# Get the project root path
get_project_path() {
    cd -- "$(dirname "${BASH_SOURCE[1]}")/.." >/dev/null 2>&1 && pwd -P
}

# Initialize CA directory structure and database
init_ca() {
    local ca_path="$1"
    local serial_start="${2:-1000}"
    
    info "Creating directory structure..."
    mkdir -p "$ca_path"/{private,certs,newcerts,crl,csr}
    chmod 700 "$ca_path/private"
    
    touch "$ca_path/index.txt"
    echo "$serial_start" > "$ca_path/serial"
    [[ "$ca_path" == *"intermediate"* ]] && echo "$serial_start" > "$ca_path/crlnumber"
}

# Generate RSA private key
generate_key() {
    local key_file="$1" description="${2:-private key}"
    run_openssl "Generating $description (3072-bit RSA)" genrsa -out "$key_file" 3072
    chmod 400 "$key_file"
    success "$description generated: $key_file"
}

# Display certificate information
display_cert_info() {
    local cert="$1" label="${2:-Certificate}"
    info "$label Information:"
    echo "  Subject: $(openssl x509 -noout -subject -in "$cert" | sed 's/subject=//')"
    echo "  Issuer:  $(openssl x509 -noout -issuer -in "$cert" | sed 's/issuer=//')"
    echo "  Valid:   $(openssl x509 -noout -startdate -in "$cert" | sed 's/notBefore=/From: /')"
    echo "           $(openssl x509 -noout -enddate -in "$cert" | sed 's/notAfter=/To:   /')"
    echo "  Serial:  $(openssl x509 -noout -serial -in "$cert" | sed 's/serial=//')"
    local san=$(openssl x509 -noout -ext subjectAltName -in "$cert" 2>/dev/null | grep -v "Subject Alternative Name:" | tr -d ' ' || true)
    [[ -n "$san" ]] && echo "  SAN:     $san"
    return 0
}

# Verify certificate format and optionally chain
verify_certificate() {
    local cert="$1" ca_file="${2:-}" label="${3:-certificate}"
    info "Verifying $label..."
    
    if ! openssl x509 -noout -text -in "$cert" > /dev/null 2>&1; then
        error "$label format verification failed"
        exit 1
    fi
    success "$label format verification passed"
    
    if [[ -n "$ca_file" ]]; then
        if ! openssl verify -CAfile "$ca_file" "$cert" > /dev/null 2>&1; then
            error "$label chain verification failed"
            exit 1
        fi
        success "$label chain verification passed"
    fi
}

# Ask user for confirmation before overwriting
confirm_overwrite() {
    local file="$1" label="${2:-file}"
    [[ -f "$file" ]] || return 1
    
    warning "$label already exists: $file"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] || { info "Skipping $label generation"; exit 0; }
    warning "Overwriting existing $label"
    return 0
}

# Clean up existing CA files
cleanup_ca_files() {
    local ca_path="$1" label="${2:-CA}"
    info "Cleaning up existing $label files..."
    rm -f "$ca_path"/private/*.pem "$ca_path"/certs/*.pem 2>/dev/null || true
    rm -f "$ca_path"/index.txt* "$ca_path"/serial* "$ca_path"/crlnumber* 2>/dev/null || true
}

