# Secure Testing with Internal Resources for Open Source Projects

This guide covers strategies for protecting secrets when external contributors need to test against secure internal resources.

## 🎯 **The Challenge**

External contributors fork your repo and need to:
- Run tests against internal APIs
- Access secured databases or services  
- Use authentication tokens for testing
- Validate against production-like environments

**But you cannot expose secrets to untrusted forks.**

## 🛡️ **Multi-Layer Security Strategies**

### **1. Separate Test Environments** (Recommended)

Create isolated test environments that mirror production but contain no sensitive data:

```yaml
# .circleci/config.yml
parameters:
  use-test-environment:
    type: boolean
    default: true
    description: "Use isolated test environment for external contributors"

jobs:
  test-external:
    when: << pipeline.parameters.use-test-environment >>
    environment:
      API_BASE_URL: "https://test-api.example.com"  # Public test instance
      DATABASE_URL: "postgresql://test-db.example.com/test"  # Isolated test DB
      AUTH_TOKEN: "test-token-safe-for-public-use"
    steps:
      - run: |
          echo "Testing against isolated environment"
          # All tests run against safe, isolated resources
```

**Benefits:**
- ✅ No real secrets exposed
- ✅ External contributors can run full tests
- ✅ Mirrors production functionality
- ✅ Safe for public use

### **2. Environment-Based Secret Isolation**

Use different secret sets based on the execution context:

```yaml
# Policy addition to security-policy.rego
restrict_production_secrets_on_external_prs contains "External PRs cannot access production secrets" if {
    is_external_pr
    
    # Check if any job uses production environment variables
    some job in input.config.workflows[_].jobs[_]
    production_secret_used(job)
}

production_secret_used(job) if {
    production_secrets := {
        "PROD_API_KEY",
        "PROD_DATABASE_URL", 
        "PROD_AUTH_TOKEN",
        "INTERNAL_SERVICE_KEY"
    }
    
    some env_var in job.environment
    env_var in production_secrets
}
```

**CircleCI Context Strategy:**
```yaml
workflows:
  test-internal:
    jobs:
      - test:
          context: 
            - production-secrets  # Only available to trusted team
          filters:
            branches:
              only: main
              
  test-external:
    jobs:
      - test:
          context:
            - test-environment-secrets  # Safe for external use
          filters:
            branches:
              ignore: main
```

### **3. Mock Services for External Testing**

Provide mock implementations of internal services:

```typescript
// tests/mocks/internal-api.ts
export class MockInternalAPI {
  async authenticate(token: string) {
    // Mock authentication always succeeds for test tokens
    if (token.startsWith('test-')) {
      return { success: true, userId: 'test-user' };
    }
    throw new Error('Invalid test token');
  }
  
  async fetchSecureData() {
    // Return realistic but non-sensitive test data
    return {
      data: 'mock-secure-data',
      timestamp: Date.now()
    };
  }
}

// tests/setup.ts
if (process.env.CI && process.env.CIRCLECI_PR_FROM_FORK) {
  // Use mocks for external contributor PRs
  jest.mock('../src/internal-api', () => ({
    InternalAPI: MockInternalAPI
  }));
}
```

### **4. Approval-Gated Production Testing**

Allow production testing only after maintainer approval:

```yaml
# .circleci/config.yml
jobs:
  test-with-production-secrets:
    parameters:
      maintainer-approved:
        type: boolean
        default: false
    when: << parameters.maintainer-approved >>
    steps:
      - run: |
          if [ "$CIRCLECI_PR_FROM_FORK" = "true" ] && [ "<< parameters.maintainer-approved >>" != "true" ]; then
            echo "❌ Production testing requires maintainer approval for external PRs"
            exit 1
          fi
      # Production tests with real secrets only run after approval
```

**Policy Enforcement:**
```rego
# Add to security-policy.rego
require_approval_for_production_testing contains "Production testing requires maintainer approval" if {
    is_external_pr
    uses_production_secrets
    not has_production_testing_approval
}

has_production_testing_approval if {
    input.pipeline.parameters.maintainer_approved == true
    contains(lower(input.pipeline.vcs.commit.subject), "prod-testing-approved")
}
```

### **5. Time-Limited Secret Rotation**

For approved external contributors, use time-limited credentials:

```bash
# .circleci/scripts/generate-temp-credentials.sh
#!/bin/bash

# Generate temporary credentials valid for 1 hour
if [ "$MAINTAINER_APPROVED" = "true" ]; then
    # Create time-limited token
    TEMP_TOKEN=$(aws sts assume-role \
        --role-arn "$TEMP_TESTING_ROLE_ARN" \
        --role-session-name "external-pr-$CIRCLE_BUILD_NUM" \
        --duration-seconds 3600 \
        --query 'Credentials.SessionToken' \
        --output text)
    
    echo "export TEMP_AUTH_TOKEN=$TEMP_TOKEN" >> $BASH_ENV
fi
```

## 🔧 **Implementation Strategy**

### **Phase 1: Safe Defaults**
```yaml
# Default configuration for all PRs
environment:
  - TEST_MODE: "true"
  - API_BASE_URL: "https://test-api.example.com"
  - USE_MOCKS: "true"
  - SAFE_FOR_FORKS: "true"
```

### **Phase 2: Graduated Access**
```yaml
# Trusted contributors get expanded access
trusted-testing:
  when:
    and:
      - not: << pipeline.parameters.use-test-environment >>
      - is_trusted_user
  environment:
    - API_BASE_URL: "https://staging-api.example.com"
    - USE_MOCKS: "false"
```

### **Phase 3: Production-Level Testing**
```yaml
# Full production testing (maintainer approval required)
production-testing:
  when:
    and:
      - << pipeline.parameters.maintainer-approved >>
      - << pipeline.parameters.production-testing >>
  context:
    - production-secrets
```

## 🚨 **Security Best Practices**

### **1. Principle of Least Privilege**
- External contributors get **minimum** access needed
- Test environments have **no production data**
- Secrets are **scoped to specific functionality**

### **2. Monitoring and Auditing**
```bash
# Add to all jobs that use secrets
- run:
    name: Audit Secret Usage
    command: |
      echo "Job: $CIRCLE_JOB"
      echo "User: $CIRCLE_USERNAME" 
      echo "PR: $CIRCLE_PR_NUMBER"
      echo "Repo: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"
      echo "Timestamp: $(date)"
      # Log to security audit system
```

### **3. Network Isolation**
```yaml
# Restrict network access for external PRs
jobs:
  test-external:
    steps:
      - run: |
          # Block access to internal networks
          if [ "$CIRCLECI_PR_FROM_FORK" = "true" ]; then
            export NO_INTERNAL_ACCESS=true
            # Configure firewall rules or use network policies
          fi
```

### **4. Secret Rotation Schedule**
- **Daily**: Rotate test environment secrets
- **Weekly**: Rotate staging secrets
- **Monthly**: Rotate production secrets
- **Immediately**: After any security incident

## 🔄 **Contributor Workflow**

### **For External Contributors:**

1. **Fork Repository**
   ```bash
   git clone https://github.com/contributor/circleci-demo-ios.git
   ```

2. **Run Safe Tests**
   ```bash
   # Tests run against mock/test environment automatically
   # No additional setup required
   ```

3. **Request Production Testing** (if needed)
   ```bash
   git commit -m "Add feature - request prod-testing-approved"
   # Maintainer reviews and approves
   ```

### **For Maintainers:**

1. **Review Code Thoroughly**
   - Check for secret extraction attempts
   - Verify no malicious network calls
   - Ensure proper error handling

2. **Approve Production Testing**
   ```bash
   # Trigger pipeline with production access
   circleci trigger-pipeline \
     --param maintainer_approved=true \
     --param production_testing=true \
     --branch feature-branch
   ```

## 📊 **Risk Assessment Matrix**

| Risk Level | Environment | Secrets Exposed | Approval Required |
|-----------|-------------|-----------------|-------------------|
| **Low** | Test/Mock | None | No |
| **Medium** | Staging | Limited | Yes |
| **High** | Production | Full | Yes + Time-limited |

## 🚀 **Example Implementation**

See the updated `.circleci/config.yml` and policy files for a complete implementation of these strategies.

**Key Files:**
- `secure-testing-workflow.yml` - Multi-environment workflow
- `mock-services/` - Mock implementations
- `scripts/credential-manager.sh` - Temporary credential generation
- Updated policies for environment-based restrictions

---

**🎯 Result**: External contributors can fully test functionality while your production secrets remain completely secure.

**🔒 Security Guarantee**: Even malicious PRs cannot access or exfiltrate production secrets, but legitimate contributors can validate their changes effectively.
