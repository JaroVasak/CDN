#!/bin/bash
# Include bash variables
source $(dirname "$0")/../vars/bash.env

# Step 1: Update Repository Information
echo "Updating package repository information..."
sudo apt update

# Step 2: Configure static IP Address
echo "Configuring static IP address..."
sudo bash -c "cat > /etc/network/interfaces.d/enp0s3.cfg" <<EOF
auto enp0s3
iface enp0s3 inet static
address $PROXMOX_HOST
netmask $NETMASK
gateway $GATEWAY
dns-nameservers 8.8.8.8 8.8.4.4
EOF

# Restart the networking service
sudo systemctl restart networking

# Step 3: Add the Proxmox Repository
echo "Installing prerequisite packages..."
sudo apt install curl software-properties-common apt-transport-https ca-certificates gnupg2 -y
echo "Adding Proxmox repository and key..."
curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | gpg --dearmor -o /usr/share/keyrings/proxmox.gpg
echo "deb [signed-by=/usr/share/keyrings/proxmox.gpg arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" | sudo tee /etc/apt/sources.list.d/proxmox.list

# Update the local APT cache and upgrade packages
echo "Updating APT cache and upgrading packages..."
sudo apt update && sudo apt full-upgrade -y

# Step 4: Install the Proxmox Kernel
echo "Installing Proxmox kernel..."
sudo apt install proxmox-default-kernel -y

# Step 5: Install the Proxmox Packages
echo "Installing Proxmox VE and additional packages..."
sudo apt install proxmox-ve postfix open-iscsi chrony -y

# Configure Postfix
# Backup original configuration
POSTFIX_CONFIG="/etc/postfix/main.cf"
echo "Backing up existing configuration..."
if [ -f "$POSTFIX_CONFIG" ]; then
  sudo cp "$POSTFIX_CONFIG" "$POSTFIX_CONFIG.bak"
fi

# Apply new configuration
echo "Configuring Postfix..."
sudo bash -c "cat > $POSTFIX_CONFIG" <<EOF
# Basic Postfix configuration
myhostname = mail.example.com
mydomain = example.com
myorigin = \$mydomain
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain
relayhost =
inet_interfaces = loopback-only
inet_protocols = ipv4
EOF

# Check the configuration for syntax errors
echo "Verifying Postfix configuration..."
sudo postconf -n

# Restart Postfix service
echo "Restarting Postfix..."
sudo systemctl restart postfix

# Confirm that Proxmox is installed and listening on port 8006
echo "Confirming Proxmox installation..."
ss -tunelp | grep 8006

# Comment out Proxmox Enterprise Repository line
sudo sed -i 's|^deb https://enterprise.proxmox.com|#deb https://enterprise.proxmox.com|' /etc/apt/sources.list.d/pve-enterprise.list

# Step 6: Install proxmoxer
echo "Installing proxmoxer..."
sudo sudo apt install python3-proxmoxer -y

# Step 7: Remove Old Linux Kernels
echo "Removing old Linux kernels..."

# List all installed kernels
INSTALLED_KERNELS=$(dpkg --list | grep linux-image | awk '{print $2}')
echo "Installed kernels:"
echo "$INSTALLED_KERNELS"

# Identify the Proxmox kernel (assumes it was the most recently installed)
PROXMOX_KERNEL=$(dpkg --list | grep linux-image | grep proxmox | awk '{print $2}' | tail -n 1)
if [ -z "$PROXMOX_KERNEL" ]; then
    echo "Error: Proxmox kernel not found. Skipping kernel removal."
else
    echo "Proxmox kernel identified as: $PROXMOX_KERNEL"
fi

# Remove all kernels except the Proxmox kernel
for KERNEL in $INSTALLED_KERNELS; do
    if [[ $KERNEL != "$PROXMOX_KERNEL" ]]; then
        echo "Removing old kernel: $KERNEL"
        sudo apt remove --purge "$KERNEL" -y
    else
        echo "Keeping kernel: $KERNEL"
    fi
done

# Step 8: Update GRUB
echo "Updating GRUB configuration..."
sudo update-grub
# Remove os-prober to prevent listing VMs in boot menu
echo "Removing os-prober..."
sudo apt remove os-prober -y

# Step 9: Reboot the system
echo "Rebooting the system..."
sudo reboot

# Step 10: Post Installation configuration of Proxmox
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/post-pve-install.sh)"

# Source: https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_12_Bookworm
