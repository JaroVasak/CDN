# CDN Infrastructure Setup

## Overview
This project automates the setup of a CDN infrastructure using Proxmox, Debian templates, Ansible, and Docker. It includes scripts and playbooks to configure Proxmox, create Debian templates, provision VMs, and deploy monitoring tools like Prometheus and Grafana.

## Prerequisites
- A Debian-based host machine capable of running Proxmox.
- Scripts included in this project will automatically install necessary tools like Ansible and SSH.
- Basic understanding of Bash scripting and Ansible playbooks is helpful but not mandatory.

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
│   │   ├── create_debian_template.yml # Create a Debian template in proxmox
│   │   └── provision_vms.yml    # Provision VMs for Ceph and Docker
│   ├── vars/               # Variables for Ansible playbooks
│   │   ├── ansible_secrets.yml  # Encrypted secrets (use Ansible Vault)
│   │   └── provision_vms.yml    # Variables for VM provisioning
├── docker/                 # Docker configuration for services
│   ├── monitoring/         # Monitoring setup
│   │   ├── prometheus/     # Prometheus configuration
│   │   │   └── prometheus.yml  # Prometheus scrape configuration
│   │   └── docker-compose.yml  # Docker Compose file for monitoring stack
├── scripts/                # Bash scripts for initial setup tasks
│   ├── ansible.sh          # Install and configure Ansible
│   ├── proxmox.sh          # Install and configure Proxmox
├── .gitignore              # Git ignore file for excluding sensitive data
└── README.md               # Project documentation
```

## Usage

### 1. Open the Project Folder
Before running any scripts, navigate to the CDN folder where the scripts and configuration files are located:

```bash
cd /path/to/CDN
```

### 2. Update Configuration Variables
Before running any scripts, make sure to configure the necessary variables.
- Open and update the vars/bash.env file with your environment's details:

```bash
cp vars/bash.env.example vars/bash.env
nano vars/bash.env
```

Example configuration in vars/bash.env:
```bash
PROXMOX_HOST=192.168.1.10
NETWORK_GATEWAY=192.168.1.1
NETWORK_MASK=255.255.255.0
```

- Important: Be sure to customize the network and Proxmox host details to match your setup.

### 3. Setup Proxmox
Once the configuration is complete, run the Proxmox setup script. This will install and configure Proxmox on your Debian host.

```bash
sudo ./scripts/proxmox.sh
```
*Note*: Update network details in `vars/bash.env` (e.g., IP, gateway, subnet) before running.

### 4. Install and Configure Ansible
Run the `ansible.sh` script to install and configure Ansible on the host machine:

```bash
sudo ./scripts/ansible.sh
```
*Note*: Ensure the variables in `vars/bash.env` are configured correctly.

### 5. Create a Debian Template
Use the `create_debian_template.yml` Ansible playbook to create a Debian cloud-init template:

```bash
ansible-playbook ansible/playbooks/create_debian_template.yml -i ansible/inventory.yml --user=ansible --private-key ~/.ssh/ansible-key
```
*Note*: Ensure that `/ansible/vars/provision_vms.yml` has the correct configuration before running this playbook.

### 6. Provision Virtual Machines
Use the `provision_vms.yml` Ansible playbook to set up virtual machines for services like Ceph and Docker:

```bash
ansible-playbook ansible/playbooks/provision_vms.yml -i ansible/inventory.yml --user=ansible --private-key ~/.ssh/ansible-key
```
*Note*: Run this playbook with appropriate permissions, such as `sudo`, if needed.

### 7. Deploy Monitoring Stack
Navigate to the monitoring directory and deploy the monitoring stack using Docker Compose:
 
```bash
cd docker/monitoring
docker-compose up -d
```

This will set up the Prometheus and Grafana monitoring stack, accessible at the following ports:

Prometheus (port 9090)
Grafana (port 3000)
Node Exporter
cAdvisor (port 8080)

*Note*: Default Grafana credentials are set to admin / admin. Update the environment variables in the docker-compose.yml file if needed.

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

