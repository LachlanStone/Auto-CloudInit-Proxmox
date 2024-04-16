# Variables
## Download Variables
AlmaLinuxVersion=9
CloudInit_Image=AlmaLinux-$AlmaLinuxVersion-GenericCloud-latest.x86_64.qcow2
CloudInit_Download=https://repo.almalinux.org/almalinux/$AlmaLinuxVersion/cloud/x86_64/images/AlmaLinux-$AlmaLinuxVersion-GenericCloud-latest.x86_64.qcow2

## VM Creation Variables
VM_NAME=CloudInit-AlmaLinux$AlmaLinuxVersion
VMID=99998
Description="Notes: This is a Cloud-Init Image image of Ubuntu $AlmaLinuxVersion LTS
- Name: CloudInit-UbuntuSRV_LTS_$AlmaLinuxVersion
- Operating System: Ubuntu Server LTS
- Role / Purpose: This is a Deployment Template for Ubuntu
- SNMP Setup: No
- Critical: No"
### Note: The Speech Marks are required even if empty [that will cause no description]
Timezone=UTC

## Cloud Init Settings
CloudInit_Setup=None

### Options
### None - Just Added Cloud Init Drive
### Network-Only - Just add network Settings to Cloud INIT
## NOTE: All of these options also do the Network Import
### SSH - Username and SSHKey Public Key Only
### Password - Username and Password Only
### Both - Username and CiPassword and SSHKey

## User Setup
CI_UserName=
CI_Password=
CI_SSHKey_Path=
 
## Network Setup
NameServer=     # Example 8.8.8.8 1.1.1.1
SearchDomain=

# Colour Variables for Script
RED=`tput bold && tput setaf 1`
GREEN=`tput bold && tput setaf 2`
YELLOW=`tput bold && tput setaf 3`
BLUE=`tput bold && tput setaf 4`
NC=`tput sgr0`

function RED(){
	echo -e "\n${RED}${1}${NC}"
}
function GREEN(){
	echo -e "\n${GREEN}${1}${NC}"
}
function YELLOW(){
	echo -e "\n${YELLOW}${1}${NC}"
}
function BLUE(){
	echo -e "\n${BLUE}${1}${NC}"
}

# Directory Setup:
rm -rf AlmaLinux$AlmaLinuxVersion-CloudInitFiles
mkdir -p AlmaLinux$AlmaLinuxVersion-CloudInitFiles
cd AlmaLinux$AlmaLinuxVersion-CloudInitFiles

# Remove the Old Image
RED "Removing old Tempalte"
qm destroy $VMID --purge

# Cloud-Init File Setup
## Setting up the CheckSUM
curl -O -s https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-$AlmaLinuxVersion
gpg --with-subkey-fingerprints RPM-GPG-KEY-AlmaLinux-$AlmaLinuxVersion
gpg --import RPM-GPG-KEY-AlmaLinux-$AlmaLinuxVersion
curl -O -s https://repo.almalinux.org/almalinux/$AlmaLinuxVersion/cloud/x86_64/images/CHECKSUM
curl -O -s https://repo.almalinux.org/almalinux/$AlmaLinuxVersion/cloud/x86_64/images/CHECKSUM.asc
gpg --verify CHECKSUM.asc CHECKSUM

## Cloud Init Downloading
GREEN "Downloading CloudInit Image"

curl -O -s $CloudInit_Download
sha256sum -c CHECKSUM 2>&1 | grep OK | echo

# Modifiy the image via virt-customize
# GREEN "Modifiy the image via virt-customize"
virt-customize -a $CloudInit_Image --install qemu-guest-agent --truncate /etc/machine-id
virt-customize -a $CloudInit_Image --timezone $Timezone --truncate /etc/machine-id

# Creating the VM
GREEN "Starting creation of VMs"

## VM Settings and Basic Setup
GREEN "Setting up VM Settings"
qm create $VMID --memory 2048 --cpu=host,flags=+pcid --core 2 --name $VM_NAME 
qm set $VMID --onboot 1 --ostype l26 --scsihw virtio-scsi-pci --bios ovmf --machine q35 --agent=1 --net0 virtio,bridge=vmbr0 --serial0 socket 

GREEN "Importing Disks"
qm importdisk $VMID $CloudInit_Image local-lvm
qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
qm set $VMID --efidisk0 local-lvm:0 --boot order=scsi0
qm set $VMID --ide2 local-lvm:cloudinit

## Description
GREEN "Setting Description"
qm set $VMID --description "$Description"

## Cloud Init Setups
if [[ "$CloudInit_Setup" == *Network-Only* ]]; then
qm set $VMID --nameserver $NameServer --searchdomain $SearchDomain
fi

if [[ "$CloudInit_Setup" == *Password* ]]; then
qm set $VMID --nameserver $NameServer --searchdomain $SearchDomain
qm set $VMID --ciuser $CI_UserName --cipassword $CI_Password
fi


if [[ "$CloudInit_Setup" == *SSH* ]]; then
qm set $VMID --nameserver $NameServer --searchdomain $SearchDomain
qm set $VMID --ciuser $CI_UserName
qm set $VMID --sshkeys $CI_SSHKey_Path
fi

if [[ "$CloudInit_Setup" == *Both* ]]; then
qm set $VMID --nameserver $NameServer --searchdomain $SearchDomain
qm set $VMID --ciuser $CI_UserName --cipassword $CI_Password
qm set $VMID --sshkeys ~/id_rsa.pub
fi

GREEN "Finalizing Template and adding Tags"
qm set $VMID --template 1 --tags template,cloudinit