#!/usr/bin/env bash
set -euo pipefail

# Usage: verify-certificates.sh [SERVICE_NAME]
# Description: Verifies the certificate chain integrity for Root CA, Intermediate CA, and server certificates

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

verify_chain() {
    local cert="$1" ca="$2" label="$3"
    info "Verifying $label..."
    
    [[ -f "$cert" ]] || { error "$label not found: $cert"; return 1; }
    [[ -f "$ca" ]] || { error "CA certificate not found: $ca"; return 1; }
    
    local output
    if output=$(openssl verify -CAfile "$ca" "$cert" 2>&1) && echo "$output" | grep -q "OK$"; then
        success "$label verification passed"
        return 0
    fi
    error "$label verification failed: $output"
    return 1
}

cert_summary() {
    local cert="$1" label="$2"
    [[ -f "$cert" ]] || return
    
    echo "  $label:"
    echo "    Subject: $(openssl x509 -noout -subject -in "$cert" | sed 's/subject=//')"
    echo "    Issuer:  $(openssl x509 -noout -issuer -in "$cert" | sed 's/issuer=//')"
    echo "    Valid:   $(openssl x509 -noout -startdate -in "$cert" | sed 's/notBefore=//') to $(openssl x509 -noout -enddate -in "$cert" | sed 's/notAfter=//')"
    echo "    Serial:  $(openssl x509 -noout -serial -in "$cert" | sed 's/serial=//')"
    echo
}

main() {
    local service="${1:-}"
    local project=$(get_project_path)
    
    local root_cert="$project/root-ca/certs/ca.cert.pem"
    local int_cert="$project/intermediate-ca/certs/intermediate.cert.pem"
    local chain="$project/intermediate-ca/certs/ca-chain.cert.pem"
    
    [[ -n "$service" ]] && info "Verifying certificates for service: $service" \
                        || info "Verifying all certificates..."
    
    # Find server certificates
    local -a server_certs=()
    if [[ -n "$service" ]]; then
        local svc_dir="$project/server/$service"
        [[ -d "$svc_dir" ]] || fail "Service directory not found: $svc_dir"
        while IFS= read -r -d '' f; do server_certs+=("$f"); done < <(find "$svc_dir/certs" -name "*.cert.pem" -print0 2>/dev/null)
        [[ ${#server_certs[@]} -eq 0 ]] && warning "No certificates found for service '$service'"
    else
        while IFS= read -r -d '' f; do server_certs+=("$f"); done < <(find "$project/server" -name "*.cert.pem" -print0 2>/dev/null)
        [[ ${#server_certs[@]} -eq 0 ]] && warning "No server certificates found"
    fi
    
    local failed=false
    
    # Verify Root CA
    info "Verifying Root CA certificate (self-signed)..."
    if [[ -f "$root_cert" ]] && openssl x509 -noout -text -in "$root_cert" > /dev/null 2>&1; then
        success "Root CA certificate format verification passed"
    else
        error "Root CA certificate verification failed"
        failed=true
    fi
    
    # Verify Intermediate CA
    verify_chain "$int_cert" "$root_cert" "Intermediate CA certificate" || failed=true
    
    # Verify server certificates
    for cert in "${server_certs[@]}"; do
        local name=$(basename "$cert" .cert.pem)
        verify_chain "$cert" "$chain" "Server certificate ($name)" || failed=true
    done
    
    # Summary
    echo
    if [[ "$failed" == true ]]; then
        error "Certificate verification completed with errors"
    else
        success "All certificate verifications passed!"
    fi
    
    echo
    info "Certificate Summary:"
    cert_summary "$root_cert" "Root CA"
    cert_summary "$int_cert" "Intermediate CA"
    for cert in "${server_certs[@]}"; do
        cert_summary "$cert" "Server ($(basename "$cert" .cert.pem))"
    done
    
    if [[ "$failed" == true ]]; then
        exit 1
    fi
    
    success "Certificate Authority infrastructure is healthy!"
    info "Trust chain: Root CA → Intermediate CA → Server Certificate(s)"
}

main "$@"
