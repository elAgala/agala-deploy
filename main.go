package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

func main() {
	// SOPS_AGE_KEY passes through to Ansible via inherited env
	if os.Getenv("SOPS_AGE_KEY") == "" {
		fmt.Fprintf(os.Stderr, "SOPS_AGE_KEY must be set\n")
		os.Exit(1)
	}

	sshKey := os.Getenv("SSH_DEPLOY_KEY")
	if sshKey == "" {
		fmt.Fprintf(os.Stderr, "SSH_DEPLOY_KEY must be set\n")
		os.Exit(1)
	}

	home := os.Getenv("HOME")

	// Create .ssh directory
	sshDir := filepath.Join(home, ".ssh")
	if err := os.MkdirAll(sshDir, 0700); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create .ssh directory: %v\n", err)
		os.Exit(1)
	}

	// Write SSH deploy key from env var
	privateKeyPath := filepath.Join(sshDir, "id_ed25519")
	if err := os.WriteFile(privateKeyPath, []byte(sshKey+"\n"), 0600); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to write SSH key: %v\n", err)
		os.Exit(1)
	}

	// GitHub credentials
	ghUser := os.Getenv("GH_USER")
	if ghUser == "" {
		fmt.Fprintf(os.Stderr, "GH_USER must be set\n")
		os.Exit(1)
	}

	ghToken := os.Getenv("GH_TOKEN")
	if ghToken == "" {
		fmt.Fprintf(os.Stderr, "GH_TOKEN must be set\n")
		os.Exit(1)
	}

	ansibleRepo := os.Getenv("ANSIBLE_REPO")
	if ansibleRepo == "" {
		ansibleRepo = "https://github.com/elAgala/agala-ansible.git"
	}

	ansiblePlaybook := os.Getenv("ANSIBLE_PLAYBOOK")
	if ansiblePlaybook == "" {
		fmt.Fprintf(os.Stderr, "ANSIBLE_PLAYBOOK must be set (e.g., 'site.yml')\n")
		os.Exit(1)
	}

	ansibleInventory := os.Getenv("ANSIBLE_INVENTORY")
	if ansibleInventory == "" {
		fmt.Fprintf(os.Stderr, "ANSIBLE_INVENTORY must be set (e.g., 'inventories/sisvoto.yml')\n")
		os.Exit(1)
	}

	// Build authenticated Git URL
	authenticatedRepo := strings.Replace(ansibleRepo, "https://", fmt.Sprintf("https://%s:%s@", ghUser, ghToken), 1)

	// Clone ansible repository
	repoPath := filepath.Join(home, "ansible-repo")
	cmd := exec.Command("git", "clone", authenticatedRepo, repoPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to clone ansible repository: %v\n", err)
		os.Exit(1)
	}

	// Playbook comes from mounted volume (project repo), inventory from Git repo
	inventoryPath := filepath.Join(repoPath, ansibleInventory)

	args := []string{
		"ansible-playbook", ansiblePlaybook,
		"--inventory", inventoryPath,
	}

	if limit := os.Getenv("ANSIBLE_LIMIT"); limit != "" {
		args = append(args, "--limit", limit)
	}

	args = append(args, "--diff")
	args = append(args, "-e", fmt.Sprintf("app_version=%s", os.Getenv("APP_VERSION")))
	args = append(args, "-e", fmt.Sprintf("ansible_ssh_private_key_file=%s", privateKeyPath))
	args = append(args, "-e", "ansible_host_key_checking=false")

	// Registry variables - if any are present, all 3 must be present
	registryUsername := os.Getenv("REGISTRY_USERNAME")
	registryPassword := os.Getenv("REGISTRY_PASSWORD")
	registryURL := os.Getenv("REGISTRY_URL")

	if registryUsername != "" || registryPassword != "" || registryURL != "" {
		if registryUsername == "" || registryPassword == "" || registryURL == "" {
			fmt.Fprintf(os.Stderr, "If any registry variable is set, all 3 must be set: REGISTRY_USERNAME, REGISTRY_PASSWORD, REGISTRY_URL\n")
			os.Exit(1)
		}
		args = append(args, "-e", fmt.Sprintf("registry_username=%s", registryUsername))
		args = append(args, "-e", fmt.Sprintf("registry_password=%s", registryPassword))
		args = append(args, "-e", fmt.Sprintf("registry_url=%s", registryURL))
	}

	if err := syscall.Exec("/usr/bin/ansible-playbook", args, os.Environ()); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to execute ansible-playbook: %v\n", err)
		os.Exit(1)
	}
}
