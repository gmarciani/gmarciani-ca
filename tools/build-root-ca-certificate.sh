#!/usr/bin/env bash
set -euo pipefail

# Usage: build-root-ca-certificate.sh
# Description: Creates a Root Certificate Authority with private key and self-signed certificate

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

main() {
    info "Starting Root CA certificate generation..."
    
    local project=$(get_project_path)
    local ca_path="$project/root-ca"
    local config="$ca_path/openssl.cfg"
    local key="$ca_path/private/ca.key.pem"
    local cert="$ca_path/certs/ca.cert.pem"
    
    require_file "$config" "Root CA configuration file not found"
    
    if confirm_overwrite "$cert" "Root CA certificate"; then
        cleanup_ca_files "$ca_path" "Root CA"
    fi
    
    init_ca "$ca_path"
    generate_key "$key" "Root CA private key"
    
    run_openssl "Creating Root CA certificate (valid for 10 years)" \
        req -config "$config" -new -x509 -key "$key" -out "$cert" -days 3650
    chmod 444 "$cert"
    success "Root CA certificate created: $cert"
    
    verify_certificate "$cert" "" "Root CA certificate"
    display_cert_info "$cert" "Root CA Certificate"
    success "Root CA setup completed successfully!"
}

main "$@"
