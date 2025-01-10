#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo" >&2
    exit 1
fi

# Source the environment variables
source "$(dirname "$(realpath "$0")")/../vars/bash.env"

# Install prerequisites (wget and gpg)
echo "Installing prerequisites (wget and gpg)..."
apt update
apt install wget gpg sshpass -y

# Add the Ansible PPA repository and its signing key
echo "Adding Ansible PPA repository..."
# Check if the Ansible keyring file already exists
if [ ! -f /usr/share/keyrings/ansible-archive-keyring.gpg ]; then
    # If it doesn't exist, download and dearmor the key
    echo "Downloading and dearmoring Ansible key..."
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
else
    echo "Ansible keyring already exists, skipping download."
fi
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/ansible.list

# Update APT and install Ansible
echo "Updating APT cache and installing Ansible..."
apt update && apt install ansible -y

# Verify the installation of Ansible
echo "Verifying Ansible installation..."
ansible --version

# ----------------------------
#  Ansible Configuration Section
# ----------------------------

# Create an inventory file for Ansible to define the Proxmox host
echo "Creating Ansible inventory file..."
cat <<EOF > $ANSIBLE_FOLDER/$INVENTORY_FILE
all:
  hosts:
    proxmox:
      ansible_host: $PROXMOX_HOST
      ansible_user: root
      ansible_ssh_private_key_file: $SSH_KEY_PATH
      ansible_python_interpreter: /usr/bin/python3
EOF

# Configure Ansible settings to avoid warnings and key checking
echo "Configuring Ansible settings..."
cat <<EOF > $ANSIBLE_FOLDER/$ANSIBLE_CONFIG
[defaults]
interpreter_python=auto_silent
host_key_checking=False
EOF

# ----------------------------
# SSH Key Generation and Sharing
# ----------------------------

# Ensure the .ssh directory exists
if [ ! -d $SSH_KEY_FOLDER ]; then
    echo "Creating .ssh directory for $ANSIBLE_USER at $SSH_KEY_FOLDER..."
    mkdir -p $SSH_KEY_FOLDER
fi

# Generate SSH key for Ansible user if not already exists
if [ ! -f $SSH_KEY_PATH ]; then
    echo "Generating SSH key for Ansible user..."
    ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N "" -C "$ANSIBLE_USER@$PROXMOX_HOST"
    echo "SSH key generated at $SSH_KEY_PATH"
else
    echo "SSH key already exists at $SSH_KEY_PATH"
fi

# Copying the public key to Proxmox Host
ssh-copy-id -i $SSH_KEY_PATH.pub root@$PROXMOX_HOST

# ----------------------------
# Create and Run Ansible Playbook
# ----------------------------

# Create Ansible playbook to onboard Proxmox host
echo "Creating Ansible playbook..."
SSH_KEY_CONTENT=$(cat $SSH_KEY_PATH.pub)
cat <<EOF > $ANSIBLE_FOLDER/playbooks/$PROXMOX_ONBOARD
- hosts: proxmox
  become: true
  tasks:
    - name: Install sudo package
      apt:
        name: sudo
        update_cache: yes
        cache_valid_time: 3600
        state: latest

    - name: Create Ansible user
      user:
        name: $ANSIBLE_USER
        shell: '/bin/bash'

    - name: Add Ansible SSH key
      authorized_key:
        user: $ANSIBLE_USER
        key: $SSH_KEY_CONTENT

    - name: Add Ansible user to sudoers
      become: true
      copy:
        src: ../files/$SUDOER_FILE
        dest: /etc/sudoers.d/$ANSIBLE_USER
        owner: root
        group: root
        mode: 0440

    - name: Create Ansible tmp directory
      file:
        path: "/home/$ANSIBLE_USER/.ansible/tmp"
        state: directory
        owner: $ANSIBLE_USER
        group: $ANSIBLE_USER
        mode: '0755'
        recurse: yes
EOF

# Create sudoers configuration for Ansible user
echo "Creating sudoers configuration for $ANSIBLE_USER..."
mkdir -p $ANSIBLE_FOLDER/files
cat <<EOF > $ANSIBLE_FOLDER/files/$SUDOER_FILE
$ANSIBLE_USER ALL=(ALL) NOPASSWD: ALL
EOF

# ----------------------------
# Running the Playbook as root (First time)
# ----------------------------
echo "Running Ansible playbook to onboard Proxmox host as root..."
echo "ansible-playbook $ANSIBLE_FOLDER/playbooks/$PROXMOX_ONBOARD -i $ANSIBLE_FOLDER/$INVENTORY_FILE"
ansible-playbook $ANSIBLE_FOLDER/playbooks/$PROXMOX_ONBOARD -i $ANSIBLE_FOLDER/$INVENTORY_FILE

# ----------------------------
# Update the inventory file with the new Proxmox host details
# ----------------------------

# Create an inventory file for Ansible to define the Proxmox host
echo "Updating the inventory file with the new created user and ssh key..."
cat <<EOF > $ANSIBLE_FOLDER/$INVENTORY_FILE
all:
  hosts:
    proxmox:
      ansible_host: $PROXMOX_HOST
      ansible_user: $ANSIBLE_USER
      ansible_ssh_private_key_file: $SSH_KEY_PATH
      ansible_python_interpreter: /usr/bin/python3
EOF

# ----------------------------
# Test connection with Ansible user (after first playbook run)
# ----------------------------
echo "Testing connection with Ansible user..."
ansible proxmox -m ping -i $ANSIBLE_FOLDER/$INVENTORY_FILE

# ----------------------------
# Finished
# ----------------------------

echo "Proxmox setup complete and Ansible connection verified."
