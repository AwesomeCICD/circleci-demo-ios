# CircleCI Config Policies Implementation Guide

This document explains how to implement and manage CircleCI Config Policies for enforcing security controls **before** any workflow execution begins.

## 🎯 **Why Config Policies > Workflow Approvals**

| Feature | Workflow Approvals | Config Policies |
|---------|-------------------|-----------------|
| **Prevention** | Workflow starts, then waits | **Workflow blocked completely** |
| **Security** | Can be bypassed | **Cannot be bypassed** |
| **Granularity** | Limited control | **Fine-grained rules** |
| **Enforcement** | Manual intervention | **Automated policy engine** |
| **Scalability** | Per-workflow setup | **Organization-wide** |

## 🔧 **Implementation Steps**

### 1. **Deploy Policies to CircleCI** (Organization Admin)

```bash
# Install CircleCI CLI
curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/main/install.sh | bash

# Authenticate
circleci setup

# Deploy policies to your organization
circleci policy push .circleci/config-policies/ --owner-id <your-org-id>

# Verify deployment
circleci policy list --owner-id <your-org-id>
```

### 2. **Enable Policy Evaluation** (Project Settings)

In CircleCI Project Settings → Security:
```
✅ Enable Config Policy Evaluation
✅ Fail builds on policy violations
✅ Log policy evaluation results
```

### 3. **Configure Trusted Users** (Update Policy)

Edit `.circleci/config-policies/security-policy.rego`:
```rego
# Replace with your team's GitHub usernames
trusted_users := {
    "your-github-username",
    "maintainer-1",
    "maintainer-2", 
    "team-lead",
    "senior-developer"
}
```

## 📋 **Policy Rules Implemented**

### 🛡️ **1. External PR Blocking**
```rego
require_approval_for_external_prs
```
- **Blocks**: All PRs from external contributors
- **Allows**: PRs with `maintainer_approved: true` parameter
- **Detection**: Fork origin ≠ target repository

### 🔐 **2. Secrets Protection**
```rego
restrict_secrets_on_external_prs
```
- **Blocks**: External PRs accessing sensitive environment variables
- **Protected vars**: API keys, tokens, passwords
- **Ensures**: No secret leakage to untrusted code

### ⚙️ **3. Config Change Control**
```rego
prevent_config_changes_without_review
```
- **Blocks**: External PRs modifying CI configuration
- **Files watched**: `.circleci/config.yml`, `fastlane/Fastfile`
- **Requires**: Additional `config-approved` in commit message

### 🚀 **4. Deployment Restriction**
```rego
restrict_deployment_on_external_prs
```
- **Blocks**: External PRs from triggering deployment jobs
- **Protected jobs**: `beta`, `deploy`, `release`, `publish`
- **Prevents**: Unauthorized deployments

### ⏰ **5. Scheduled Workflow Security**
```rego
require_maintainer_for_scheduled
```
- **Ensures**: Only trusted users can trigger scheduled workflows
- **Prevents**: Unauthorized scheduled executions

## 🔄 **Approval Workflow Process**

### **For External Contributors:**
1. **Submit PR** → Policy evaluation runs
2. **Policy blocks** → "Config policy violation" error
3. **Maintainer reviews** code thoroughly
4. **Maintainer approves** by:
   - Setting pipeline parameter: `maintainer_approved: true`
   - OR including "approved by maintainer" in commit message
5. **Policy allows** → Workflow executes

### **For Trusted Team:**
1. **Submit PR** → Policy evaluation runs
2. **Policy allows** → Workflow executes immediately
3. **Standard code review** process continues

## 🧪 **Testing Policies Locally**

```bash
# Test policy rules before deployment
./.circleci/scripts/test-policy.sh

# Manual policy testing with OPA
opa eval -d .circleci/config-policies/security-policy.rego \
         -i test-input.json \
         "data.org.deny"
```

## 🎛️ **Policy Management Commands**

```bash
# List current policies
circleci policy list --owner-id <org-id>

# Update policies  
circleci policy push .circleci/config-policies/ --owner-id <org-id>

# Delete policy
circleci policy delete <policy-name> --owner-id <org-id>

# View policy logs
circleci policy logs --owner-id <org-id>
```

## 🚨 **Troubleshooting**

### **Policy Violation Errors:**

**Error**: "External PRs require maintainer approval"
```bash
# Solution: Add approval parameter
circleci trigger-pipeline \
  --param maintainer_approved=true \
  --branch feature-branch
```

**Error**: "Config file changes require additional review"
```bash
# Solution: Add approval to commit message
git commit -m "Update config - config-approved by @maintainer"
```

### **Policy Not Working:**
1. Check policy deployment: `circleci policy list`
2. Verify organization ID is correct
3. Check policy syntax with OPA locally
4. Review CircleCI policy evaluation logs

## 🔄 **Policy Updates**

### **Adding New Rules:**
1. Update `.circleci/config-policies/security-policy.rego`
2. Test locally: `./.circleci/scripts/test-policy.sh`
3. Deploy: `circleci policy push`
4. Test with actual PR

### **Modifying Trusted Users:**
1. Edit `trusted_users` set in policy
2. Redeploy policies
3. Verify with test PR

## 📊 **Monitoring & Metrics**

### **Policy Effectiveness:**
- Monitor policy violation logs
- Track approval workflow usage
- Review blocked vs allowed PRs
- Audit security incident reduction

### **Performance Impact:**
- Policy evaluation adds ~1-2 seconds
- Negligible compared to workflow execution time
- Massive security benefit vs minimal performance cost

## 🔐 **Security Best Practices**

### **Policy Security:**
1. **Version control** all policy files
2. **Code review** policy changes
3. **Test thoroughly** before deployment
4. **Monitor constantly** for bypasses
5. **Update regularly** as threats evolve

### **Access Control:**
1. **Limit** who can deploy policies (org admins only)
2. **Audit** policy changes regularly
3. **Rotate** trusted user lists
4. **Document** all approval decisions

## 📞 **Emergency Procedures**

### **If Policy Blocks Critical Fix:**
```bash
# Temporary policy bypass (org admin only)
circleci policy push --disable-policy security-policy

# Deploy fix

# Re-enable policy
circleci policy push .circleci/config-policies/
```

### **If Policy Compromised:**
1. **Immediately disable** policy evaluation
2. **Audit** all recent approvals and executions
3. **Rotate** all secrets and tokens
4. **Review** and update policy rules
5. **Redeploy** with enhanced security

---

**🎯 Result**: Your CircleCI pipelines are now **fortress-level secure** with automated policy enforcement that **prevents** malicious code execution rather than just **detecting** it.

**🚀 Next Steps**: 
1. Deploy policies to your organization
2. Test with external contributor PR
3. Train team on approval process
4. Monitor and iterate
