# Justfile for dotfiles automation

# Build GCP image with Packer
packer-build project_id="":
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -z "{{project_id}}" ]; then
        if [ -z "${GCP_PROJECT_ID:-}" ]; then
            echo "Error: GCP project ID not provided"
            echo "Usage: just packer-build <project-id>"
            echo "   or: export GCP_PROJECT_ID=<project-id> && just packer-build"
            exit 1
        fi
        echo "Using GCP_PROJECT_ID from environment: ${GCP_PROJECT_ID}"
        packer build image.pkr.hcl
    else
        echo "Building image for project: {{project_id}}"
        packer build -var="project_id={{project_id}}" image.pkr.hcl
    fi

# Validate Packer configuration
packer-validate:
    packer validate image.pkr.hcl

# Format Packer configuration
packer-fmt:
    packer fmt image.pkr.hcl

# Initialize Packer (install required plugins)
packer-init:
    packer init image.pkr.hcl

# Show Packer configuration details
packer-inspect:
    packer inspect image.pkr.hcl

# List available Just commands
help:
    @just --list
