# CDN Infrastructure Setup

## Overview
This project aims to automate the setup of a CDN infrastructure using Proxmox, Debian templates, and Ansible. It provides scripts and playbooks to install and configure Proxmox, set up Ansible, create a Debian template for virtual machines, and provision VMs with services like Ceph and Docker.

## Prerequisites
- A Debian-based host machine capable of running Proxmox.
- SSH key pair configured for Ansible access.
- Ansible installed on the host machine.
- Basic understanding of Bash scripting and Ansible playbooks.
- Ensure the following packages are installed:
  ```bash
  sudo apt-get install ansible ssh
  ```

## Project Structure
```plaintext
CDN/
├── ansible/                # Ansible configuration and playbooks
│   ├── ansible.cfg        # Configuration file for Ansible
│   ├── files/             # Supporting files (e.g., sudoer_ansible)
│   ├── inventory.yml      # Ansible inventory file
│   ├── playbooks/         # Playbooks for provisioning and configuring services
│   │   ├── configure_ceph.yml  # Configure Ceph cluster
│   │   ├── configure_docker.yml # Configure Docker environment
│   │   ├── proxmox_onboard.yml   # Onboard Proxmox setup
│   │   ├── create_debian_template.yml # Create a Debian template
│   │   └── provision_vms.yml    # Provision VMs for Ceph and Docker
│   ├── vars/               # Variables for Ansible playbooks
│   │   ├── ansible_secrets.yml  # Encrypted secrets (use Ansible Vault)
│   │   └── provision_vms.yml    # Variables for VM provisioning
├── scripts/                # Bash scripts for initial setup tasks
│   ├── ansible.sh          # Install and configure Ansible
│   ├── proxmox.sh          # Install and configure Proxmox
├── .gitignore              # Git ignore file for excluding sensitive data
└── README.md               # Project documentation
```

## Usage

### 1. Setup Proxmox
Run the `proxmox.sh` script to install and configure Proxmox on a Debian host:

```bash
sudo ./scripts/proxmox.sh
```
*Note*: Update network details in `vars/bash.env` (e.g., IP, gateway, subnet) before running.

### 2. Setup Ansible
Run the `ansible.sh` script to install and configure Ansible on the host machine:

```bash
sudo ./scripts/ansible.sh
```
*Note*: Ensure the variables in `vars/bash.env` are configured correctly.

### 3. Create a Debian Template
Use the `create_debian_template.yml` Ansible playbook to create a Debian cloud-init template:

```bash
ansible-playbook ansible/playbooks/create_debian_template.yml -i ansible/inventory.yml --user=ansible --private-key ~/.ssh/ansible-key
```
*Note*: Ensure that `vars/bash.env` has the correct configuration before running this playbook.

### 4. Provision Virtual Machines
Use the `provision_vms.yml` Ansible playbook to set up virtual machines for services like Ceph and Docker:

```bash
ansible-playbook ansible/playbooks/provision_vms.yml -i ansible/inventory.yml --user=ansible --private-key ~/.ssh/ansible-key
```
*Note*: Run this playbook with appropriate permissions, such as `sudo`, if needed.

## Configuration

### Bash Variables
Configuration for the Bash scripts is stored in `vars/bash.env`. An example file `bash.env.example` is provided:

```bash
PROXMOX_HOST=192.168.1.10
NETWORK_GATEWAY=192.168.1.1
NETWORK_MASK=255.255.255.0
```

Copy and update the example file:

```bash
cp vars/bash.env.example vars/bash.env
nano vars/bash.env
```

Load variables in scripts using:

```bash
source vars/bash.env
```

### Ansible Secrets
Sensitive information for Ansible can be stored in `ansible/vars/ansible_secrets.yml`. Use `ansible-vault` to encrypt this file for security:

```bash
ansible-vault encrypt ansible/vars/ansible_secrets.yml
ansible-vault decrypt ansible/vars/ansible_secrets.yml
```

### Provisioning Variables
`ansible/vars/provision_vms.yml` contains variables needed by the `provision_vms.yml` playbook to create and manage VMs.

### File Permissions
Ensure that your scripts are executable:

```bash
chmod +x scripts/proxmox.sh scripts/ansible.sh
```

### Example Configuration Files
- `ansible.cfg` for Ansible settings.
- `inventory.yml` for Ansible inventory.

## Security Best Practices
- Encrypt sensitive files using `ansible-vault`.
- Store SSH keys securely and set permissions with `chmod 600 ~/.ssh/ansible-key`.
- Ensure scripts and playbooks are tested in a non-production environment before full deployment.

## Notes
- Ensure all dependencies (e.g., Bash, SSH, Ansible) are installed before running scripts.
- Review scripts and playbooks to align them with your environment and needs.
- Always test in a non-production environment first.

## License
This project is licensed under the MIT License. See `LICENSE` for more details.

