#!/bin/bash
# Include bash variables
source ../vars/bash.env

# Download the Debian 12 Generic Cloud image (RAW format for ZFS compatibility)
wget --trust-server-names -P /tmp -N "$CLOUD_IMAGE_URL"

# Create a VM with the desired specifications
printf "\n** Creating a VM with $MEMORY MB using network bridge $BRIDGE\n"
qm create $VM_ID --name $VM_NAME --memory $MEMORY --net0 virtio,bridge=$BRIDGE --kvm 0

# Import the raw disk into the ZFS storage
printf "\n** Importing the disk in $FORMAT format (as 'Unused Disk 0')\n"
qm importdisk $VM_ID /tmp/$VMIMAGE $STORAGE -format $FORMAT

# Attach the imported disk to the VM using VirtIO SCSI
printf "\n** Attaching the disk to the vm using VirtIO SCSI\n"
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$VM_ID-disk-0

# Setting boot and display settings with serial console
printf "\n** Setting boot and display settings with serial console\n"
qm set $VM_ID --boot c --bootdisk scsi0 --serial0 socket --vga serial0

# Resize the disk to the specified size
qm resize $VM_ID scsi0 $DISK_SIZE

# Set up network for DHCP (or static IP if needed)
printf "\n** Using a dhcp server on $BRIDGE"
qm set $VM_ID --ipconfig0 ip=dhcp
#qm set $VM_ID --ipconfig0 ip=10.10.10.222/24,gw=10.10.10.1

# Configure cloud-init for the VM
printf "\n** Creating a cloudinit drive managed by Proxmox\n"
qm set $VMID --ide2 $STORAGE:cloudinit

# Configure SSH access using your public key
qm set $VM_ID --sshkey $SSH_KEY_PATH

printf "\n** Specifying the cloud-init configuration format\n"
#qm set $VMID --citype $CITYPE
#qm set $VMID --ciuser debian
# Optional: Set a password for the default user (alternative to SSH keys)
# qm set $VM_ID --cipassword AwesomePassword

# Verify the cloud-init configuration (optional)
qm cloudinit dump $VM_ID user
qm cloudinit dump $VMID network

# Convert the VM to a template
qm template $VM_ID

# Clean up by removing the downloaded image file
rm -v /tmp/$VMIMAGE


# Create a linked clone of the template
CLONE_ID=191
CLONE_NAME="debian12-vm1"
qm clone $VM_ID $CLONE_ID --name $CLONE_NAME

# Start the cloned VM
qm start $CLONE_ID
