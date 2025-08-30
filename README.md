# Agala Deploy

Containerized Ansible deployment tool with 1Password integration and Git-based inventory management.

## Usage Example

### Woodpecker CI Pipeline

```yaml
- name: Deploy to VPS
  image: ghcr.io/elagala/agala-deploy:v1.0.3
  environment:
    # 1Password Connect
    OP_CONNECT_HOST:
      from_secret: op_connect_host
    OP_CONNECT_TOKEN:
      from_secret: op_connect_token
    
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
    
    # SSH key from 1Password
    OP_ANSIBLE_PRIVATE_KEY_ROUTE:
      from_secret: op_ansible_private_key_route
    
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
  -e OP_CONNECT_HOST="https://your-connect-server" \
  -e OP_CONNECT_TOKEN="your-connect-token" \
  -e GH_USER="elAgala" \
  -e GH_TOKEN="ghp_xxxxxxxxxxxx" \
  -e ANSIBLE_REPO="https://github.com/elAgala/agala-ansible.git" \
  -e ANSIBLE_PLAYBOOK="/app/deploy/.ansible/development.yml" \
  -e ANSIBLE_INVENTORY="inventories/sisvoto.yml" \
  -e OP_ANSIBLE_PRIVATE_KEY_ROUTE="MyVault/SSH/deploy_key" \
  -e APP_VERSION="v1.2.3" \
  ghcr.io/elagala/agala-deploy:v1.0.3
```

## Environment Variables

### Required
- `OP_CONNECT_HOST` - 1Password Connect server URL
- `OP_CONNECT_TOKEN` - 1Password Connect token
- `GH_USER` - GitHub username for inventory repo access
- `GH_TOKEN` - GitHub personal access token
- `ANSIBLE_PLAYBOOK` - Path to playbook file from project repo (e.g., `.ansible/development.yml`)
- `ANSIBLE_INVENTORY` - Inventory path from Git repo (e.g., `inventories/sisvoto.yml`)
- `OP_ANSIBLE_PRIVATE_KEY_ROUTE` - 1Password reference to SSH private key

### Optional
- `ANSIBLE_REPO` - Inventory Git repository URL (defaults to `https://github.com/elAgala/agala-ansible.git`)
- `ANSIBLE_LIMIT` - Ansible limit parameter for targeting specific hosts
- `APP_VERSION` - Application version to deploy
- `REGISTRY_URL`, `REGISTRY_USERNAME`, `REGISTRY_PASSWORD` - Container registry credentials (all 3 required if any is set)

## How it Works

1. Clones your private Ansible inventory repository using GitHub credentials
2. Fetches SSH private key from 1Password
3. Executes `ansible-playbook` with:
   - **Playbook**: From your project repository (mounted volume)
   - **Inventory**: From the cloned Git repository

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
└── group_vars/
    └── ...                    # Group variables
```

This approach provides:
- **Clean separation**: Playbooks with your code, inventories managed separately
- **Version control**: Track inventory changes in Git
- **Security**: Secrets managed through 1Password integration in your playbooks
- **Flexibility**: Different inventories for different environments