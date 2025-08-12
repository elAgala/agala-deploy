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
    
    # GitHub credentials for private ansible repo
    GH_USER:
      from_secret: github_username
    GH_TOKEN:
      from_secret: github_token
    
    # Ansible configuration
    ANSIBLE_REPO: https://github.com/elAgala/agala-ansible.git
    ANSIBLE_PLAYBOOK: site.yml
    ANSIBLE_INVENTORY: inventories/production.yml
    ANSIBLE_LIMIT: web
    
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
    APP_VERSION: ${DRONE_COMMIT_SHA}
    
    # Dynamic secrets from 1Password (optional)
    VAR_DATABASE_PASSWORD: MyVault/Database/prod_password
    VAR_API_KEY: MyVault/API/production_key
```

### Docker Run

```bash
docker run --rm \
  -e OP_CONNECT_HOST="https://your-connect-server" \
  -e OP_CONNECT_TOKEN="your-connect-token" \
  -e GH_USER="elAgala" \
  -e GH_TOKEN="ghp_xxxxxxxxxxxx" \
  -e ANSIBLE_REPO="https://github.com/elAgala/agala-ansible.git" \
  -e ANSIBLE_PLAYBOOK="site.yml" \
  -e ANSIBLE_INVENTORY="inventories/production.yml" \
  -e OP_ANSIBLE_PRIVATE_KEY_ROUTE="MyVault/SSH/deploy_key" \
  -e APP_VERSION="v1.2.3" \
  ghcr.io/elagala/agala-deploy:v1.0.3
```

## Environment Variables

### Required
- `OP_CONNECT_HOST` - 1Password Connect server URL
- `OP_CONNECT_TOKEN` - 1Password Connect token
- `GH_USER` - GitHub username
- `GH_TOKEN` - GitHub personal access token
- `ANSIBLE_PLAYBOOK` - Playbook filename (e.g., `site.yml`)
- `ANSIBLE_INVENTORY` - Inventory path (e.g., `inventories/production.yml`)
- `OP_ANSIBLE_PRIVATE_KEY_ROUTE` - 1Password reference to SSH private key

### Optional
- `ANSIBLE_REPO` - Git repository URL (defaults to `https://github.com/elAgala/agala-ansible.git`)
- `ANSIBLE_LIMIT` - Ansible limit parameter
- `APP_VERSION` - Application version to deploy
- `REGISTRY_URL`, `REGISTRY_USERNAME`, `REGISTRY_PASSWORD` - Container registry credentials (all 3 required if any is set)
- `VAR_*` - Dynamic variables fetched from 1Password (e.g., `VAR_API_KEY=MyVault/API/key` becomes `-e api_key=<value>`)

## How it Works

1. Clones your private Ansible repository using GitHub credentials
2. Fetches SSH private key from 1Password
3. Processes any `VAR_*` environment variables by fetching values from 1Password
4. Executes `ansible-playbook` with the specified inventory and playbook from your Git repo

## Repository Structure

Your Ansible repository should contain:
```
├── inventories/
│   ├── production.yml
│   └── development.yml
├── site.yml
├── roles/
└── ...
```
