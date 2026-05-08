# Agala Deploy

Containerized Ansible deployment tool with SOPS + age secrets and Git-based inventory management.

## Usage Example

### Woodpecker CI Pipeline

```yaml
- name: Deploy to VPS
  image: ghcr.io/elagala/agala-deploy:v3.0.0
  environment:
    # Secrets (SOPS + age)
    SOPS_AGE_KEY:
      from_secret: sops_age_key
    SSH_DEPLOY_KEY:
      from_secret: ssh_deploy_key

    # GitHub credentials for private inventory repo
    GH_USER:
      from_secret: github_username
    GH_TOKEN:
      from_secret: github_token

    # Ansible configuration
    ANSIBLE_REPO: https://github.com/elAgala/agala-ansible.git
    ANSIBLE_PLAYBOOK: .ansible/development.yml        # from project repo
    ANSIBLE_INVENTORY: inventories/sisvoto.yml         # from Git repo
    ANSIBLE_LIMIT: dev

    # Registry credentials (optional - all 3 required if any is set)
    REGISTRY_URL: ghcr.io
    REGISTRY_USERNAME:
      from_secret: github_username
    REGISTRY_PASSWORD:
      from_secret: github_token

    # App deployment
    APP_VERSION: ${CI_COMMIT_SHA}
```

### Docker Run

```bash
docker run --rm \
  -v ./:/app/deploy \
  -e SOPS_AGE_KEY="AGE-SECRET-KEY-1..." \
  -e SSH_DEPLOY_KEY="$(cat ~/.ssh/deploy_key)" \
  -e GH_USER="elAgala" \
  -e GH_TOKEN="ghp_xxxxxxxxxxxx" \
  -e ANSIBLE_REPO="https://github.com/elAgala/agala-ansible.git" \
  -e ANSIBLE_PLAYBOOK="/app/deploy/.ansible/development.yml" \
  -e ANSIBLE_INVENTORY="inventories/sisvoto.yml" \
  -e APP_VERSION="v1.2.3" \
  ghcr.io/elagala/agala-deploy:v3.0.0
```

## Environment Variables

### Required
- `SOPS_AGE_KEY` - age private key for SOPS decryption (passes through to Ansible)
- `SSH_DEPLOY_KEY` - SSH private key content (written to `~/.ssh/id_ed25519`)
- `GH_USER` - GitHub username for inventory repo access
- `GH_TOKEN` - GitHub personal access token
- `ANSIBLE_PLAYBOOK` - Path to playbook file from project repo (e.g., `.ansible/development.yml`)
- `ANSIBLE_INVENTORY` - Inventory path from Git repo (e.g., `inventories/sisvoto.yml`)

### Optional
- `ANSIBLE_REPO` - Inventory Git repository URL (defaults to `https://github.com/elAgala/agala-ansible.git`)
- `ANSIBLE_LIMIT` - Ansible limit parameter for targeting specific hosts
- `APP_VERSION` - Application version to deploy
- `REGISTRY_URL`, `REGISTRY_USERNAME`, `REGISTRY_PASSWORD` - Container registry credentials (all 3 required if any is set)

## How it Works

1. Clones your private Ansible inventory repository using GitHub credentials
2. Writes SSH deploy key from `SSH_DEPLOY_KEY` env var to `~/.ssh/id_ed25519`
3. Executes `ansible-playbook` with:
   - **Playbook**: From your project repository (mounted volume)
   - **Inventory**: From the cloned Git repository
4. `SOPS_AGE_KEY` passes through to Ansible, where the `community.sops.sops` vars plugin auto-decrypts `*.sops.yml` files in `host_vars/`

## Repository Structure

**Your project repository** (mounted as volume):
```
├── .env                        # Application environment
├── .ansible/
│   └── development.yml         # Deployment playbook
└── src/
    └── ...                     # Application code
```

**Your inventory repository** (cloned from Git):
```
├── inventories/
│   ├── production.yml          # Production servers
│   ├── sisvoto.yml            # Development servers
│   └── staging.yml            # Staging servers
├── host_vars/
│   └── */secrets.sops.yml     # SOPS-encrypted secrets per host
└── group_vars/
    └── ...                    # Group variables
```

This approach provides:
- **Clean separation**: Playbooks with your code, inventories managed separately
- **Version control**: Track inventory changes in Git
- **Security**: Secrets encrypted with SOPS + age, decrypted at deploy time
- **Flexibility**: Different inventories for different environments
