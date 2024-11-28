# Project Name

## Description
This project is designed to manage virtual machine (VM) creation, provisioning, and cloud initialization using Ansible and shell scripts. It includes playbooks for automation, configuration management, and setup of Debian cloud-init templates, along with supporting Bash scripts.

## Folder Structure
```
project-name/
|
├── ansible/                          # Main directory for Ansible files
│   ├── inventory.yml                 # Inventory file
│   ├── ansible_secrets.yml           # File for storing secrets (secure it appropriately)
│   │
│   ├── playbooks/                    # Directory for main playbooks
│   │   ├── configure_ceph.yml        # Playbook for configuring ceph cluster
│   │   ├── configure_docker.yml      # Playbook for configuring docker host
│   │   └── provision_vms.yml         # Playbook for provisioning VMs
│
├── scripts/                          # Directory for Bash scripts
│   ├── ansible.sh                    # Bash script for running Ansible commands
│   ├── proxmox_onboard.sh            # Bash script for onboarding Proxmox systems
│   └── debian_template.sh            # Bash script for setting up Debian with cloud-init
```

## Prerequisites
- Ansible installed on the control machine.
- Proxmox environment accessible for VM operations.
- Debian-based templates available for cloud-init setup.

## Usage

### Ansible Playbooks
1. **VM Creation**
   ```bash
   ansible-playbook ansible/playbooks/create_vm.yml
   ```

2. **Provision VMs**
   ```bash
   ansible-playbook ansible/playbooks/provision_vms.yml
   ```

3. **Cloud Initialization**
   ```bash
   ansible-playbook ansible/playbooks/cloud_init.yml
   ```

### Shell Scripts
1. **Run Ansible Commands**
   ```bash
   ./scripts/ansible.sh
   ```

2. **Onboard Proxmox Systems**
   ```bash
   ./scripts/proxmox_onboard.sh
   ```

3. **Setup Debian Cloud-Init**
   ```bash
   ./scripts/setup_debian_cloudinit.sh
   ```

4. **Create Virtual Machines**
   ```bash
   ./scripts/create_vm.sh
   ```

## Security Notes
- Ensure `ansible_secrets.yml` is properly secured and excluded from version control.
- Use appropriate access controls and encryption for sensitive data.

## License
This project is open-source. Feel free to modify and use as needed.

## Contributing
Contributions are welcome! Please create a pull request or submit an issue if you have suggestions or improvements.

