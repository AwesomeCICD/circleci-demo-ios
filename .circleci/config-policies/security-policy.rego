# CircleCI Config Policy for Open Source Security
# This policy enforces security controls before any workflow execution

package org

import rego.v1

# Policy: Require approval for external contributors
# Prevents workflows from running on PRs until approved by maintainers
require_approval_for_external_prs contains "External PRs require maintainer approval before execution" if {
    # Check if this is a pull request from an external contributor
    is_external_pr
    
    # Check if approval has not been granted
    not has_maintainer_approval
}

# Helper: Detect external PRs (not from main repo collaborators)
is_external_pr if {
    # PR from a fork or external contributor
    input.pipeline.vcs.origin_repository_url != input.pipeline.vcs.target_repository_url
}

is_external_pr if {
    # PR from non-collaborator (based on CircleCI user context)
    not is_trusted_user
}

# Helper: Check if user is a trusted collaborator
is_trusted_user if {
    # List of trusted GitHub usernames (maintainers)
    trusted_users := {
        "your-github-username",
        "maintainer-1", 
        "maintainer-2"
        # Add your team's GitHub usernames here
    }
    
    input.pipeline.trigger_parameters.circleci.actor in trusted_users
}

# Helper: Check for maintainer approval
has_maintainer_approval if {
    # Look for approval annotation or environment variable
    input.pipeline.parameters.maintainer_approved == true
}

has_maintainer_approval if {
    # Check for specific approval comment or GitHub review
    contains(lower(input.pipeline.vcs.commit.subject), "approved by maintainer")
}

# Policy: Restrict sensitive environment variables on external PRs
restrict_secrets_on_external_prs contains "External PRs cannot access sensitive environment variables" if {
    is_external_pr
    
    # Check if any job uses sensitive environment variables
    some job in input.config.workflows[_].jobs[_]
    sensitive_env_var_used(job)
}

# Helper: Check for sensitive environment variable usage
sensitive_env_var_used(job) if {
    sensitive_vars := {
        "APP_STORE_CONNECT_API_KEY_ID",
        "APP_STORE_CONNECT_API_ISSUER_ID", 
        "APP_STORE_CONNECT_API_KEY_CONTENT",
        "APPLE_TEAM_ID",
        "SLACK_WEBHOOK",
        "AWS_ROLE_ARN",
        "FASTLANE_PASSWORD"
    }
    
    some env_var in job.environment
    env_var in sensitive_vars
}

# Policy: Prevent config changes without review
prevent_config_changes_without_review contains "Config file changes require additional review" if {
    is_external_pr
    
    # Check if .circleci/config.yml was modified
    config_file_modified
    
    # No additional review approval found
    not has_config_review_approval
}

# Helper: Detect config file modifications
config_file_modified if {
    # This would need to be populated by your Git diff or CI system
    ".circleci/config.yml" in input.pipeline.vcs.changed_files
}

config_file_modified if {
    "fastlane/Fastfile" in input.pipeline.vcs.changed_files
}

# Helper: Check for config-specific approval
has_config_review_approval if {
    contains(lower(input.pipeline.vcs.commit.subject), "config-approved")
}

# Policy: Restrict deployment jobs on external PRs
restrict_deployment_on_external_prs contains "External PRs cannot trigger deployment jobs" if {
    is_external_pr
    
    # Check if any deployment job is present
    some workflow in input.config.workflows[_]
    some job_name in workflow.jobs[_]
    is_deployment_job(job_name)
}

# Helper: Identify deployment jobs
is_deployment_job(job_name) if {
    deployment_jobs := {"beta", "deploy", "release", "publish"}
    job_name in deployment_jobs
}

# Policy: Require maintainer for scheduled workflows
require_maintainer_for_scheduled contains "Scheduled workflows require maintainer context" if {
    # Check if this is a scheduled trigger
    input.pipeline.trigger_type == "scheduled"
    
    # Ensure it's from a trusted source
    not is_trusted_user
}

# Meta-policy: Combine all security violations
deny contains msg if {
    some msg in require_approval_for_external_prs
}

deny contains msg if {
    some msg in restrict_secrets_on_external_prs  
}

deny contains msg if {
    some msg in prevent_config_changes_without_review
}

deny contains msg if {
    some msg in restrict_deployment_on_external_prs
}

deny contains msg if {
    some msg in require_maintainer_for_scheduled
}

# Allow policy: Explicitly allow trusted scenarios
allow if {
    # Main branch from trusted users
    input.pipeline.vcs.branch == "main"
    is_trusted_user
}

allow if {
    # PRs with proper approval
    is_external_pr
    has_maintainer_approval
}

allow if {
    # Internal team member PRs (non-main branches)
    input.pipeline.vcs.branch != "main"
    is_trusted_user
}
