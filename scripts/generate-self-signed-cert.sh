#!/bin/sh
#
# From https://devopscube.com/create-self-signed-certificates-openssl/
#
set -eu

if [ "$#" -ne 1 ]; then
    echo "Error: No domain name argument provided"
    echo "Usage: Provide a domain name as an argument"
    exit 1
fi

DOMAIN=$1

COUNTRY=${COUNTRY:-AU}
STATE=${STATE:-Victoria}
LOCALITY=${LOCALITY:-Melbourne}
ORG=${ORG:-Organisation}
OU=${OU:-${ORG:-Organisation Unit}}
DAYS=${DAYS:-365}

# Create root CA & Private key
set -x
openssl req -x509 \
    -sha256 -days "$DAYS" \
    -nodes \
    -newkey rsa:2048 \
    -subj "/CN=${DOMAIN}/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORG}" \
    -keyout rootCA.key -out rootCA.crt

# Generate Private key
openssl genrsa -out "${DOMAIN}.key" 2048

# Create csf conf
set +x
cat >csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = ${COUNTRY}
ST = ${STATE}
L = ${LOCALITY}
O = ${ORG}
OU = ${OU}
CN = ${DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${DOMAIN}
EOF

# Create CSR request using private key
set -x
openssl req -new -key "${DOMAIN}.key" -out "${DOMAIN}.csr" -config csr.conf

# Create a external config file for the certificate
set +x
cat >cert.conf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
EOF

# Create cert with self signed CA
set -x
openssl x509 -req \
    -in "${DOMAIN}.csr" \
    -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out "${DOMAIN}.crt" \
    -days "$DAYS" \
    -sha256 -extfile cert.conf

# Delete temp files.
rm csr.conf cert.conf
rm rootCA.srl "${DOMAIN}.csr"

set +x
echo 'Done.'
