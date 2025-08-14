#!/bin/bash

# Setup Secure Testing Environments for Open Source Project
# This script helps configure CircleCI contexts and environments for secure testing

set -e

echo "🔧 Setting up Secure Testing Environments for CircleCI"
echo "====================================================="

# Check if CircleCI CLI is installed
if ! command -v circleci &> /dev/null; then
    echo "❌ CircleCI CLI is not installed."
    echo "📦 Install it with: curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/main/install.sh | bash"
    exit 1
fi

echo "✅ CircleCI CLI found: $(circleci version)"

# Get organization ID
echo ""
read -p "🏢 Enter your CircleCI Organization ID: " ORG_ID

if [ -z "$ORG_ID" ]; then
    echo "❌ Organization ID is required"
    exit 1
fi

echo ""
echo "🔒 Creating Secure Testing Contexts..."

# Create test environment context (safe for external contributors)
echo "📝 Creating test-environment-secrets context..."
circleci context create test-environment-secrets --org-id "$ORG_ID" || echo "Context may already exist"

# Add safe test environment variables
circleci context store-secret test-environment-secrets --org-id "$ORG_ID" \
    API_BASE_URL "https://test-api.circleci-demo.com"

circleci context store-secret test-environment-secrets --org-id "$ORG_ID" \
    DATABASE_URL "postgresql://test-db.circleci-demo.com/testdb"

circleci context store-secret test-environment-secrets --org-id "$ORG_ID" \
    AUTH_TOKEN "test-token-safe-for-public-use"

circleci context store-secret test-environment-secrets --org-id "$ORG_ID" \
    USE_MOCKS "true"

echo "✅ test-environment-secrets context created with safe values"

# Create staging environment context (trusted team only)
echo "📝 Creating staging-secrets context..."
circleci context create staging-secrets --org-id "$ORG_ID" || echo "Context may already exist"

echo ""
echo "⚠️  For staging-secrets context, you'll need to add these manually in CircleCI UI:"
echo "   - STAGING_API_KEY (your staging API key)"
echo "   - STAGING_DATABASE_URL (your staging database URL)"
echo "   - STAGING_AUTH_TOKEN (your staging auth token)"

# Create production environment context (approval required)
echo "📝 Creating production-secrets context..."
circleci context create production-secrets --org-id "$ORG_ID" || echo "Context may already exist"

echo ""
echo "⚠️  For production-secrets context, you'll need to add these manually in CircleCI UI:"
echo "   - PROD_API_KEY (your production API key)"
echo "   - PROD_DATABASE_URL (your production database URL)"  
echo "   - PROD_AUTH_TOKEN (your production auth token)"
echo "   - INTERNAL_SERVICE_KEY (your internal service key)"

# Set up context restrictions
echo ""
echo "🔐 Setting up Context Security Groups..."
echo "ℹ️  You'll need to configure these in CircleCI UI at:"
echo "   https://app.circleci.com/settings/organization/$ORG_ID/contexts"
echo ""
echo "📋 Recommended security group setup:"
echo "   test-environment-secrets: ✅ Allow all team members"
echo "   staging-secrets: 🔒 Restrict to trusted developers only" 
echo "   production-secrets: 🔒 Restrict to maintainers/admin only"

# Deploy config policies
echo ""
echo "🛡️  Deploying Config Policies..."
if [ -d ".circleci/config-policies" ]; then
    circleci policy push .circleci/config-policies/ --owner-id "$ORG_ID"
    echo "✅ Config policies deployed successfully"
else
    echo "⚠️  Config policies directory not found. Make sure you're in the project root."
fi

# Test policy deployment
echo ""
echo "🧪 Testing Policy Deployment..."
circleci policy list --owner-id "$ORG_ID"

echo ""
echo "🎯 Setup Complete! Next Steps:"
echo "================================="
echo ""
echo "1. 📝 Update trusted usernames in .circleci/config-policies/security-policy.rego"
echo "2. 🔐 Add secrets to staging-secrets and production-secrets contexts in CircleCI UI"
echo "3. 👥 Configure security groups for contexts"
echo "4. 🧪 Test with an external contributor PR"
echo "5. 📊 Monitor policy enforcement logs"
echo ""
echo "🔗 Useful Links:"
echo "   - Context Management: https://app.circleci.com/settings/organization/$ORG_ID/contexts"
echo "   - Policy Management: https://app.circleci.com/settings/organization/$ORG_ID/security"
echo "   - Security Guide: ./SECURE-TESTING.md"
echo ""
echo "🚀 Your open source project is now secure!"
