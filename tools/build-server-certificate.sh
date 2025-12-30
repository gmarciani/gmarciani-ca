#!/usr/bin/env bash
set -euo pipefail

# Usage: build-server-certificate.sh SERVER_NAME
# Description: Creates a server certificate signed by the Intermediate CA
# Arguments:
#   SERVER_NAME (required): Name of the server (directory under PROJECT_DIR/server/)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

cleanup_server_files() {
    local server_path="$1" name="$2" csr_path="$3"
    info "Cleaning up existing server certificate files..."
    rm -f "$server_path"/private/"$name".* "$server_path"/certs/"$name".* 2>/dev/null || true
    rm -f "$csr_path/$name".* 2>/dev/null || true
}

cleanup_ca_database() {
    local ca_path="$1" cert="$2"
    [[ -f "$cert" ]] || return 0
    
    info "Cleaning up CA database entries..."
    local subject=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//' || true)
    [[ -z "$subject" ]] && return 0
    
    [[ -f "$ca_path/index.txt" ]] || return 0
    cp "$ca_path/index.txt" "$ca_path/index.txt.backup.$(date +%s)" 2>/dev/null || true
    grep -v "$subject" "$ca_path/index.txt" > "$ca_path/index.txt.tmp" 2>/dev/null || true
    mv "$ca_path/index.txt.tmp" "$ca_path/index.txt" 2>/dev/null || true
}

main() {
    [[ $# -eq 0 || -z "${1:-}" ]] && { error "SERVER_NAME is required"; exit 1; }
    
    local name="$1"
    info "Starting server certificate generation..."
    
    local project=$(get_project_path)
    local server_path="$project/server/$name"
    local ca_path="$project/intermediate-ca"
    local csr_path="$project/root-ca/csr"
    
    local config="$server_path/openssl.cfg"
    local ca_config="$ca_path/openssl.cfg"
    local ca_chain="$ca_path/certs/ca-chain.cert.pem"
    local key="$server_path/private/$name.key.pem"
    local csr="$csr_path/$name.csr.pem"
    local cert="$server_path/certs/$name.cert.pem"
    local p12="$server_path/private/$name.p12"
    
    require_file "$config" "Server configuration file not found"
    require_file "$ca_chain" "CA chain certificate not found (run build-intermediate-ca-certificate.sh first)"
    require_file "$ca_config" "Intermediate CA configuration file not found"
    
    info "Server Name: $name"
    info "Server Path: $server_path"
    
    # Check for existing files and confirm overwrite
    if [[ -f "$cert" || -f "$key" ]]; then
        local ref="$cert"; [[ -f "$cert" ]] || ref="$key"
        if confirm_overwrite "$ref" "Server certificate files"; then
            cleanup_server_files "$server_path" "$name" "$csr_path"
            cleanup_ca_database "$ca_path" "$cert"
        fi
    fi
    
    info "Creating directory structure..."
    mkdir -p "$server_path"/{private,certs} "$csr_path"
    chmod 700 "$server_path/private"
    
    generate_key "$key" "Server private key"
    
    run_openssl "Creating Certificate Signing Request" \
        req -config "$config" -new -key "$key" -out "$csr"
    success "Certificate Signing Request created: $csr"
    
    info "Signing server certificate with Intermediate CA..."
    cd "$ca_path"
    if ! openssl ca -config "$ca_config" -extensions server_cert \
          -batch -notext -in "$csr" -out "$cert"; then
        error "Failed: Signing server certificate"
        exit 1
    fi
    chmod 444 "$cert"
    success "Server certificate created: $cert"
    
    verify_certificate "$cert" "$ca_chain" "Server certificate"
    
    info "Exporting certificate to PKCS#12 format..."
    local password="${name}pass"
    if ! openssl pkcs12 -export -name "$name" -in "$cert" -inkey "$key" \
          -password "pass:$password" -out "$p12"; then
        error "Failed: Exporting to PKCS#12"
        exit 1
    fi
    chmod 400 "$p12"
    success "PKCS#12 certificate exported: $p12"
    info "PKCS#12 password: $password"
    
    display_cert_info "$cert" "Server Certificate"
    success "Server certificate setup completed successfully!"
}

main "$@"
