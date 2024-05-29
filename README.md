# gmarciani-ca
GMARCIANI Certification Authority

## Root CA

```
cd root-ca
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
openssl genrsa -out private/ca.key.pem 2048
chmod 400 private/ca.key.pem
openssl req -config openssl.cfg \
      -key private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem
chmod 444 certs/ca.cert.pem
```

## Intermediate CA
```
cd intermediate-ca
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
openssl genrsa -out private/intermediate.key.pem 2048
chmod 400 private/intermediate.key.pem
```

```
cd root-ca
openssl req -config ../intermediate-ca/openssl.cfg -new -sha256 \
      -key ../intermediate-ca/private/intermediate.key.pem \
      -out ../intermediate-ca/csr/intermediate.csr.pem
```

```
cd root-ca
openssl ca -config openssl.cfg -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in ../intermediate-ca/csr/intermediate.csr.pem \
      -out ../intermediate-ca/certs/intermediate.cert.pem
chmod 444 ../intermediate-ca/certs/intermediate.cert.pem
```

```
openssl x509 -noout -text \
      -in intermediate-ca/certs/intermediate.cert.pem

openssl verify -CAfile root-ca/certs/ca.cert.pem \
      intermediate-ca/certs/intermediate.cert.pem
```

```
cat intermediate-ca/certs/intermediate.cert.pem \
      root-ca/certs/ca.cert.pem > intermediate-ca/certs/ca-chain.cert.pem
chmod 444 intermediate-ca/certs/ca-chain.cert.pem
```

## Server Certificates

```
openssl genrsa -out server/private/yawa.com.key.pem 2048
chmod 400 server/private/yawa.com.key.pem
```

```
openssl req -config server/openssl.cfg \
      -key server/private/yawa.com.key.pem \
      -new -sha256 -out server/csr/yawa.com.csr.pem
```

```
cd intermediate-ca
openssl ca -config openssl.cfg \
      -extensions server_cert -days 375 -notext -md sha256 \
      -in ../server/csr/yawa.com.csr.pem \
      -out ../server/certs/yawa.com.cert.pem
chmod 444 ../server/certs/yawa.com.cert.pem
```

```
cd ..
openssl x509 -noout -text \
      -in server/certs/yawa.com.cert.pem
      
openssl verify -CAfile intermediate-ca/certs/ca-chain.cert.pem \
      server/certs/yawa.com.cert.pem
```

```
openssl pkcs12 -export \
    -name "YAWA" \
    -in server/certs/yawa.com.cert.pem \
    -inkey server/private/yawa.com.key.pem \
    -out server/private/yawa.p12  
```
