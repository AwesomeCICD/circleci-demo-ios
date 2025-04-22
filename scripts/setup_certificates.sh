#!/bin/bash
set -e

# Check if AWS SSO session is active
if ! aws sts get-caller-identity &>/dev/null; then
  echo "No active AWS session detected. Initiating AWS SSO login..."
  
  # Check if a profile was specified
  if [ -z "$AWS_PROFILE" ]; then
    echo "No AWS_PROFILE specified. Please export AWS_PROFILE or add --profile to your command."
    exit 1
  fi
  
  # Login using SSO
  aws sso login --profile "$AWS_PROFILE"
  
  # Verify login was successful
  if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &>/dev/null; then
    echo "AWS SSO login failed. Please check your configuration and try again."
    exit 1
  fi
fi

# Ensure the S3_BUCKET_NAME is set
if [ -z "$S3_BUCKET_NAME" ]; then
  echo "Error: S3_BUCKET_NAME environment variable is not set"
  exit 1
fi

# Create tarball
echo "Creating certificates tarball..."
tar -czf certificates.tar.gz -C certificates cert.p12

# Upload to S3 (using profile if specified)
echo "Uploading to S3..."
if [ -n "$AWS_PROFILE" ]; then
  aws s3 cp certificates.tar.gz "s3://${S3_BUCKET_NAME}/certificates/" \
    --profile "$AWS_PROFILE" \
    --metadata "createdAt=$(date +"%Y-%m-%d_%H-%M-%S"),creator=$(whoami),environment=production"
else
  aws s3 cp certificates.tar.gz "s3://${S3_BUCKET_NAME}/certificates/" \
    --metadata "createdAt=$(date +"%Y-%m-%d_%H-%M-%S"),creator=$(whoami),environment=production"
fi

# Cleanup
echo "Cleaning up..."
rm certificates.tar.gz

echo "Done! Certificates package uploaded to s3://${S3_BUCKET_NAME}/certificates/"