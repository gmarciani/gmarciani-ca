# GMARCIANI Certificate Authority

GMARCIANI Certificate Authority

## Usage

Build certificates for the Root CA and Intermediate CA:

```shell
make build_ca
```

Build certificate for the server:

```shell
make build_server
```

Verify certificates:

```shell
make verify
```

Cleanup everything (certificates and temp files for Root CA, Intermediate CA and server):

```shell
make clean
```
