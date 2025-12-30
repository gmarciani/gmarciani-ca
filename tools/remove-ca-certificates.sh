#!/usr/bin/env bash
set -euo pipefail

# Usage: remove-ca-certificates.sh
# Description: Removes Root CA and Intermediate CA certificates from macOS Keychain

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

remove_cert() {
    local name="$1" label="$2"
    info "Removing $label certificate..."
    if sudo security delete-certificate -c "$name" /Library/Keychains/System.keychain 2>/dev/null; then
        success "$label certificate removed successfully"
    else
        warning "$label certificate not found (may have been already removed)"
    fi
}

main() {
    info "Starting CA certificate removal process..."
    
    [[ "$(uname)" == "Darwin" ]] || fail "This script is for macOS only"
    command -v security &>/dev/null || fail "macOS 'security' command not found"
    
    warning "This operation requires sudo privileges"
    info "You may be prompted for your password"
    echo
    
    remove_cert "GMARCIANI Root CA" "Root CA"
    remove_cert "GMARCIANI Intermediate CA" "Intermediate CA"
    
    echo
    success "CA certificate removal completed!"
}

main "$@"
