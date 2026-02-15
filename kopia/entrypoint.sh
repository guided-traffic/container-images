#!/bin/bash
set -e

# Auto-connect to S3 repository if environment variables are set
# Expected env vars (from ConfigMap aws-s3-storage-config):
#   bucket  - S3 bucket name
#   region  - AWS region
#   s3Url   - S3 endpoint URL (e.g. https://s3.eu-central-1.amazonaws.com)
# AWS credentials file (from Secret current-aws-credentials, key: credentials):
#   Mounted at AWS_CREDENTIALS_FILE (default: /etc/aws/credentials)
#   Format: standard AWS credentials file with [default] profile

AWS_CREDENTIALS_FILE="${AWS_CREDENTIALS_FILE:-/etc/aws/credentials}"

# Parse AWS credentials file if it exists
if [ -f "$AWS_CREDENTIALS_FILE" ]; then
  echo "Parsing AWS credentials from ${AWS_CREDENTIALS_FILE}..."
  AWS_ACCESS_KEY_ID=$(grep -E '^\s*aws_access_key_id\s*=' "$AWS_CREDENTIALS_FILE" | head -1 | sed 's/.*=\s*//' | tr -d ' ')
  AWS_SECRET_ACCESS_KEY=$(grep -E '^\s*aws_secret_access_key\s*=' "$AWS_CREDENTIALS_FILE" | head -1 | sed 's/.*=\s*//' | tr -d ' ')
  AWS_SESSION_TOKEN=$(grep -E '^\s*aws_session_token\s*=' "$AWS_CREDENTIALS_FILE" | head -1 | sed 's/.*=\s*//' | tr -d ' ')
fi

if [ -n "$bucket" ] && [ -n "$region" ] && [ -n "$s3Url" ]; then
  # Strip https:// prefix from s3Url for kopia --endpoint
  endpoint="${s3Url#https://}"
  endpoint="${endpoint#http://}"

  if kopia repository status &>/dev/null; then
    echo "Kopia repository already connected."
  else
    echo "Connecting to S3 repository: s3://${bucket} (${region})..."

    # Build connect command with credentials
    CONNECT_ARGS=(
      --bucket="$bucket"
      --region="$region"
      --endpoint="$endpoint"
    )

    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
      CONNECT_ARGS+=(
        --access-key="$AWS_ACCESS_KEY_ID"
        --secret-access-key="$AWS_SECRET_ACCESS_KEY"
      )
      if [ -n "$AWS_SESSION_TOKEN" ]; then
        CONNECT_ARGS+=(--session-token="$AWS_SESSION_TOKEN")
      fi
    else
      echo "ERROR: AWS credentials not found. Ensure the secret is mounted at ${AWS_CREDENTIALS_FILE}."
      exit 1
    fi

    kopia repository connect s3 "${CONNECT_ARGS[@]}"
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
