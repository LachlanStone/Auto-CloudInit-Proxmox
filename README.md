# Auto-CloudInit-Proxmox

Auto-CloudInit-Proxmox is a cloud instance template framework for Proxmox VE Templates. It's based on cloudbase-init, virt-customize and Proxmox-VE scripting
## List of Cloud Instance Templates

- CloudInit-Debian.sh
  - Auto Deployment of the Latest Debian LTS Release

## How to use the script

Each Script has a list of variables within the script to allow you to customize how the script runs and specific settings that will be auto applied. The Script will also auto create it own directory to work inside to keep your filesystem clean.

## Required Packages to be Installed

These scripts do require the following packages to be installed on your Proxmox-VE or Linux Host


## Find a Bug or Feature Request

Please raise all pull request or features request directly on the Repo, I am actively monitoring this Repo