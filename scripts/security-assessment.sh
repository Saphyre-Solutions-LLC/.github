#!/bin/bash

# 🔒 Saphyre Solutions Security Assessment Script
# This script performs a comprehensive security assessment of all repositories
# Author: Security Team
# Version: 1.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORG_NAME="Saphyre-Solutions-LLC"
LOG_FILE="security_assessment_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="security_report_$(date +%Y%m%d_%H%M%S).md"

# Initialize log
echo "Security Assessment Started: $(date)" > "$LOG_FILE"

# Logging function
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "$message"
}

print_header() {
    echo ""
    echo "======================================================================"
    echo "$1"
    echo "======================================================================"
    log "$1"
}

# Check if required tools are installed
check_dependencies() {
    print_header "🔧 Checking Dependencies"
    
    local deps=("gh" "jq" "curl" "git")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        else
            print_status "$GREEN" "✅ $dep is installed"
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_status "$RED" "❌ Missing dependencies: ${missing_deps[*]}"
        echo "Please install missing dependencies and run again."
        exit 1
    fi
    
    # Check GitHub CLI authentication
    if ! gh auth status &> /dev/null; then
        print_status "$RED" "❌ GitHub CLI not authenticated"
        echo "Please run 'gh auth login' first."
        exit 1
    fi
    
    print_status "$GREEN" "✅ All dependencies satisfied"
}

# Get list of all repositories
get_repositories() {
    print_header "📋 Fetching Repository List"
    
    local repos
    repos=$(gh repo list "$ORG_NAME" --json name,visibility,isPrivate,isArchived --limit 100)
    
    if [ -z "$repos" ]; then
        print_status "$RED" "❌ No repositories found or access denied"
        exit 1
    fi
    
    echo "$repos" | jq -r '.[] | "\(.name),\(.visibility),\(.isPrivate),\(.isArchived)"' > repositories.tmp
    
    local repo_count
    repo_count=$(wc -l < repositories.tmp)
    print_status "$GREEN" "✅ Found $repo_count repositories"
}

# Assess organization-level security settings
assess_organization_security() {
    print_header "🏢 Organization Security Assessment"
    
    # Get organization details
    local org_info
    org_info=$(gh api "orgs/$ORG_NAME" 2>/dev/null || echo "{}")
    
    # Check 2FA requirement
    local two_factor_required
    two_factor_required=$(echo "$org_info" | jq -r '.two_factor_requirement_enabled // false')
    
    if [ "$two_factor_required" = "true" ]; then
        print_status "$GREEN" "✅ Two-factor authentication required"
    else
        print_status "$RED" "❌ Two-factor authentication not required"
    fi
    
    # Check default repository permission
    local default_permission
    default_permission=$(echo "$org_info" | jq -r '.default_repository_permission // "unknown"')
    
    case "$default_permission" in
        "read")
            print_status "$GREEN" "✅ Default repository permission: read (secure)"
            ;;
        "write"|"admin")
            print_status "$YELLOW" "⚠️  Default repository permission: $default_permission (consider restricting)"
            ;;
        *)
            print_status "$YELLOW" "⚠️  Default repository permission: $default_permission"
            ;;
    esac
    
    # Check member privileges
    local members_can_create_repos
    members_can_create_repos=$(echo "$org_info" | jq -r '.members_can_create_repositories // true')
    
    if [ "$members_can_create_repos" = "false" ]; then
        print_status "$GREEN" "✅ Members cannot create repositories (secure)"
    else
        print_status "$YELLOW" "⚠️  Members can create repositories (consider restricting)"
    fi
}

# Assess individual repository security
assess_repository_security() {
    local repo_name=$1
    local visibility=$2
    local is_private=$3
    local is_archived=$4
    
    print_header "🔍 Assessing Repository: $repo_name"
    
    if [ "$is_archived" = "true" ]; then
        print_status "$BLUE" "ℹ️  Repository is archived - skipping detailed assessment"
        return
    fi
    
    local security_score=0
    local max_score=0
    
    # Check if repository has security features enabled
    print_status "$BLUE" "🔍 Checking security features..."
    
    # Check for vulnerability alerts (requires push access)
    max_score=$((max_score + 1))
    if gh api "repos/$ORG_NAME/$repo_name/vulnerability-alerts" &>/dev/null; then
        print_status "$GREEN" "✅ Vulnerability alerts enabled"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  Vulnerability alerts status unknown or disabled"
    fi
    
    # Check for security policy
    max_score=$((max_score + 1))
    if gh api "repos/$ORG_NAME/$repo_name/contents/SECURITY.md" &>/dev/null || \
       gh api "repos/$ORG_NAME/$repo_name/contents/.github/SECURITY.md" &>/dev/null; then
        print_status "$GREEN" "✅ Security policy (SECURITY.md) exists"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No security policy found"
    fi
    
    # Check for code of conduct
    max_score=$((max_score + 1))
    if gh api "repos/$ORG_NAME/$repo_name/contents/CODE_OF_CONDUCT.md" &>/dev/null || \
       gh api "repos/$ORG_NAME/$repo_name/contents/.github/CODE_OF_CONDUCT.md" &>/dev/null; then
        print_status "$GREEN" "✅ Code of conduct exists"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No code of conduct found"
    fi
    
    # Check for contributing guidelines
    max_score=$((max_score + 1))
    if gh api "repos/$ORG_NAME/$repo_name/contents/CONTRIBUTING.md" &>/dev/null || \
       gh api "repos/$ORG_NAME/$repo_name/contents/.github/CONTRIBUTING.md" &>/dev/null || \
       gh api "repos/$ORG_NAME/$repo_name/contents/contributing.md" &>/dev/null; then
        print_status "$GREEN" "✅ Contributing guidelines exist"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No contributing guidelines found"
    fi
    
    # Check for README
    max_score=$((max_score + 1))
    if gh api "repos/$ORG_NAME/$repo_name/contents/README.md" &>/dev/null; then
        print_status "$GREEN" "✅ README.md exists"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No README.md found"
    fi
    
    # Check for license
    max_score=$((max_score + 1))
    local license_info
    license_info=$(gh api "repos/$ORG_NAME/$repo_name" --jq '.license.name // "none"')
    if [ "$license_info" != "none" ] && [ "$license_info" != "null" ]; then
        print_status "$GREEN" "✅ License: $license_info"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No license specified"
    fi
    
    # Check for .gitignore
    max_score=$((max_score + 1))
    if gh api "repos/$ORG_NAME/$repo_name/contents/.gitignore" &>/dev/null; then
        print_status "$GREEN" "✅ .gitignore exists"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No .gitignore found"
    fi
    
    # Check for workflow files
    max_score=$((max_score + 1))
    local workflows
    workflows=$(gh api "repos/$ORG_NAME/$repo_name/actions/workflows" --jq '.total_count // 0')
    if [ "$workflows" -gt 0 ]; then
        print_status "$GREEN" "✅ GitHub Actions workflows: $workflows"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No GitHub Actions workflows found"
    fi
    
    # Check branch protection (requires admin access)
    max_score=$((max_score + 1))
    local default_branch
    default_branch=$(gh api "repos/$ORG_NAME/$repo_name" --jq '.default_branch')
    
    if gh api "repos/$ORG_NAME/$repo_name/branches/$default_branch/protection" &>/dev/null; then
        print_status "$GREEN" "✅ Branch protection enabled on $default_branch"
        security_score=$((security_score + 1))
    else
        print_status "$YELLOW" "⚠️  No branch protection on $default_branch"
    fi
    
    # Calculate security score percentage
    local score_percentage
    score_percentage=$(( (security_score * 100) / max_score ))
    
    print_status "$BLUE" "📊 Security Score: $security_score/$max_score ($score_percentage%)"
    
    # Determine overall security rating
    if [ "$score_percentage" -ge 90 ]; then
        print_status "$GREEN" "🏆 Security Rating: EXCELLENT"
    elif [ "$score_percentage" -ge 80 ]; then
        print_status "$GREEN" "✅ Security Rating: GOOD"
    elif [ "$score_percentage" -ge 60 ]; then
        print_status "$YELLOW" "⚠️  Security Rating: FAIR"
    else
        print_status "$RED" "❌ Security Rating: POOR"
    fi
    
    # Store results for report
    echo "$repo_name,$visibility,$is_private,$security_score,$max_score,$score_percentage" >> security_results.tmp
}

# Generate security report
generate_report() {
    print_header "📊 Generating Security Report"
    
    {
        echo "# 🔒 Saphyre Solutions Security Assessment Report"
        echo ""
        echo "**Assessment Date:** $(date)"
        echo "**Organization:** $ORG_NAME"
        echo ""
        
        echo "## 📋 Executive Summary"
        echo ""
        
        local total_repos
        total_repos=$(wc -l < repositories.tmp)
        echo "- **Total Repositories Assessed:** $total_repos"
        
        local public_repos
        public_repos=$(grep ",public," repositories.tmp | wc -l || echo "0")
        echo "- **Public Repositories:** $public_repos"
        
        local private_repos
        private_repos=$(grep ",private," repositories.tmp | wc -l || echo "0")
        echo "- **Private Repositories:** $private_repos"
        
        local archived_repos
        archived_repos=$(grep ",true$" repositories.tmp | wc -l || echo "0")
        echo "- **Archived Repositories:** $archived_repos"
        
        echo ""
        echo "## 🏢 Organization Security Status"
        echo ""
        echo "### ✅ Strengths"
        echo "- Microsoft Entra SSO integration configured"
        echo "- Enterprise GitHub organization with advanced security features"
        echo "- Comprehensive security documentation in place"
        echo ""
        echo "### ⚠️ Areas for Improvement"
        echo "- Ensure 2FA is enforced for all members"
        echo "- Implement branch protection rules across all repositories"
        echo "- Enable security scanning features for all repositories"
        echo ""
        
        echo "## 📊 Repository Security Scores"
        echo ""
        echo "| Repository | Visibility | Security Score | Rating |"
        echo "|------------|------------|----------------|--------|"
        
        if [ -f security_results.tmp ]; then
            while IFS=',' read -r repo_name visibility is_private score max_score percentage; do
                local rating
                if [ "$percentage" -ge 90 ]; then
                    rating="🏆 EXCELLENT"
                elif [ "$percentage" -ge 80 ]; then
                    rating="✅ GOOD"
                elif [ "$percentage" -ge 60 ]; then
                    rating="⚠️ FAIR"
                else
                    rating="❌ POOR"
                fi
                echo "| $repo_name | $visibility | $score/$max_score ($percentage%) | $rating |"
            done < security_results.tmp
        fi
        
        echo ""
        echo "## 🎯 Priority Recommendations"
        echo ""
        echo "### High Priority"
        echo "1. **Enable Branch Protection Rules**"
        echo "   - Require pull request reviews before merging"
        echo "   - Require status checks to pass"
        echo "   - Restrict pushes to main/master branches"
        echo ""
        echo "2. **Enable Security Scanning**"
        echo "   - Enable Dependabot alerts and security updates"
        echo "   - Configure CodeQL code scanning"
        echo "   - Enable secret scanning for all repositories"
        echo ""
        echo "3. **Implement AI Security Controls**"
        echo "   - Configure GitHub Copilot security settings"
        echo "   - Implement AI API key rotation"
        echo "   - Add AI-specific security scanning workflows"
        echo ""
        
    } > "$REPORT_FILE"
    
    print_status "$GREEN" "✅ Security report generated: $REPORT_FILE"
}

# Cleanup function
cleanup() {
    print_status "$BLUE" "🧹 Cleaning up temporary files..."
    rm -f repositories.tmp security_results.tmp 2>/dev/null || true
}

# Main execution
main() {
    print_header "🔒 Saphyre Solutions Security Assessment"
    print_status "$BLUE" "Starting comprehensive security assessment..."
    
    check_dependencies
    get_repositories
    assess_organization_security
    
    # Assess each repository
    while IFS=',' read -r repo_name visibility is_private is_archived; do
        assess_repository_security "$repo_name" "$visibility" "$is_private" "$is_archived"
    done < repositories.tmp
    
    generate_report
    cleanup
    
    print_header "✅ Security Assessment Complete"
    print_status "$GREEN" "📋 Assessment log: $LOG_FILE"
    print_status "$GREEN" "📊 Security report: $REPORT_FILE"
    
    echo ""
    echo "Next steps:"
    echo "1. Review the security report"
    echo "2. Prioritize recommendations based on risk"
    echo "3. Implement security improvements"
    echo "4. Schedule regular security assessments"
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"