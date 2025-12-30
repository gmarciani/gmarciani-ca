#!/usr/bin/env bash
set -euo pipefail

# Usage: build-intermediate-ca-certificate.sh
# Description: Creates an Intermediate Certificate Authority signed by the Root CA

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main() {
    info "Starting Intermediate CA certificate generation..."
    
    local project=$(get_project_path)
    local root_path="$project/root-ca"
    local ca_path="$project/intermediate-ca"
    
    local root_config="$root_path/openssl.cfg"
    local root_cert="$root_path/certs/ca.cert.pem"
    local config="$ca_path/openssl.cfg"
    local key="$ca_path/private/intermediate.key.pem"
    local csr="$ca_path/csr/intermediate.csr.pem"
    local cert="$ca_path/certs/intermediate.cert.pem"
    local chain="$ca_path/certs/ca-chain.cert.pem"
    
    require_file "$root_cert" "Root CA certificate not found (run build-root-ca-certificate.sh first)"
    require_file "$root_config" "Root CA configuration file not found"
    require_file "$config" "Intermediate CA configuration file not found"
    
    if confirm_overwrite "$cert" "Intermediate CA certificate"; then
        cleanup_ca_files "$ca_path" "Intermediate CA"
    fi
    
    init_ca "$ca_path"
    generate_key "$key" "Intermediate CA private key"
    
    run_openssl "Creating Certificate Signing Request" \
        req -config "$config" -new -key "$key" -out "$csr"
    success "Certificate Signing Request created: $csr"
    
    info "Signing Intermediate CA certificate with Root CA..."
    cd "$root_path"
    if ! openssl ca -config "$root_config" -extensions v3_intermediate_ca \
          -batch -notext -in "$csr" -out "$cert"; then
        fail "Signing Intermediate CA certificate"
    fi
    chmod 444 "$cert"
    success "Intermediate CA certificate created: $cert"
    
    verify_certificate "$cert" "$root_cert" "Intermediate CA certificate"
    
    info "Creating certificate chain file..."
    cat "$cert" "$root_cert" > "$chain"
    chmod 444 "$chain"
    success "Certificate chain created: $chain"
    
    display_cert_info "$cert" "Intermediate CA Certificate"
    success "Intermediate CA setup completed successfully!"
}

main "$@"
