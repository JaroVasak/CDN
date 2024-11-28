#!/bin/bash

# ----------------------------
# Configuration Section
# ----------------------------

# Read the Proxmox Host IP from the command line
if [ -z "$1" ]; then
    echo "Usage: $0 <PROXMOX_HOST>"
    exit 1
fi
PROXMOX_HOST="$1"

# Variables
ANSIBLE_USER="ansible"
SSH_KEY_NAME="ansible-key"
SSH_KEY_PATH="/home/$ANSIBLE_USER/.ssh/$SSH_KEY_NAME"
INVENTORY_FILE="inventory.yml"
ANSIBLE_PLAYBOOK="proxmox_onboard.yml"
SUDOER_FILE="files/sudoer_ansible"

# Install prerequisites (wget and gpg)
echo "Installing prerequisites (wget and gpg)..."
sudo apt update
sudo apt install wget gpg sshpass -y

# Set the Ubuntu codename for Debian 12 (Bookworm)
UBUNTU_CODENAME=jammy  # This is the correct codename for Debian 12 (Bookworm)

# Add the Ansible PPA repository and its signing key
echo "Adding Ansible PPA repository..."
# Check if the Ansible keyring file already exists
if [ ! -f /usr/share/keyrings/ansible-archive-keyring.gpg ]; then
    # If it doesn't exist, download and dearmor the key
    echo "Downloading and dearmoring Ansible key..."
    wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
else
    echo "Ansible keyring already exists, skipping download."
fi
echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list

# Update APT and install Ansible
echo "Updating APT cache and installing Ansible..."
sudo apt update && sudo apt install ansible -y

# Verify the installation of Ansible
echo "Verifying Ansible installation..."
ansible --version

# ----------------------------
# Proxmox Configuration Section
# ----------------------------

# Create an inventory file for Ansible to define the Proxmox host
echo "Creating Ansible inventory file..."
cat <<EOF > $INVENTORY_FILE
all:
  hosts:
    proxmox_host:
      ansible_host: $PROXMOX_HOST
      ansible_user: root
EOF


# Configure Ansible settings to avoid warnings and key checking
echo "Configuring Ansible settings..."
cat <<EOF > ansible.cfg
[defaults]
interpreter_python=auto_silent
host_key_checking=False
EOF

# ----------------------------
# SSH Key Generation and Sharing
# ----------------------------

# Ensure the .ssh directory exists
if [ ! -d "/home/$ANSIBLE_USER/.ssh" ]; then
    echo "Creating .ssh directory for $ANSIBLE_USER..."
    mkdir -p "/home/$ANSIBLE_USER/.ssh"
    chown $ANSIBLE_USER:$ANSIBLE_USER "/home/$ANSIBLE_USER/.ssh"
    chmod 700 "/home/$ANSIBLE_USER/.ssh"
fi

# Generate SSH key for Ansible user if not already exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Generating SSH key for Ansible user..."
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "$ANSIBLE_USER@$PROXMOX_HOST"
    chown $ANSIBLE_USER:$ANSIBLE_USER "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
    chmod 600 "$SSH_KEY_PATH"
    echo "SSH key generated at $SSH_KEY_PATH"
else
    echo "SSH key already exists at $SSH_KEY_PATH"
fi

# Copying the public key to Proxmox Host for creating Cloud Teplate (Vms)
scp $SSH_KEY_PATH.pub root@$PROXMOX_HOST:/root/$SSH_KEY_NAME.pub

# ----------------------------
# Create and Run Ansible Playbook
# ----------------------------

# Create Ansible playbook to onboard Proxmox host
echo "Creating Ansible playbook..."
cat <<EOF > $ANSIBLE_PLAYBOOK
- hosts: proxmox_host
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
        key: "$(cat $SSH_KEY_PATH.pub)"

    - name: Add Ansible user to sudoers
      copy:
        src: $SUDOER_FILE
        dest: /etc/sudoers.d/$ANSIBLE_USER
        owner: root
        group: root
        mode: 0440
EOF

# Create sudoers configuration for Ansible user
echo "Creating sudoers configuration for $ANSIBLE_USER..."
mkdir -p files
cat <<EOF > files/sudoer_ansible
$ANSIBLE_USER ALL=(ALL) NOPASSWD: ALL
EOF

# ----------------------------
# Running the Playbook as root (First time)
# ----------------------------

# Check and modify Proxmox SSH configuration if the root access is denied
#echo "Ensuring SSH configuration allows public key and password authentication..."
#ssh root@$PROXMOX_HOST "sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config; \
#sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config; \
#sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config; \
#sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config; \
#systemctl restart ssh" || {
#    echo "Failed to update SSH configuration. Check root access and try again."
#    exit 1
#}

# Run the playbook to configure the Proxmox host (using root user)
echo "Running Ansible playbook to onboard Proxmox host as root..."
ansible-playbook $ANSIBLE_PLAYBOOK -i $INVENTORY_FILE --user=root -k

# ----------------------------
# Test connection with Ansible user (after first playbook run)
# ----------------------------

# Test connection using the ansible user (SSH key authentication)
echo "Testing connection with Ansible user..."
ansible proxmox_host -m ping -i $INVENTORY_FILE --user=$ANSIBLE_USER --private-key $SSH_KEY_PATH


# ----------------------------
# Update the inventory file with the new Proxmox host details
# ----------------------------

# Create an inventory file for Ansible to define the Proxmox host
echo "Updating the inventory file with the new created user and ssh key..."
cat <<EOF > $INVENTORY_FILE
all:
  hosts:
    proxmox_host:
      ansible_host: $PROXMOX_HOST
      ansible_user: $ANSIBLE_USER
      ansible_ssh_private_key_file: $SSH_KEY_PATH
EOF

# ----------------------------
# Finished
# ----------------------------

echo "Proxmox setup complete and Ansible connection verified."
