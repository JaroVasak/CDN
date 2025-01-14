# CDN Infrastructure Setup

## Overview
This project automates the setup of a CDN infrastructure using Proxmox, Debian templates, Ansible, and Docker. It includes scripts and playbooks to configure Proxmox, create Debian templates, provision VMs, and deploy monitoring tools like Prometheus and Grafana.

## Prerequisites
- A Debian-based host machine capable of running Proxmox.
- Scripts included in this project will automatically install necessary tools like Ansible and SSH. Make the scripts executable by running:
```bash
chmod +x scripts/proxmox.sh scripts/ansible.sh
```
- Basic understanding of Bash scripting and Ansible playbooks is helpful but not mandatory.

## Project Structure
```plaintext
CDN/
├── ansible/               # Ansible configurations and playbooks
│   ├── ansible.cfg        # Ansible configuration file
│   ├── files/             # Supporting files (e.g., sudoers configuration for Ansible)
│   ├── inventory.yml      # Ansible inventory file
│   ├── playbooks/         # Playbooks for provisioning and configuring services
│   │   ├── configure_ceph.yml       # Playbook to configure the Ceph cluster
│   │   ├── configure_docker.yml     # Playbook to configure the Docker environment
│   │   ├── proxmox_onboard.yml      # Playbook to onboard Proxmox setup
│   │   ├── create_debian_template.yml # Playbook to create a Debian template in Proxmox
│   │   ├── provision_network.yml    # Playbook to create a Proxmox network for VMs
│   │   └── provision_vms.yml        # Playbook to provision VMs for Ceph and Docker
│   ├── vars/                    # Variables for Ansible playbooks
│   │   ├── ansible_secrets.yml  # Encrypted secrets (use Ansible Vault)
│   │   └── provision_vms.yml    # Variables for VM provisioning
├── docker/                      # Docker configurations for services
│   ├── monitoring/              # Monitoring setup
│   │   ├── grafana/             # Grafana configuration
│   │   │   ├── dashboards/      # Prepared dashboards
│   │   │   │   └── node-exporter-full.json  # Node Exporter Full dashboard JSON
│   │   │   └── provisioning/           # Provisioning resources
│   │   │       ├── dashboards/         # Dashboard provisioning resources
│   │   │       │   └── dashboards.yml  # Dashboard configuration
│   │   │       └── datasources/        # Datasource provisioning resources
│   │   │           └── datasources.yml # Datasource configuration
│   │   ├── prometheus/                 # Prometheus configuration
│   │   │   └── prometheus.yml          # Prometheus scrape configuration
│   │   └── docker-compose.yml          # Docker Compose file for monitoring stack
├── scripts/                # Bash scripts for initial setup tasks
│   ├── ansible.sh          # Script to install and configure Ansible
│   └── proxmox.sh          # Script to install and configure Proxmox
├── .gitignore              # Git ignore file to exclude sensitive data
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
ansible-playbook ansible/playbooks/create_debian_template.yml -i ansible/inventory.yml
```
*Note*: Ensure that `/ansible/vars/provision_vms.yml` has the correct configuration before running this playbook.

### 6. Create Proxmox API User Manually

Before you proceed with provisioning virtual machines, you need to create a user in Proxmox that can manage Proxmox via REST API. Follow these steps to create the user and API token:

## Steps to Create Proxmox User and API Token

1. **Log in to Proxmox Web Interface**:
   - Open your web browser and navigate to your Proxmox server (e.g., `https://<proxmox-ip>:8006`).
   - Log in with your administrative credentials.

2. **Add a New User**:
   - Click on `Datacenter` in the left panel.
   - Go to `Permissions` > `Users`.
   - Click `Add` to create a new user.
   - Fill in the details:
     - **User**: Choose a username (e.g., `ansible@pam`).
     - **Password**: Set a secure password for the user.
   - Click `Add` to create the user.

3. **Assign Permissions to the User**:
   - Navigate to `Permissions` > `Add` > `User Permission`.
   - Set the following:
     - **Path**: `/` (Root directory).
     - **User**: Select the user you just created (e.g., `ansible@pam`).
     - **Role**: Select `Administrator`.
   - Click `Add` to assign the permissions.

4. **Create an API Token**:
   - Go to `API Tokens` under the same `Permissions` menu.
   - Click `Add` to create a new API token.
   - Set the following:
     - **User**: Select the user you just created (e.g., `ansible@pam`).
     - **Token ID**: Set a token identifier (e.g., `ansible-token`).
     - **Privilege Separation**: Uncheck this option.
   - Click `Add` to generate the token.

5. **Store Token Details**:
   - Copy the `Token ID` and `Secret` values.
   - Store these details securely in a secret vault file (e.g., `ansible/vars/ansible_secrets.yml`) that can be called by your Ansible playbooks. You can use `ansible-vault` to encrypt this information for added security. 

```yaml
api_token_id: "ansible-token"
api_token_secret: "<your-token-secret>"
```

### 7. Provision Proxmox Network
Use the `provision_network.yml` Ansible playbook to set up proxmox network used for virtual machines:

```bash
ansible-playbook ansible/playbooks/provision_network.yml -i ansible/inventory.yml
```
*Note*: Run this playbook with appropriate permissions, such as `sudo`, if needed.

### 8. Provision Virtual Machines
Use the `provision_vms.yml` Ansible playbook to set up virtual machines for services like Ceph and Docker:

```bash
ansible-playbook ansible/playbooks/provision_vms.yml -i ansible/inventory.yml
```
*Note*: Run this playbook with appropriate permissions, such as `sudo`, if needed.

### 9. Deploy Monitoring Stack
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

