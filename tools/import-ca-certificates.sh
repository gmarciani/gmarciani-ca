#!/usr/bin/env bash
set -euo pipefail

# Usage: import-ca-certificates.sh
# Description: Imports Root CA and Intermediate CA certificates into macOS Keychain

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

import_cert() {
    local cert="$1" label="$2" trust="$3"
    info "Importing $label certificate..."
    if ! sudo security add-trusted-cert -d -r "$trust" -k /Library/Keychains/System.keychain "$cert"; then
        fail "Failed to import $label certificate"
    fi
    success "$label certificate imported successfully"
}

verify_import() {
    local name="$1" label="$2"
    info "Verifying $label certificate in Keychain..."
    if security find-certificate -c "$name" /Library/Keychains/System.keychain &>/dev/null; then
        success "$label certificate found in System Keychain"
        return 0
    else
        error "$label certificate not found in System Keychain"
        return 1
    fi
}

main() {
    info "Starting CA certificate import process..."
    
    [[ "$(uname)" == "Darwin" ]] || fail "This script is for macOS only"
    command -v security &>/dev/null || fail "macOS 'security' command not found"
    
    local project=$(get_project_path)
    local root_cert="$project/root-ca/certs/ca.cert.pem"
    local int_cert="$project/intermediate-ca/certs/intermediate.cert.pem"
    
    require_file "$root_cert" "Root CA certificate not found (run 'make build_ca' first)"
    require_file "$int_cert" "Intermediate CA certificate not found (run 'make build_ca' first)"
    
    warning "This operation requires sudo privileges"
    info "You may be prompted for your password"
    echo
    
    import_cert "$root_cert" "Root CA" "trustRoot"
    import_cert "$int_cert" "Intermediate CA" "trustAsRoot"
    
    echo
    info "Verifying import..."
    local verify_failed=false
    verify_import "GMARCIANI Root CA" "Root CA" || verify_failed=true
    verify_import "GMARCIANI Intermediate CA" "Intermediate CA" || verify_failed=true
    
    echo
    [[ "$verify_failed" == true ]] && fail "CA certificate import verification failed"
    
    success "CA certificates imported and verified successfully!"
    info "All certificates issued by this CA will now be trusted by macOS"
}

main "$@"
