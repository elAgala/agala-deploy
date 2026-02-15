# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Containerized Ansible deployment tool. Secrets are managed with SOPS + age (encrypted in git, decrypted at deploy time). The container includes Ansible, sops, age, and the community.sops collection.

## Architecture

1. **Dockerfile**: Multi-stage build — compiles Go entrypoint, installs Ansible + sops + age + collections
2. **Makefile**: Build, run, and push commands for the Docker image
3. **main.go**: Go entrypoint that writes the SSH key, clones the ansible repo, and exec's ansible-playbook
4. **go.mod**: Go module definition

The container expects a `deploy/` directory mounted at runtime containing Ansible playbooks.

## Development Commands

```bash
make build          # Build Docker image
make run-local      # Build and run locally with .env file
make build-and-push # Build and push to registry
make push           # Push existing image
make clean          # Remove local image
```

### Docker Registry
- Registry: `ghcr.io`
- Repository: `elagala/agala-deploy`
- Current tag: `v3.0.0`

## Required Environment Variables

| Variable | Description |
|----------|-------------|
| `SOPS_AGE_KEY` | age private key (passes through to Ansible for SOPS decryption) |
| `SSH_DEPLOY_KEY` | SSH private key content (written to ~/.ssh/id_ed25519) |
| `GH_USER` | GitHub username for cloning ansible repo |
| `GH_TOKEN` | GitHub token for cloning ansible repo |
| `ANSIBLE_PLAYBOOK` | Playbook path (e.g., `deploy/site.yml`) |
| `ANSIBLE_INVENTORY` | Inventory path within ansible repo (e.g., `inventories/sisvoto.yml`) |

### Optional
| Variable | Description |
|----------|-------------|
| `ANSIBLE_REPO` | Git URL for ansible repo (default: `https://github.com/elAgala/agala-ansible.git`) |
| `ANSIBLE_LIMIT` | Limit execution to specific hosts |
| `APP_VERSION` | Application version to deploy |
| `REGISTRY_USERNAME` | Container registry username (all 3 registry vars required if any set) |
| `REGISTRY_PASSWORD` | Container registry password |
| `REGISTRY_URL` | Container registry URL |

## How Secrets Work

1. `SOPS_AGE_KEY` is set in the container environment (from CI secret)
2. The entrypoint clones agala-ansible which contains `*.sops.yml` files in `host_vars/`
3. Ansible's `community.sops.sops` vars plugin auto-decrypts these files using `SOPS_AGE_KEY`
4. Decrypted variables (e.g., `database_password`, `jwt_secret`) are available in playbooks
