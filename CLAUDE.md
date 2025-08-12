# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a containerized Ansible deployment tool that integrates with 1Password for secure credential management. The project creates a Docker container with Ansible, 1Password CLI, and necessary dependencies to run deployment playbooks with secrets managed through 1Password.

## Architecture

The project consists of four main components:

1. **Dockerfile**: Multi-stage build that compiles the Go entrypoint and creates final container with Alpine Linux, Ansible, 1Password CLI, and community.docker collection
2. **Makefile**: Provides build, run, and deployment commands for the Docker container
3. **main.go**: Go-based container entrypoint that retrieves secrets from 1Password CLI and executes Ansible playbooks
4. **go.mod**: Go module definition

The container expects a `deploy/` directory to be mounted at runtime containing Ansible playbooks and related deployment files.

## Development Commands

### Building and Running
```bash
# Build the Docker image
make build

# Run locally with 1Password secret injection
make run-local

# Build and push to registry
make build-and-push

# Push existing image to registry
make push

# Clean up local Docker image
make clean
```

### Docker Registry Configuration
- Registry: `ghcr.io`
- Repository: `elagala/agala-deploy`
- Current tag: `v1.0.3`

## Required Environment Variables

When running the container, the following environment variables must be set:

- `OP_ANSIBLE_INVENTORY_FILE_ROUTE`: 1Password reference to Ansible inventory file
- `OP_ANSIBLE_PRIVATE_KEY_ROUTE`: 1Password reference to SSH private key
- `ANSIBLE_PLAYBOOK`: Path to the Ansible playbook to execute
- `ANSIBLE_LIMIT`: Ansible limit parameter for targeting specific hosts
- `APP_VERSION`: Application version to deploy
- `REGISTRY_USERNAME`: Container registry username
- `REGISTRY_PASSWORD`: Container registry password
- `REGISTRY_URL`: Container registry URL

## File Structure

The minimal project structure includes:
- `Dockerfile`: Multi-stage container build definition
- `Makefile`: Build and deployment automation
- `main.go`: Go entrypoint application
- `go.mod`: Go module definition
- `.gitignore`: Git ignore rules (excludes `.ansible`, `.env`, `deploy` directories)

## Security Considerations

- All secrets are managed through 1Password and never stored in the repository
- SSH keys and inventory files are retrieved at runtime from 1Password
- The `.env` file (containing 1Password references) is git-ignored
- Host key checking is disabled for Ansible (suitable for containerized deployments)

## 1Password Integration

The `run-local` target uses `op inject` to resolve 1Password secret references from `.env` file before running the container. The Go entrypoint uses `op read` commands to retrieve the actual secrets at runtime.

## Dynamic Variable Support

The Go entrypoint supports dynamic variables through environment variables with the `VAR_` prefix:

- Set environment variables like `VAR_DATABASE_URL=vault/item/field` 
- The entrypoint will fetch the value from 1Password using `op read`
- Pass it to Ansible as `-e database_url=<fetched_value>` (lowercase, without VAR_ prefix)

Example:
```bash
VAR_API_KEY=MyVault/APIKeys/production_key
VAR_DB_PASSWORD=MyVault/Database/prod_password
```

These become Ansible variables: `api_key` and `db_password`.