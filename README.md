# GMARCIANI Certificate Authority

A complete Certificate Authority (CA) infrastructure implementation using OpenSSL, designed as both an educational showcase of PKI best practices and a practical tool for local development certificate generation.

![GMARCIANI Certificate Authority](resources/readme-image.png)

## Purpose

This project serves two main purposes:

1. **Educational Showcase**: Demonstrates how to properly set up a Certificate Authority infrastructure following industry best practices and security standards.
2. **Local Development Tool**: Provides an easy way to generate trusted SSL/TLS certificates for local development environments, eliminating browser security warnings and enabling HTTPS testing.

## Overview

This project implements a two-tier Certificate Authority structure following PKI best practices:

- **Root CA**: The trust anchor that signs the intermediate CA certificate.
- **Intermediate CA**: Signs end-entity certificates (servers, clients).
- **Server Certificates**: SSL/TLS certificates for web servers and applications.

The hierarchical approach provides better security by keeping the Root CA offline and using the Intermediate CA for day-to-day certificate signing operations.

## Project Structure

```
├── root-ca/                    # Root Certificate Authority
│   ├── certs/                  # Root CA certificates
│   ├── csr/                    # Certificate signing requests (for all services)
│   ├── newcerts/               # Newly issued certificates
│   └── openssl.cfg             # Root CA OpenSSL configuration
├── intermediate-ca/            # Intermediate Certificate Authority
│   ├── certs/                  # Intermediate CA certificates and chain
│   ├── csr/                    # Certificate signing requests
│   ├── newcerts/               # Newly issued certificates
│   └── openssl.cfg             # Intermediate CA OpenSSL configuration
├── server/                     # Server certificates organized by service
│   ├── example/                # Example service
│   │   ├── openssl.cfg         # Service-specific OpenSSL configuration
│   │   ├── private/            # Service private keys and PKCS#12 files
│   │   └── certs/              # Service certificates
│   └── [service-name]/         # Additional services follow the same pattern
│       ├── openssl.cfg
│       ├── private/
│       └── certs/
```

## Quick Start

### 1. Build the Complete CA Infrastructure

Build certificates for the Root CA and Intermediate CA:

```shell
make build_ca
```

This command:
- Creates the Root CA private key and self-signed certificate (valid for 10 years)
- Creates the Intermediate CA private key and certificate signed by the Root CA
- Generates the certificate chain file for validation

### 2. Generate Server Certificates

Build certificate for the default service (example):

```shell
make build_server
```

Or build a certificate for a specific service:

```shell
make build_server SERVER_NAME=meshub
make build_server SERVER_NAME=api-gateway
```

You can also use the script directly:

```shell
bash tools/build-server-certificate.sh example
bash tools/build-server-certificate.sh meshub
```

**To add a new service:**

1. **Create the service directory**:
   ```shell
   mkdir -p server/my-service
   ```

2. **Copy and customize the configuration**:
   ```shell
   cp server/example/openssl.cfg server/my-service/openssl.cfg
   ```
   Edit `server/my-service/openssl.cfg` with your service-specific details (domain names, organization, etc.)

3. **Generate the certificate**:
   ```shell
   bash tools/build-server-certificate.sh my-service
   ```

This process:
- Creates a server private key for the specified service
- Generates a Certificate Signing Request (CSR)
- Issues the server certificate signed by the Intermediate CA
- Exports the certificate to PKCS#12 format for easy deployment
- Validates the certificate chain
- Stores files in `server/SERVICE_NAME/private/` and `server/SERVICE_NAME/certs/`

### 3. Verify Certificate Chain

Verify the entire certificate chain (all services):

```shell
make verify
```

Or verify certificates for a specific service:

```shell
make verify_server                    # Verifies default service (example)
make verify_server SERVER_NAME=meshub # Verifies meshub service
```

You can also use the script directly:

```shell
bash tools/verify-certificates.sh           # Verify all certificates
bash tools/verify-certificates.sh example   # Verify example service only
bash tools/verify-certificates.sh meshub    # Verify meshub service only
```

This validates:
- Root CA certificate format and integrity
- Intermediate CA certificate against Root CA
- Server certificate(s) against the certificate chain

### 4. Import CA Certificates (macOS)

To make certificates issued by your CA trusted system-wide on macOS:

```shell
make import_ca
```

This command:
- Imports the Root CA certificate into the macOS System Keychain with `trustRoot` setting
- Imports the Intermediate CA certificate with `trustAsRoot` setting
- Requires sudo privileges (you'll be prompted for your password)
- Makes all certificates issued by this CA automatically trusted by:
  - Web browsers (Safari, Chrome, Firefox)
  - System applications
  - Command-line tools (curl, wget, etc.)

You can also use the script directly:

```shell
bash tools/import-ca-certificates.sh
```

**⚠️ Security Note**: This makes your CA certificates trusted system-wide. Only use this for development and testing purposes. Remove the certificates when no longer needed.

### 5. Remove CA Certificates (macOS)

To remove the imported CA certificates from the macOS System Keychain:

```shell
make remove_ca
```

This command:
- Removes the Root CA certificate from the System Keychain
- Removes the Intermediate CA certificate from the System Keychain
- Requires sudo privileges
- Reverts the trust settings applied by `import_ca`

You can also use the script directly:

```shell
bash tools/remove-ca-certificates.sh
```

After removal, certificates issued by this CA will no longer be automatically trusted. You may need to restart applications or clear browser caches for changes to take full effect.

### 6. Clean Up

Remove all generated certificates and temporary files:

```shell
make clean
```

## Advanced Usage

### Service-Based Certificate Management

The project organizes certificates by service, making it easy to manage multiple applications:

```shell
# Generate certificates for different services
bash tools/build-server-certificate.sh api-gateway
bash tools/build-server-certificate.sh web-frontend
bash tools/build-server-certificate.sh database-service

# Verify specific services
bash tools/verify-certificates.sh api-gateway
bash tools/verify-certificates.sh web-frontend
```

### Certificate Configuration

Each service has its own OpenSSL configuration file at `server/SERVICE_NAME/openssl.cfg`. You can customize:

- **Organization details**: Company name, organizational unit, location
- **Subject Alternative Names (SAN)**: Domain names and IP addresses
- **Certificate extensions**: Key usage, extended key usage

Example SAN configuration in `server/example/openssl.cfg`:
```ini
[alternate_names]
DNS.1  = example.com
DNS.2  = www.example.com
DNS.3  = api.example.com
DNS.4  = localhost
IP.1   = 127.0.0.1
IP.2   = 192.168.1.100
```

### Certificate Validity

- **Root CA**: 10 years (3650 days)
- **Intermediate CA**: 10 years (3650 days)
- **Server certificates**: 10 years (3650 days)

### Key Specifications

All certificates use:
- **Key size**: 3072-bit RSA
- **Hash algorithm**: SHA-256
- **Proper file permissions**: Private keys (400), Certificates (444)

### Bulk Operations

```shell
# Generate certificates for multiple services
for service in api web database; do
    bash tools/build-server-certificate.sh $service
done

# Verify all services
for service in api web database; do
    bash tools/verify-certificates.sh $service
done
```

## File Locations

After running the build commands, certificates will be organized as follows:

### CA Infrastructure
- Root CA certificate: `root-ca/certs/ca.cert.pem`
- Root CA private key: `root-ca/private/ca.key.pem`
- Intermediate CA certificate: `intermediate-ca/certs/intermediate.cert.pem`
- Intermediate CA private key: `intermediate-ca/private/intermediate.key.pem`
- Certificate chain: `intermediate-ca/certs/ca-chain.cert.pem`

### Service Certificates
For each service (e.g., `example`, `meshub`):
- Service certificate: `server/SERVICE_NAME/certs/DERIVED_NAME.cert.pem`
- Service private key: `server/SERVICE_NAME/private/DERIVED_NAME.key.pem`
- Service PKCS#12: `server/SERVICE_NAME/private/DERIVED_NAME.p12`
- Service CSR: `root-ca/csr/DERIVED_NAME.csr.pem`

**Note**: `DERIVED_NAME` is automatically generated from the `commonName` in the service's OpenSSL configuration (e.g., `example.com` becomes `example-com`).

### Example File Structure
```
server/
├── example/
│   ├── certs/example-com.cert.pem
│   └── private/
│       ├── example-com.key.pem
│       └── example-com.p12
└── meshub/
    ├── certs/meshub-us.cert.pem
    └── private/
        ├── meshub-us.key.pem
        └── meshub-us.p12
```

## Security Considerations

**⚠️ Important**: This CA setup is designed for educational purposes and local development environments. Do not use this configuration for production systems without implementing additional security measures.

### Development and Educational Use
- This project demonstrates PKI concepts and provides certificates for local development
- Generated certificates are suitable for localhost, development servers, and learning environments
- The configuration prioritizes ease of use and educational value over production-grade security

### Security Features Implemented
- Private keys are stored with restrictive permissions (400)
- Root CA should be kept offline in production environments
- Intermediate CA handles day-to-day certificate signing
- Certificate serial numbers start from 1000
- All certificates use SHA-256 hashing

### Production Considerations
If adapting this for production use, consider:
- Hardware Security Modules (HSMs) for key storage
- Password-protected private keys
- Shorter certificate validity periods
- Proper key escrow and backup procedures
- Certificate Revocation Lists (CRL) and OCSP responders
- Audit logging and monitoring

## Requirements

- OpenSSL (tested with modern versions supporting 3072-bit RSA keys)
- Bash shell
- Make utility

## Script Reference

### Certificate Generation Scripts

- `tools/build-root-ca-certificate.sh` - Creates the Root CA
- `tools/build-intermediate-ca-certificate.sh` - Creates the Intermediate CA
- `tools/build-server-certificate.sh SERVICE_NAME` - Creates certificates for a specific service
- `tools/verify-certificates.sh [SERVICE_NAME]` - Verifies certificate chains

### Certificate Management Scripts (macOS)

- `tools/import-ca-certificates.sh` - Imports CA certificates into macOS System Keychain
- `tools/remove-ca-certificates.sh` - Removes CA certificates from macOS System Keychain

### Common Script Options

All scripts support:
- `-h` or `--help` - Display usage information
- Colored output for better readability
- Comprehensive error handling and validation
- Interactive prompts for overwriting existing certificates

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure you have write permissions in the project directory
2. **OpenSSL command not found**: Install OpenSSL on your system
3. **Service directory not found**: Create the service directory and OpenSSL configuration first
4. **Certificate verification fails**: Check that the certificate chain is properly built
5. **Invalid service name**: Service names can only contain letters, numbers, dots, hyphens, and underscores

### Service Configuration Issues

If you encounter issues with service certificates:

1. **Check the OpenSSL configuration**:
   ```shell
   # Verify the config file exists and has proper format
   openssl req -config server/SERVICE_NAME/openssl.cfg -text -noout
   ```

2. **Verify the commonName is set**:
   ```shell
   grep "^commonName" server/SERVICE_NAME/openssl.cfg
   ```

3. **Check directory structure**:
   ```shell
   ls -la server/SERVICE_NAME/
   # Should contain openssl.cfg
   ```

### Rebuilding Certificates

To rebuild everything from scratch:

```shell
make rebuild
```

To rebuild certificates for a specific service:

```shell
# Clean and rebuild specific service
rm -rf server/SERVICE_NAME/private server/SERVICE_NAME/certs
bash tools/build-server-certificate.sh SERVICE_NAME
```

### Clean Up

Remove all generated certificates and temporary files:

```shell
make clean                              # Clean all certificates
make clean_server SERVER_NAME=example  # Clean specific service certificates
```

**Note**: The `make clean` command removes all generated certificates and keys. Use with caution in production environments.

## Quick Reference

### Common Commands

```shell
# Setup CA infrastructure
make build_ca

# Generate service certificates
make build_server                        # Default service (example)
make build_server SERVER_NAME=meshub     # Specific service
bash tools/build-server-certificate.sh my-service

# Verify certificates
make verify                              # All certificates
make verify_server                       # Default service
make verify_server SERVER_NAME=meshub   # Specific service
bash tools/verify-certificates.sh my-service

# Import/Remove CA certificates (macOS)
make import_ca                           # Import CA certificates to System Keychain
make remove_ca                           # Remove CA certificates from System Keychain
bash tools/import-ca-certificates.sh     # Direct script usage
bash tools/remove-ca-certificates.sh     # Direct script usage

# Clean up
make clean                               # All certificates
make rebuild                             # Clean and rebuild all
```

### Service Management Workflow

1. **Create service directory**: `mkdir -p server/my-service`
2. **Copy configuration**: `cp server/example/openssl.cfg server/my-service/`
3. **Customize configuration**: Edit `server/my-service/openssl.cfg`
4. **Generate certificate**: `bash tools/build-server-certificate.sh my-service`
5. **Verify certificate**: `bash tools/verify-certificates.sh my-service`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.