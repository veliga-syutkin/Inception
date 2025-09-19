#!/bin/bash
set -e

CERT_DIR="/etc/nginx/certs"

mkdir -p $CERT_DIR

if [ ! -f $CERT_DIR/server.crt ]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/CN=${DOMAIN_NAME}" \
    -keyout $CERT_DIR/server.key \
    -out $CERT_DIR/server.crt
fi