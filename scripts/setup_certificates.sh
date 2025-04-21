#!/bin/bash
set -e

# This script packages certificates and provisioning profiles for S3
# It should be run locally, not in CI

# Ensure AWS CLI is configured
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
CERTS_DIR="$TEMP_DIR/certificates"
mkdir -p "$CERTS_DIR"

# Copy certificates and provisioning profiles to the temporary directory
echo "Copying certificates and provisioning profiles..."
cp -R ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision "$CERTS_DIR/"
cp -R ~/Library/Keychains/login.keychain-db "$CERTS_DIR/"

# Create the tarball
echo "Creating tarball..."
tar -czf certificates.tar.gz -C "$TEMP_DIR" certificates

# Upload to S3 with metadata
echo "Uploading to S3..."
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
aws s3 cp certificates.tar.gz s3://${S3_BUCKET_NAME}/certificates/ \
  --metadata "createdAt=${TIMESTAMP},creator=$(whoami),environment=local"

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR"
rm certificates.tar.gz

echo "Done! Certificates and provisioning profiles uploaded to S3."