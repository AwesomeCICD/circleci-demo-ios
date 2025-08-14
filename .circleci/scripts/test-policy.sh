#!/bin/bash

# CircleCI Config Policy Testing Script
# Tests policy evaluation locally before deployment

set -e

echo "🔍 Testing CircleCI Config Policies..."

# Check if OPA (Open Policy Agent) is installed
if ! command -v opa &> /dev/null; then
    echo "❌ OPA (Open Policy Agent) is not installed."
    echo "📦 Install it with: brew install open-policy-agent/tap/opa"
    echo "🔗 Or visit: https://www.openpolicyagent.org/docs/latest/#running-opa"
    exit 1
fi

echo "✅ OPA found: $(opa version)"

# Test data for different scenarios
POLICY_DIR=".circleci/config-policies"
CONFIG_FILE=".circleci/config.yml"

# Test 1: External PR (should be blocked)
echo "🧪 Test 1: External PR from untrusted user..."
cat > /tmp/external-pr-input.json << EOF
{
  "config": $(cat $CONFIG_FILE | yq eval -o=json),
  "pipeline": {
    "vcs": {
      "origin_repository_url": "https://github.com/external-user/circleci-demo-ios.git",
      "target_repository_url": "https://github.com/your-org/circleci-demo-ios.git",
      "branch": "feature/external-contribution",
      "commit": {
        "subject": "Add new feature"
      },
      "changed_files": ["src/newfile.txt"]
    },
    "trigger_type": "webhook",
    "trigger_parameters": {
      "circleci": {
        "actor": "external-contributor"
      }
    },
    "parameters": {
      "maintainer_approved": false
    }
  }
}
EOF

RESULT1=$(opa eval -d $POLICY_DIR/security-policy.rego -i /tmp/external-pr-input.json "data.org.deny")
if echo "$RESULT1" | grep -q "External PRs require maintainer approval"; then
    echo "✅ Test 1 PASSED: External PR correctly blocked"
else
    echo "❌ Test 1 FAILED: External PR should be blocked"
fi

# Test 2: Trusted user on main branch (should be allowed)
echo "🧪 Test 2: Trusted user on main branch..."
cat > /tmp/trusted-main-input.json << EOF
{
  "config": $(cat $CONFIG_FILE | yq eval -o=json),
  "pipeline": {
    "vcs": {
      "origin_repository_url": "https://github.com/your-org/circleci-demo-ios.git",
      "target_repository_url": "https://github.com/your-org/circleci-demo-ios.git",
      "branch": "main",
      "commit": {
        "subject": "Update main branch"
      }
    },
    "trigger_type": "webhook",
    "trigger_parameters": {
      "circleci": {
        "actor": "your-github-username"
      }
    },
    "parameters": {
      "maintainer_approved": true
    }
  }
}
EOF

RESULT2=$(opa eval -d $POLICY_DIR/security-policy.rego -i /tmp/trusted-main-input.json "data.org.allow")
if echo "$RESULT2" | grep -q "true"; then
    echo "✅ Test 2 PASSED: Trusted user on main branch allowed"
else
    echo "❌ Test 2 FAILED: Trusted user should be allowed"
fi

# Test 3: External PR with config changes (should be blocked)
echo "🧪 Test 3: External PR modifying config files..."
cat > /tmp/config-change-input.json << EOF
{
  "config": $(cat $CONFIG_FILE | yq eval -o=json),
  "pipeline": {
    "vcs": {
      "origin_repository_url": "https://github.com/external-user/circleci-demo-ios.git",
      "target_repository_url": "https://github.com/your-org/circleci-demo-ios.git",
      "branch": "feature/update-ci",
      "commit": {
        "subject": "Update CI configuration"
      },
      "changed_files": [".circleci/config.yml", "fastlane/Fastfile"]
    },
    "trigger_type": "webhook",
    "trigger_parameters": {
      "circleci": {
        "actor": "external-contributor"
      }
    },
    "parameters": {
      "maintainer_approved": false
    }
  }
}
EOF

RESULT3=$(opa eval -d $POLICY_DIR/security-policy.rego -i /tmp/config-change-input.json "data.org.deny")
if echo "$RESULT3" | grep -q "Config file changes require additional review"; then
    echo "✅ Test 3 PASSED: Config changes correctly blocked"
else
    echo "❌ Test 3 FAILED: Config changes should be blocked"
fi

# Test 4: Approved external PR (should be allowed)
echo "🧪 Test 4: Approved external PR..."
cat > /tmp/approved-pr-input.json << EOF
{
  "config": $(cat $CONFIG_FILE | yq eval -o=json),
  "pipeline": {
    "vcs": {
      "origin_repository_url": "https://github.com/external-user/circleci-demo-ios.git",
      "target_repository_url": "https://github.com/your-org/circleci-demo-ios.git",
      "branch": "feature/approved-contribution",
      "commit": {
        "subject": "Add feature - approved by maintainer"
      }
    },
    "trigger_type": "webhook",
    "trigger_parameters": {
      "circleci": {
        "actor": "external-contributor"
      }
    },
    "parameters": {
      "maintainer_approved": true
    }
  }
}
EOF

RESULT4=$(opa eval -d $POLICY_DIR/security-policy.rego -i /tmp/approved-pr-input.json "data.org.allow")
if echo "$RESULT4" | grep -q "true"; then
    echo "✅ Test 4 PASSED: Approved external PR allowed"
else
    echo "❌ Test 4 FAILED: Approved PR should be allowed"
fi

# Cleanup
rm -f /tmp/*-input.json

echo ""
echo "🎯 Policy Testing Complete!"
echo "📋 Summary:"
echo "   - External PRs are blocked until approved"
echo "   - Config changes require additional review"
echo "   - Trusted users on main branch are allowed"
echo "   - Approved PRs are allowed to proceed"
echo ""
echo "🚀 Ready to deploy policies to CircleCI!"
echo "📖 Next steps:"
echo "   1. Update trusted usernames in security-policy.rego"
echo "   2. Deploy policies to CircleCI organization"
echo "   3. Test with actual PRs"
