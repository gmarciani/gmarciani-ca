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
        error "Failed to import $label certificate"
        return 1
    fi
    success "$label certificate imported successfully"
}

main() {
    info "Starting CA certificate import process..."
    
    [[ "$(uname)" == "Darwin" ]] || { error "This script is for macOS only"; exit 1; }
    command -v security &>/dev/null || { error "macOS 'security' command not found"; exit 1; }
    
    local project=$(get_project_path)
    local root_cert="$project/root-ca/certs/ca.cert.pem"
    local int_cert="$project/intermediate-ca/certs/intermediate.cert.pem"
    
    require_file "$root_cert" "Root CA certificate not found (run 'make build_ca' first)"
    require_file "$int_cert" "Intermediate CA certificate not found (run 'make build_ca' first)"
    
    warning "This operation requires sudo privileges"
    info "You may be prompted for your password"
    echo
    
    import_cert "$root_cert" "Root CA" "trustRoot" || exit 1
    info "Root CA certificate added with 'trustRoot' setting"
    
    import_cert "$int_cert" "Intermediate CA" "trustAsRoot" || exit 1
    info "Intermediate CA certificate added with 'trustAsRoot' setting"
    
    echo
    success "CA certificates imported successfully!"
    info "All certificates issued by this CA will now be trusted by macOS"
    echo
    warning "Security Note: Remove these certificates when no longer needed (make remove_ca)"
}

main "$@"
