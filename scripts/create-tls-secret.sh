#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-wisecow}
SECRET_NAME=${SECRET_NAME:-wisecow-tls}
HOST=${HOST:-wisecow.local}
CERT_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$CERT_DIR"
}
trap cleanup EXIT

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout "$CERT_DIR/tls.key" \
  -out "$CERT_DIR/tls.crt" \
  -subj "/CN=${HOST}/O=${HOST}" \
  -addext "subjectAltName=DNS:${HOST}"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret tls "$SECRET_NAME" \
  --cert="$CERT_DIR/tls.crt" \
  --key="$CERT_DIR/tls.key" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created/updated TLS secret '$SECRET_NAME' in namespace '$NAMESPACE' for host '$HOST'."
