# Security Guidelines for Open Source Contributors

This project implements several security measures to protect against malicious code execution and unauthorized access to secrets.

## 🔒 CircleCI Security Configuration

### Workflow Approval Process

**For External Contributors (Non-main branches):**
- All PRs from external contributors require manual approval before CircleCI workflows execute
- An approval step (`hold-for-approval`) blocks execution until a maintainer approves
- This prevents malicious code from running with access to secrets or infrastructure

**For Trusted Main Branch:**
- Main branch bypasses approval for faster development
- Only maintainers with push access to main can trigger immediate execution

### Required CircleCI Project Settings

To maximize security, configure these settings in your CircleCI project:

#### 1. **Fork PR Settings** (Project Settings → Advanced)
```
✅ Pass secrets to builds from forked pull requests: DISABLED
✅ Build forked pull requests: ENABLED
✅ Auto-cancel redundant builds: ENABLED
```

#### 2. **Environment Variable Restrictions**
```
✅ Restrict environment variables to main branch only
✅ Use project-level environment variables (not context-level for sensitive data)
```

#### 3. **Required Environment Variables**
Ensure these are set at the **project level** (not in config):
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID` 
- `APP_STORE_CONNECT_API_KEY_CONTENT`
- `APPLE_TEAM_ID`
- `SLACK_WEBHOOK` (optional)
- `AWS_ROLE_ARN` (for S3 uploads)
- `S3_BUCKET_NAME`

## 🛡️ Additional Security Measures

### 1. **Branch Protection Rules** (GitHub Settings)
```yaml
main branch:
  - Require pull request reviews before merging
  - Require status checks to pass before merging
  - Require branches to be up to date before merging
  - Restrict pushes to admins only
  - Include administrators in restrictions
```

### 2. **Repository Security Settings**
```yaml
✅ Enable private vulnerability reporting
✅ Enable Dependabot alerts
✅ Enable Dependabot security updates
✅ Enable dependency graph
```

### 3. **Code Review Requirements**
- **Minimum 2 reviewers** for any PR affecting:
  - `.circleci/config.yml`
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - Any security-related code

### 4. **Secrets Management Best Practices**
- **Never commit secrets** to the repository
- Use CircleCI **project environment variables** for sensitive data
- Rotate API keys regularly
- Use **least privilege principle** for all credentials

## 🚨 Security Incident Response

### If Malicious Code is Detected:
1. **Immediately revoke** all API keys and tokens
2. **Reset environment variables** in CircleCI
3. **Review all recent commits** and PRs
4. **Audit CircleCI build logs** for unauthorized access
5. **Update all secrets** before re-enabling automation

### Regular Security Maintenance:
- **Monthly**: Review and rotate API keys
- **Quarterly**: Audit CircleCI environment variables
- **As needed**: Update dependencies and security patches

## 📋 Approval Workflow for Maintainers

### When a PR Requires Approval:
1. **Review the code changes** thoroughly
2. **Check for any suspicious modifications** to:
   - Build scripts
   - CI configuration
   - Dependency changes
   - Environment variable usage
3. **Verify the contributor** is trustworthy
4. **Approve the CircleCI workflow** by clicking "Approve" in the CircleCI UI
5. **Monitor the build execution** for any unusual behavior

### Red Flags to Watch For:
- Modifications to `.circleci/config.yml` that add new commands
- Changes to `fastlane/Fastfile` that access environment variables
- New dependencies or package additions
- Network requests to unknown endpoints
- File system modifications outside expected paths

## 🔐 For Contributors

### External Contributors:
- Your PRs will require approval before CI runs
- This is a security measure, not a trust issue
- Maintainers will review and approve legitimate contributions promptly
- Consider becoming a trusted contributor by contributing several approved PRs

### Trusted Contributors:
- Direct push access to non-main branches
- PRs to main still require review and approval
- Responsible for following security guidelines

## 📞 Contact

For security concerns or questions, please:
- Open a security advisory on GitHub
- Email the maintainers privately
- Do not discuss security issues in public issues or PRs

---

**Remember**: Security is everyone's responsibility. When in doubt, err on the side of caution.
