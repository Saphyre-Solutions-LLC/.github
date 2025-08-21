# 🛠️ Security Configuration Guide for Saphyre Solutions LLC

## 🎯 Overview

This guide provides step-by-step instructions for implementing enterprise-grade security across all Saphyre Solutions GitHub repositories while maintaining productivity for AI-assisted development workflows.

## 📋 Table of Contents

1. [Organization-Level Security](#organization-level-security)
2. [Repository Security Configuration](#repository-security-configuration)
3. [Branch Protection Rules](#branch-protection-rules)
4. [Security Scanning Setup](#security-scanning-setup)
5. [AI-Specific Security Controls](#ai-specific-security-controls)
6. [Secret Management](#secret-management)
7. [Access Control Configuration](#access-control-configuration)
8. [Monitoring and Alerting](#monitoring-and-alerting)
9. [Incident Response Setup](#incident-response-setup)
10. [Compliance Configuration](#compliance-configuration)

---

## 🏢 Organization-Level Security

### 1. SAML Single Sign-On (SSO) Configuration

**Current Status:** ✅ Implemented (Microsoft Entra SSO)

**Verification Steps:**
```bash
# Check SSO status via GitHub CLI (requires admin access)
gh api orgs/Saphyre-Solutions-LLC --jq '.has_organization_projects'
```

**Configuration Checklist:**
- [x] Microsoft Entra SSO enabled
- [ ] SCIM provisioning configured
- [ ] Emergency access accounts configured
- [ ] SSO enforcement for all members

### 2. Two-Factor Authentication (2FA) Enforcement

**Organization Settings to Configure:**

1. **Navigate to:** Organization Settings → Authentication Security
2. **Enable:** "Require two-factor authentication"
3. **Configure:** Grace period for new members (recommended: 7 days)
4. **Set:** Recovery options for members

**API Configuration:**
```bash
# Enable 2FA requirement (requires owner permissions)
gh api -X PATCH orgs/Saphyre-Solutions-LLC \
  -f two_factor_requirement_enabled=true
```

### 3. Member Privileges and Permissions

**Base Permissions Configuration:**
- **Default repository permission:** Read
- **Members can create repositories:** False (admin approval required)
- **Members can delete or transfer repositories:** False
- **Members can create pages:** True (for documentation)

**API Configuration:**
```bash
# Set base permissions
gh api -X PATCH orgs/Saphyre-Solutions-LLC \
  -f default_repository_permission=read \
  -f members_can_create_repositories=false \
  -f members_can_create_pages=true
```

### 4. GitHub Apps and OAuth App Restrictions

**Policy Configuration:**
- **OAuth App access restrictions:** Enabled
- **GitHub App installation restrictions:** Enabled
- **Approved apps only:** Whitelist approach

**Required Approved Apps:**
- Microsoft Azure
- Microsoft Teams
- GitHub Copilot for Business
- Security scanning tools (Dependabot, CodeQL)

---

## 🏛️ Repository Security Configuration

### Repository-Level Security Settings

**For each repository, configure:**

#### Security & Analysis Settings

1. **Dependency Graph:** ✅ Enabled
2. **Dependabot Alerts:** ✅ Enabled
3. **Dependabot Security Updates:** ✅ Enabled
4. **Dependabot Version Updates:** ✅ Enabled
5. **Code Scanning:** ✅ Enabled (CodeQL)
6. **Secret Scanning:** ✅ Enabled
7. **Private Vulnerability Reporting:** ✅ Enabled

**API Configuration Script:**
```bash
#!/bin/bash
# Enable security features for all repositories

REPOS=(
  "TelePrompt-Official-App"
  "TelePrompt-Authentication"
  "Automate-Syncing-of-GitHub-Teams-with-Entra-Groups"
  "Network_Ai_Sweeper"
  "TelePrompt-Vision"
  "Claude_Voice_Control"
  "Relik-Recall"
  # Add other repositories as needed
)

for repo in "${REPOS[@]}"; do
  echo "Configuring security for $repo..."
  
  # Enable vulnerability alerts
  gh api -X PUT repos/Saphyre-Solutions-LLC/$repo/vulnerability-alerts
  
  # Enable dependabot alerts
  gh api -X PUT repos/Saphyre-Solutions-LLC/$repo/dependabot/alerts
  
  # Enable secret scanning
  gh api -X PUT repos/Saphyre-Solutions-LLC/$repo/secret-scanning/alerts
  
  echo "✅ Security enabled for $repo"
done
```

#### Repository Visibility Classification

**Public Repositories:**
- `.github` (organization profile)
- `TelePrompt-Official-App`
- `TelePrompt-Authentication`
- `Social-Hub`
- `Contact-Directory-ORG`

**Private/Internal Repositories:**
- `Network_Ai_Sweeper`
- `TelePrompt-Vision`
- `Claude_Voice_Control`
- `Relik-Recall`

---

## 🛡️ Branch Protection Rules

### Main Branch Protection (Production)

**Configuration for `main` branch:**

```yaml
# Branch protection configuration
protection_rules:
  main:
    required_status_checks:
      strict: true
      contexts:
        - "security-scan"
        - "dependency-check"
        - "ai-security-scan"
        - "build"
        - "test"
    enforce_admins: true
    required_pull_request_reviews:
      required_approving_review_count: 2
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
      restrict_push_users: []
    restrictions:
      users: []
      teams: ["security-team", "admin-team"]
    allow_force_pushes: false
    allow_deletions: false
    required_linear_history: true
```

**API Configuration:**
```bash
# Apply branch protection to main branch
gh api -X PUT repos/Saphyre-Solutions-LLC/REPO_NAME/branches/main/protection \
  --input protection-config.json
```

### Development Branch Protection

**Configuration for `develop` branch:**

```yaml
protection_rules:
  develop:
    required_status_checks:
      strict: false
      contexts:
        - "security-scan"
        - "build"
    enforce_admins: false
    required_pull_request_reviews:
      required_approving_review_count: 1
      dismiss_stale_reviews: true
    allow_force_pushes: true
    allow_deletions: false
```

---

## 🔍 Security Scanning Setup

### 1. CodeQL Configuration

**Create `.github/workflows/codeql.yml`:**
```yaml
name: "CodeQL Security Analysis"

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Mondays

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    strategy:
      fail-fast: false
      matrix:
        language: [ 'python', 'javascript', 'csharp' ]

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Initialize CodeQL
      uses: github/codeql-action/init@v3
      with:
        languages: ${{ matrix.language }}
        config-file: ./.github/codeql/codeql-config.yml

    - name: Autobuild
      uses: github/codeql-action/autobuild@v3

    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v3
      with:
        category: "/language:${{matrix.language}}"
```

### 2. Dependabot Configuration

**Create `.github/dependabot.yml`:**
```yaml
version: 2
updates:
  # Python dependencies
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"

  # JavaScript dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    reviewers:
      - "security-team"
    labels:
      - "dependencies"
      - "security"

  # Docker dependencies
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "security-team"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    reviewers:
      - "security-team"
```

### 3. Secret Scanning Configuration

**Custom Secret Patterns (`.github/secret_scanning.yml`):**
```yaml
# Custom patterns for AI service keys
patterns:
  - name: "OpenAI API Key"
    regex: "sk-[a-zA-Z0-9]{32,}"
    
  - name: "Anthropic API Key"
    regex: "sk-ant-[a-zA-Z0-9-]{32,}"
    
  - name: "HuggingFace Token"
    regex: "hf_[a-zA-Z0-9]{34}"
    
  - name: "Azure Cognitive Services Key"
    regex: "[a-f0-9]{32}"
    
  - name: "Custom API Endpoint"
    regex: "https://[a-zA-Z0-9-]+\\.saphyresolutions\\.com/api/[a-zA-Z0-9]+"
```

---

## 🤖 AI-Specific Security Controls

### 1. GitHub Copilot for Business Configuration

**Organization Settings:**
- **Public code suggestions:** Blocked
- **Copilot in CLI:** Enabled with restrictions
- **Content exclusions:** Configured for sensitive repositories

**Policy Configuration:**
```json
{
  "seat_management_setting": "assign_selected",
  "public_code_suggestions": "block",
  "ide_chat": "enabled",
  "platform_chat": "enabled",
  "cli": "enabled"
}
```

### 2. AI Training Data Protection

**Repository-Specific Rules for `Hosted-On-GitHub-for-Ai-Indexing`:**
```yaml
# Special security configuration for AI training data
security_config:
  required_reviews: 3
  required_reviewers:
    - "ai-security-team"
    - "data-protection-team"
    - "legal-team"
  
  file_size_limits:
    max_file_size: "25MB"
    alert_threshold: "10MB"
  
  content_restrictions:
    block_patterns:
      - "social_security_number"
      - "credit_card"
      - "personal_email"
      - "phone_number"
```

### 3. AI Model Security

**Model Repository Security:**
```bash
# Security script for AI model repositories
#!/bin/bash

# Check for model files in repository
find . -name "*.pkl" -o -name "*.pt" -o -name "*.h5" -size +100M | while read file; do
  echo "⚠️ Large model file detected: $file"
  echo "Consider using Git LFS or external storage"
done

# Check for hardcoded AI endpoints
grep -r "https://api\." . --include="*.py" --include="*.js" | grep -E "(openai|anthropic|azure)" && echo "⚠️ Hardcoded AI endpoints found"

# Verify environment variable usage
grep -r "os\.getenv\|process\.env" . --include="*.py" --include="*.js" | grep -i "api" && echo "✅ Environment variables used for API keys"
```

---

## 🔐 Secret Management

### 1. Organization Secrets

**Required Organization Secrets:**
```bash
# Security scanning
FOSSA_API_KEY          # License compliance scanning
SONARCLOUD_TOKEN       # Code quality and security

# AI Services (for authorized repositories only)
OPENAI_API_KEY         # OpenAI API access
ANTHROPIC_API_KEY      # Anthropic Claude access
AZURE_COGNITIVE_KEY    # Azure AI services

# Infrastructure
AZURE_CLIENT_ID        # Azure service principal
AZURE_CLIENT_SECRET    # Azure authentication
AZURE_TENANT_ID        # Azure tenant

# Monitoring
DATADOG_API_KEY        # Application monitoring
SLACK_WEBHOOK_URL      # Security notifications
```

**Secret Management Script:**
```bash
#!/bin/bash
# Set organization secrets (requires admin access)

SECRETS=(
  "FOSSA_API_KEY:$FOSSA_KEY"
  "SONARCLOUD_TOKEN:$SONAR_TOKEN"
  "DATADOG_API_KEY:$DATADOG_KEY"
)

for secret in "${SECRETS[@]}"; do
  IFS=':' read -r name value <<< "$secret"
  gh secret set "$name" --org Saphyre-Solutions-LLC --body "$value"
  echo "✅ Set secret: $name"
done
```

### 2. Repository-Specific Secrets

**High-Security Repositories (Private):**
```bash
# TelePrompt-Authentication secrets
gh secret set DATABASE_URL --repo Saphyre-Solutions-LLC/TelePrompt-Authentication
gh secret set JWT_SECRET --repo Saphyre-Solutions-LLC/TelePrompt-Authentication
gh secret set ENCRYPTION_KEY --repo Saphyre-Solutions-LLC/TelePrompt-Authentication

# AI Model repositories
gh secret set MODEL_ENDPOINT --repo Saphyre-Solutions-LLC/TelePrompt-Vision
gh secret set AI_API_KEY --repo Saphyre-Solutions-LLC/Claude_Voice_Control
```

---

## 📞 Support and Escalation

**For implementation questions:**
- **Technical Issues:** Open issue in `.github` repository
- **Security Concerns:** security@SaphyreSolutions.com
- **Emergency:** Tim.Spurlin@SaphyreSolutions.com

**Resources:**
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [Microsoft Security Documentation](https://docs.microsoft.com/en-us/security/)
- [AI Security Guidelines](https://www.nist.gov/itl/ai-risk-management-framework)

---

*This configuration guide is living documentation and should be updated as security requirements evolve.*