#!/bin/bash
set -e

# Auto-connect to S3 repository if environment variables are set
# Expected env vars (from ConfigMap aws-s3-storage-config):
#   bucket  - S3 bucket name
#   region  - AWS region
#   s3Url   - S3 endpoint URL (e.g. https://s3.eu-central-1.amazonaws.com)

if [ -n "$bucket" ] && [ -n "$region" ] && [ -n "$s3Url" ]; then
  # Strip https:// prefix from s3Url for kopia --endpoint
  endpoint="${s3Url#https://}"
  endpoint="${endpoint#http://}"

  if kopia repository status &>/dev/null; then
    echo "Kopia repository already connected."
  else
    echo "Connecting to S3 repository: s3://${bucket} (${region})..."
    kopia repository connect s3 \
      --bucket="$bucket" \
      --region="$region" \
      --endpoint="$endpoint" \
      --disable-tls-verification=false
    echo "Kopia repository connected successfully."
  fi
else
  echo "WARNING: S3 environment variables (bucket, region, s3Url) not set. Skipping auto-connect."
fi

# Start Kopia web UI server in the background on port 80
KOPIA_UI_PORT=${KOPIA_UI_PORT:-80}
if kopia repository status &>/dev/null; then
  echo "Starting Kopia server on port ${KOPIA_UI_PORT}..."
  kopia server start \
    --address="0.0.0.0:${KOPIA_UI_PORT}" \
    --insecure \
    --without-password &
  echo "Kopia server started on port ${KOPIA_UI_PORT}."
else
  echo "WARNING: No repository connected. Kopia server not started."
fi

# Execute the provided command (e.g. "sleep infinity")
exec "$@"
