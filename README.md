# Project: CDN Infrastructure Setup

## Overview

This project automates the provisioning of a Content Delivery Network (CDN) infrastructure using Proxmox and Ansible. It includes scripts for setting up Proxmox, creating Debian templates, and configuring Ansible for managing virtual machines and services like Ceph and Docker.

---

## Prerequisites

- A host machine (virtual or bare metal) with Debian installed, capable of running Proxmox.
- Basic understanding of Bash scripting and Ansible.
- An SSH key pair for Ansible configuration.

---

## Project Structure

```
CDN/
├── ansible/                # Contains Ansible configuration and playbooks
│   ├── playbooks/          # Playbooks for provisioning and configuring services
│   ├── ansible_secrets.yml # Placeholder for sensitive Ansible variables
│   ├── inventory.yml       # Ansible inventory file
│   └── vars/               # Variables for Ansible playbooks
│       ├── provision_vms.yml  # Variables for provisioning VMs
│       └── ansible_secrets.yml # Encrypted secrets or placeholders
├── scripts/                # Bash scripts for automating setup tasks
│   ├── ansible.sh          # Installs and configures Ansible on the host
│   ├── debian-template.sh  # Creates a Debian cloud-init template on Proxmox
│   └── proxmox.sh          # Installs and configures Proxmox on a Debian machine
├── vars/                   # Variables for scripts and Ansible
│   ├── bash.env            # Environment variables for Bash scripts
│   └── bash.env.example    # Template for environment variables
├── .gitignore              # Git ignore file for excluding sensitive data
└── README.md               # Project documentation
```

---

## Usage

### 1. Setup Proxmox

Run the `proxmox.sh` script to install and configure Proxmox on a Debian machine.

```bash
./scripts/proxmox.sh
```

**Note:** Update the network details (IP, gateway, and mask) in the `vars/bash.env` file before running the Bash scripts (`proxmox.sh`, `debian-template.sh`, `ansible.sh`).

### 2. Create a Debian Template

Run the `debian-template.sh` script to create a cloud-init template for Debian. Ensure the required variables are set in `vars/bash.env`.

```bash
./scripts/debian-template.sh
```

### 3. Setup Ansible

Run the `ansible.sh` script to install Ansible and configure it for use with Proxmox. Ensure the required variables are set in `vars/bash.env`.

```bash
./scripts/ansible.sh
```

### 4. Provision Virtual Machines

Use the `provision_vms.yml` playbook to provision virtual machines for Ceph and Docker.

```bash
ansible-playbook ansible/playbooks/provision_vms.yml -i ansible/inventory.yml --user=ansible --private-key ~/.ssh/ansible-key
```

---

## Configuration Files

### Bash Variables (`vars/bash.env`)

Stores environment variables for Bash scripts. An example file `bash.env.example` is provided:

```bash
PROXMOX_HOST=192.168.1.10
NETWORK_GATEWAY=192.168.1.1
NETWORK_MASK=255.255.255.0
```

To use, copy the example file and update it with your details:

```bash
cp vars/bash.env.example vars/bash.env
nano vars/bash.env
```

Load these variables in scripts using `source vars/bash.env`.

### Ansible Secrets (`ansible/ansible_secrets.yml`)

Placeholder for sensitive variables used in Ansible playbooks. Ensure this file is encrypted using `ansible-vault` if it contains sensitive information.

### Provisioning Variables (ansible/vars/provision_vms.yml)
Contains the variables used by provision_vms.yml to create and manage VMs.

---

## .gitignore

Add sensitive or environment-specific files to `.gitignore` to prevent accidental commits.

```plaintext
vars/*.env
!vars/bash.env.example
ansible/ansible_secrets.yml
```

---

## Notes

- Ensure all dependencies are installed on the host machine before running scripts (e.g., `bash`, `ssh`, `ansible`).
- Review each script and playbook to adapt it to your specific environment and requirements.
- Test in a non-production environment before deploying to production.

---

## License

This project is licensed under the MIT License. See `LICENSE` for details.

