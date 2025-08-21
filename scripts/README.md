# 🔒 Security Scripts

This directory contains scripts to validate and manage the organization-wide security configuration for Saphyre Solutions LLC.

## 📋 Available Scripts

### `validate-security-config.sh`

A comprehensive validation script that verifies all security configurations are properly deployed.

**Usage:**
```bash
./scripts/validate-security-config.sh
```

**What it checks:**
- ✅ Security policy documentation
- ✅ Security guidelines
- ✅ Organization security configuration
- ✅ Dependabot configuration
- ✅ Security workflows (4 different workflows)
- ✅ Security issue templates
- ✅ Security-focused PR template
- ✅ YAML syntax validation
- ✅ README security documentation

**Exit codes:**
- `0` - All checks passed
- `1` - One or more checks failed

## 🛡️ Security Features Validated

The validation script ensures that the following security features are properly configured:

### 🔍 **Automated Security Scanning**
- CodeQL analysis for vulnerability detection
- Secret scanning with push protection
- Dependency vulnerability scanning
- Third-party security tools integration

### 📦 **Dependency Security**
- Dependabot configuration for all ecosystems
- Automated security updates
- Vulnerability alerts and reporting
- Security advisory monitoring

### 🔧 **Repository Protection**
- Branch protection rules enforcement
- Required status checks
- Security team review requirements
- Organization-wide security settings

### 📋 **Security Documentation**
- Comprehensive security policy
- Security guidelines and best practices
- Security-focused issue templates
- Security review requirements in PR templates

## 🚀 Quick Validation

To quickly validate your security configuration:

```bash
# Navigate to the repository root
cd /path/to/.github/repository

# Run the validation script
./scripts/validate-security-config.sh

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ Security configuration is valid!"
else
    echo "❌ Security configuration has issues that need to be fixed"
fi
```

## 🔄 Integration with CI/CD

You can integrate this validation script with your CI/CD pipeline:

```yaml
name: Validate Security Configuration
on: [push, pull_request]

jobs:
  validate-security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Validate Security Configuration
      run: ./scripts/validate-security-config.sh
```

## 📞 Support

For questions about security configuration or issues with the validation script:

- **Security Team:** security@SaphyreSolutions.com
- **Emergency Contact:** Tim.Spurlin@SaphyreSolutions.com
- **Documentation:** [Security Guidelines](../SECURITY-GUIDELINES.md)

---

**🛡️ Remember: Security is everyone's responsibility!**