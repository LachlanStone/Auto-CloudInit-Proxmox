# Variables
## Download Variables
DebianVersion=12
DebinaBuildName=bookworm
CloudInit_Image=debian-$DebianVersion-generic-amd64.qcow2
CloudInit_Download=https://cloud.debian.org/images/cloud/$DebinaBuildName/latest/debian-$DebianVersion-generic-amd64.qcow2

## VM Creation Variables
VM_NAME=CloudInit-Debian$DebianVersion
VMID=99998
Description="Notes: This is a Cloud-Init Image image of Debian $DebianVersion LTS
- Name: $VM_NAME
- Operating System: Debian $DebianVersion
-- Release: $DebinaBuildName
- Purpose: Debian Desktop Enviroment / Server Enviroment Cloud Init Image"
Timezone=UTC

## Note: The Speech Marks are required even if empty [that will cause no description]

## Cloud Init Variables
CloudInit_Setup=None

### Options
### None - Just Added Cloud Init Drive
### Network-Only - Just add network Settings to Cloud INIT
## NOTE: All of these options also do the Network Import
### SSH - Username and SSHKey Public Key Only
### Password - Username and Password Only
### Both - Username and CiPassword and SSHKey

## User Setup Variables
CI_UserName=
CI_Password=
CI_SSHKey_Path=
 
## Network Setup Variables
NameServer=   # Example 8.8.8.8 1.1.1.1
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
rm -rf $VM_NAME
mkdir -p $VM_NAME
cd $VM_NAME

# Remove the Old Image
RED "Removing old Tempalte"
qm destroy $VMID --purge

# Cloud-Init File Setup
## Cloud Init Downloading
GREEN "Downloading CloudInit Image"
wget $CloudInit_Download

# Modifiy the image via virt-customize
# GREEN "Modifiy the image via virt-customize"
virt-customize -a $CloudInit_Image --install qemu-guest-agent,bash-completion,locales-all --truncate /etc/machine-id
virt-customize -a $CloudInit_Image --timezone $Timezone --truncate /etc/machine-id

# Creating the VM
GREEN "Starting creation of VMs"

## VM Settings and Basic Setup
GREEN "Setting up VM Settings"
qm create $VMID --memory 2048 --cpu=host,flags=+pcid --core 2 --name $VM_NAME 
qm set $VMID --onboot 1 --ostype l26 --scsihw virtio-scsi-pci --bios ovmf --machine q35 --agent=1 --net0 virtio,bridge=vmbr0 --serial0 socket 

GREEN "Importing Disks"
if [ "$1" = "--lvm" -o "$1" = "-l" ]; then
	YELLOW "Import to local-lvm"
	qm importdisk $VMID $CloudInit_Image local-lvm
	qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
	qm set $VMID --efidisk0 local-lvm:0 --boot order=scsi0
	qm set $VMID --ide2 local-lvm:cloudinit
elif [ "$1" = "--zfs" -o "$1" = "-z" ]; then
	YELLOW "Import to local-zfs"
	qm importdisk $VMID $CloudInit_Image local-zfs
	qm set $VMID --scsi0 local-zfs:vm-$VMID-disk-0
	qm set $VMID --efidisk0 local-zfs:0 --boot order=scsi0
	qm set $VMID --ide2 local-zfs:cloudinit
elif [ "$1" = "--storage-import" -o "$1" = "-s" ]; then
	YELLOW "Import to $2"
	qm importdisk $VMID $CloudInit_Image $2
	qm set $VMID --scsi0 $2:vm-$VMID-disk-0
	qm set $VMID --efidisk0 $2:0 --boot order=scsi0
	qm set $VMID --ide2 $2:cloudinit
else
	GREEN "Importing to local-lvm"
	qm importdisk $VMID $CloudInit_Image local-lvm
	qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
	qm set $VMID --efidisk0 local-lvm:0 --boot order=scsi0
	qm set $VMID --ide2 local-lvm:cloudinit
fi

Description
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
