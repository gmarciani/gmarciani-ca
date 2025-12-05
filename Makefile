default: build

ROOT_CA_DIR = "root-ca"
INTERMEDIATE_CA_DIR = "intermediate-ca"
SERVER_DIR ?= server
SERVER_NAME ?= myserver
TOOLS_DIR = "tools"

# Build
rebuild: clean build

build: build_ca build_server

build_ca: build_root_ca build_intermediate_ca

build_root_ca:
	bash ${TOOLS_DIR}/build-root-ca-certificate.sh

build_intermediate_ca:
	bash ${TOOLS_DIR}/build-intermediate-ca-certificate.sh

build_server:
	bash ${TOOLS_DIR}/build-server-certificate.sh ${SERVER_DIR} ${SERVER_NAME}

# Clean
clean: clean_root_ca clean_intermediate_ca clean_server

clean_root_ca:
	rm -rf ${ROOT_CA_DIR}/certs
	rm -rf ${ROOT_CA_DIR}/crl
	rm -rf ${ROOT_CA_DIR}/csr
	rm -rf ${ROOT_CA_DIR}/certs
	rm -rf ${ROOT_CA_DIR}/newcerts
	rm -rf ${ROOT_CA_DIR}/private
	rm -rf ${ROOT_CA_DIR}/index.txt*
	rm -rf ${ROOT_CA_DIR}/serial*

clean_intermediate_ca:
	rm -rf ${INTERMEDIATE_CA_DIR}/certs
	rm -rf ${INTERMEDIATE_CA_DIR}/crl
	rm -rf ${INTERMEDIATE_CA_DIR}/csr
	rm -rf ${INTERMEDIATE_CA_DIR}/certs
	rm -rf ${INTERMEDIATE_CA_DIR}/newcerts
	rm -rf ${INTERMEDIATE_CA_DIR}/private
	rm -rf ${INTERMEDIATE_CA_DIR}/crlnumber*
	rm -rf ${INTERMEDIATE_CA_DIR}/index.txt*
	rm -rf ${INTERMEDIATE_CA_DIR}/serial*

clean_server:
	rm -rf ${SERVER_DIR}/certs
	rm -rf ${SERVER_DIR}/csr
	rm -rf ${SERVER_DIR}/private

verify:
	openssl verify -CAfile "${ROOT_CA_DIR}/certs/ca.cert.pem" "${INTERMEDIATE_CA_DIR}/certs/intermediate.cert.pem"
	openssl verify -CAfile "${INTERMEDIATE_CA_DIR}/certs/ca-chain.cert.pem" "${SERVER_DIR}/certs/yawa.cert.pem"

