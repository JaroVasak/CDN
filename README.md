# Private-Cloud-CDN-LAB

## Overview
The goal of this project is to create a fully automated private cloud infrastructure that mirrors a real-world use case, such as a Content Delivery Network (CDN). The infrastructure leverages Proxmox as the virtualization platform, Ansible as the configuration management tool, and Bash for automating the setup of prerequisites. The operating system used for both Proxmox and the cloud template is Debian.

This lab environment includes the following services:
- Prometheus and Grafana for monitoring and visualizing system metrics.
- Two Nginx instances used as a reverse proxy, caching layer, and web server.
- Ceph as a distributed storage cluster.

> **Note**: This project is still in progress. The following components are not yet fully functional:
> - Provisioning of Nginx instances
> - Ceph cluster setup

## Prerequisites
- A Debian-based host machine capable of running Proxmox.
- Ansible version >= 2.17 is recommended for compatibility with the provided playbooks.
- Make the scripts executable before running:
```bash
chmod +x scripts/proxmox.sh scripts/ansible.sh
```

## Project Structure
```plaintext
CDN/
├── ansible/                         # Ansible configurations and playbooks
│   ├── inventory.yml                # Ansible inventory file
│   ├── playbooks/                   # Playbooks for provisioning and configuring services
│   │   ├── configure_ceph.yml       # Playbook to configure the Ceph cluster
│   │   ├── configure_docker.yml     # Playbook to configure the Docker environment
│   │   ├── create_debian_template.yml # Playbook to create a Debian cloud-init template
│   │   ├── provision_network.yml    # Playbook to create the Proxmox bridge network
│   │   └── provision_vms.yml        # Playbook to provision VMs for Ceph and Docker
│   └── vars/                        # Variables for Ansible playbooks
│       ├── ansible_secrets.yml      # Encrypted secrets (use Ansible Vault)
│       └── provision_vms.yml        # Variables for VM provisioning
├── docker/                          # Docker configurations for services
│   └── monitoring/                  # Monitoring stack
│       ├── grafana/                 # Grafana configuration
│       │   ├── dashboards/          # Pre-built dashboards
│       │   │   └── node-exporter-full.json
│       │   └── provisioning/        # Auto-provisioning config
│       │       ├── dashboards/      # Dashboard provisioning
│       │       │   └── dashboards.yml
│       │       └── datasources/     # Datasource provisioning
│       │           └── datasources.yml
│       ├── prometheus/
│       │   └── prometheus.yml       # Prometheus scrape configuration
│       ├── .env.example             # Template for Grafana credentials
│       └── docker-compose.yml       # Monitoring stack compose file
├── scripts/                         # Bash scripts for initial setup
│   ├── ansible.sh                   # Installs and configures Ansible
│   └── proxmox.sh                   # Installs and configures Proxmox
├── vars/
│   ├── bash.env                     # Local environment variables (gitignored)
│   └── bash.env.example             # Template for bash.env
├── .gitignore
└── README.md
```

> **Note**: `ansible/ansible.cfg` and `ansible/playbooks/proxmox_onboard.yml` are generated at runtime by `ansible.sh` and are not committed to the repository.

## Usage

### 1. Open the Project Folder
```bash
cd /path/to/CDN
```

### 2. Configure Environment Variables
Copy the example file and fill in your environment's values:

```bash
cp vars/bash.env.example vars/bash.env
nano vars/bash.env
```

Key variables to set:

```bash
# Proxmox host IP address
PROXMOX_HOST="192.168.1.50"
GATEWAY="192.168.1.1"
NETMASK="255.255.255.0"

# Network interface name — check yours with: ip link show
NIC_NAME="enp3s0"
```

### 3. Setup Proxmox
Run the Proxmox setup script on the Debian host. This installs Proxmox, configures the static IP, and runs post-install steps.

```bash
sudo ./scripts/proxmox.sh
```

> **Important**: Set `NIC_NAME` in `vars/bash.env` to your actual network interface name before running. Using the wrong name will misconfigure networking. Check with `ip link show`.

### 4. Install and Configure Ansible
Run `ansible.sh` to install Ansible, generate an SSH key, copy it to the Proxmox host, and create the `ansible` service user:

```bash
sudo ./scripts/ansible.sh
```

> **Note**: This script will prompt for the Proxmox root password once during `ssh-copy-id`. Ensure `vars/bash.env` is configured before running.

### 5. Create a Debian Cloud-Init Template
```bash
ansible-playbook ansible/playbooks/create_debian_template.yml -i ansible/inventory.yml
```

> **Note**: Review `ansible/vars/provision_vms.yml` and ensure `storage`, `vm_id`, and `disk_size` are correct before running.

### 6. Create Proxmox API User Manually

Before provisioning VMs, create a Proxmox user with API access:

1. **Log in** to the Proxmox web interface at `https://<proxmox-ip>:8006`.

2. **Add a new user**:
   - `Datacenter` → `Permissions` → `Users` → `Add`
   - Username: e.g. `ansible@pam`

3. **Assign permissions**:
   - `Permissions` → `Add` → `User Permission`
   - Path: `/`, User: `ansible@pam`, Role: `Administrator`

4. **Create an API token**:
   - `Permissions` → `API Tokens` → `Add`
   - User: `ansible@pam`, Token ID: e.g. `ansible-token`, uncheck Privilege Separation

5. **Store the token** in `ansible/vars/ansible_secrets.yml` (encrypt with Ansible Vault):

```yaml
api_token_id: "ansible-token"
api_token_secret: "<your-token-secret>"
```

### 7. Provision Proxmox Network
```bash
ansible-playbook ansible/playbooks/provision_network.yml -i ansible/inventory.yml
```

### 8. Provision Virtual Machines
```bash
ansible-playbook ansible/playbooks/provision_vms.yml -i ansible/inventory.yml
```

This playbook provisions Ceph VMs and a Docker VM, and adds them dynamically to the inventory.

### 9. Deploy Monitoring Stack
The monitoring stack is deployed automatically as part of `provision_vms.yml`. To deploy it manually:

```bash
cp docker/monitoring/.env.example docker/monitoring/.env
nano docker/monitoring/.env   # set GRAFANA_ADMIN_USER and GRAFANA_ADMIN_PASSWORD

cd docker/monitoring
docker-compose up -d
```

| Service | URL |
|---|---|
| Prometheus | `http://<host>:9090` |
| Grafana | `http://<host>:3000` |
| cAdvisor | `http://<host>:8080` |

> **Note**: The monitoring stack is intended to run on the Docker VM, not on the Proxmox host. The `configure_docker.yml` playbook handles copying files and starting the stack on the VM.

## Configuration

### Bash Variables (`vars/bash.env`)
Copy from the example and fill in your values:

```bash
cp vars/bash.env.example vars/bash.env
```

Variables are sourced automatically by both scripts at startup.

### Ansible Inventory (`ansible/inventory.yml`)
Fill in the IP addresses for Ceph and Docker hosts once they are provisioned. Hosts with `FILL_IN` as the address are placeholders:

```yaml
ceph:
  hosts:
    ceph_cluster1:
      ansible_host: "192.168.1.X"   # replace with actual IP
```

### Ansible Secrets (`ansible/vars/ansible_secrets.yml`)
Encrypt sensitive values with Ansible Vault:

```bash
ansible-vault encrypt ansible/vars/ansible_secrets.yml
ansible-vault decrypt ansible/vars/ansible_secrets.yml
```

### Provisioning Variables (`ansible/vars/provision_vms.yml`)
Contains VM specs (CPU, memory, disk, storage pool) used by `provision_vms.yml` and `create_debian_template.yml`.

## Security Best Practices
- Encrypt `ansible/vars/ansible_secrets.yml` using `ansible-vault`.
- Never commit `vars/bash.env` or `docker/monitoring/.env` — both are gitignored.
- Set correct permissions on SSH keys: `chmod 600 ~/.ssh/ansible-key`.
- Test playbooks in a non-production environment before full deployment.
