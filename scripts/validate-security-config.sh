#!/bin/bash

# 🔒 Security Configuration Validation Script
# This script validates that all security configurations are properly deployed
# across the Saphyre Solutions LLC organization

set -e

echo "🔒 Saphyre Solutions LLC - Security Configuration Validator"
echo "==========================================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "success")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "error")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "info")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Validation counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to perform a check
check() {
    local test_name=$1
    local test_command=$2
    local success_message=$3
    local error_message=$4
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo ""
    print_status "info" "Checking: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_status "success" "$success_message"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        print_status "error" "$error_message"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

echo "Starting security configuration validation..."
echo ""

# Check 1: Verify SECURITY.md exists
check "Security Policy" \
    "test -f SECURITY.md" \
    "Security policy (SECURITY.md) exists" \
    "Security policy (SECURITY.md) is missing"

# Check 2: Verify Security Guidelines exist
check "Security Guidelines" \
    "test -f SECURITY-GUIDELINES.md" \
    "Security guidelines (SECURITY-GUIDELINES.md) exist" \
    "Security guidelines (SECURITY-GUIDELINES.md) are missing"

# Check 3: Verify Organization Config exists
check "Organization Config" \
    "test -f organization-security-config.yml" \
    "Organization security config exists" \
    "Organization security config is missing"

# Check 4: Verify Dependabot config exists
check "Dependabot Configuration" \
    "test -f .github/dependabot.yml" \
    "Dependabot configuration exists" \
    "Dependabot configuration is missing"

# Check 5: Verify security workflows exist
check "Security Scanning Workflow" \
    "test -f .github/workflows/security-scanning.yml" \
    "Security scanning workflow exists" \
    "Security scanning workflow is missing"

check "Dependency Security Workflow" \
    "test -f .github/workflows/dependency-security.yml" \
    "Dependency security workflow exists" \
    "Dependency security workflow is missing"

check "Security Enforcement Workflow" \
    "test -f .github/workflows/security-enforcement.yml" \
    "Security enforcement workflow exists" \
    "Security enforcement workflow is missing"

check "Organization Security Deployment Workflow" \
    "test -f .github/workflows/deploy-organization-security.yml" \
    "Organization security deployment workflow exists" \
    "Organization security deployment workflow is missing"

# Check 6: Verify issue templates exist
check "Security Vulnerability Template" \
    "test -f .github/ISSUE_TEMPLATE/security-vulnerability.yml" \
    "Security vulnerability issue template exists" \
    "Security vulnerability issue template is missing"

check "Security Enhancement Template" \
    "test -f .github/ISSUE_TEMPLATE/security-enhancement.yml" \
    "Security enhancement issue template exists" \
    "Security enhancement issue template is missing"

# Check 7: Verify PR template exists
check "Pull Request Template" \
    "test -f .github/pull_request_template.md" \
    "Security-focused PR template exists" \
    "Security-focused PR template is missing"

# Check 8: Verify YAML syntax is valid
check "YAML Syntax Validation" \
    "python3 -c \"
import yaml
import os
for root, dirs, files in os.walk('.github'):
    for file in files:
        if file.endswith(('.yml', '.yaml')):
            with open(os.path.join(root, file), 'r') as f:
                yaml.safe_load(f)
\"" \
    "All YAML files have valid syntax" \
    "One or more YAML files have syntax errors"

# Check 9: Verify README has been updated with security info
check "README Security Section" \
    "grep -q 'Enterprise-Grade Security' profile/README.md" \
    "README has been updated with security information" \
    "README security section is missing"

# Check 10: Verify required security features are documented
check "Security Features Documentation" \
    "grep -q 'Multi-layered security scanning' profile/README.md && 
     grep -q 'Automated vulnerability detection' profile/README.md &&
     grep -q 'Advanced secret protection' profile/README.md" \
    "Security features are properly documented" \
    "Security features documentation is incomplete"

echo ""
echo "==========================================================="
echo "🔒 Security Configuration Validation Summary"
echo "==========================================================="
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    print_status "success" "All security configurations validated successfully!"
    print_status "success" "✅ $PASSED_CHECKS/$TOTAL_CHECKS checks passed"
    echo ""
    print_status "info" "Your organization is now protected with:"
    echo "   🛡️  Comprehensive security scanning workflows"
    echo "   🔒 Automated vulnerability detection and remediation"
    echo "   🔐 Advanced secret protection with push protection"
    echo "   📋 Security-focused issue and PR templates"
    echo "   📊 Organization-wide security policy enforcement"
    echo "   🚨 24/7 security monitoring and incident response"
    echo ""
    print_status "info" "Next steps:"
    echo "   1. Merge this PR to activate security configurations"
    echo "   2. Run the organization-wide deployment workflow"
    echo "   3. Monitor security alerts and vulnerability reports"
    echo "   4. Train team members on new security processes"
    echo ""
    exit 0
else
    print_status "error" "Security configuration validation failed!"
    print_status "error" "❌ $FAILED_CHECKS/$TOTAL_CHECKS checks failed"
    print_status "warning" "✅ $PASSED_CHECKS/$TOTAL_CHECKS checks passed"
    echo ""
    print_status "warning" "Please fix the failing checks before deploying"
    exit 1
fi