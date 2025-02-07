#!/bin/sh

set -e

ansibleCoreVersion=2.16.5
repoUrlHttps="https://github.com/dehidehidehi/ansible-configs.git"
repoUrlSsh="git@github.com:dehidehidehi/ansible-configs.git"
repoUrl=$repoUrlSsh
repoDir="$HOME/Documents/Development/ansible-configs"
logsFile="$HOME/tmp/logs/ansible-configs.log"

if [ -z "$(find /var/cache/apt -maxdepth 0 -mmin -1440)" ]; then
   	yes | sudo apt update
   	yes | sudo apt upgrade
else
	echo "Update/upgrade already done in the last 23 hours"
fi

mkdir -p "$HOME/tmp" || true

# Git
sudo apt install git
git config --global user.name "toset"
git config --global user.email "toset@email.com"

# Git LFS
version="3.4.1"
dir="$HOME/tmp/downloads"
filename="git-lfs.tar.gz"
downloadUri="https://github.com/git-lfs/git-lfs/releases/download/v$version/git-lfs-linux-amd64-v$version.tar.gz" 

mkdir -p "$dir" || true

echo "Downloading Git LFS..."
curl -s -L $downloadUri -o "$dir/$filename"

echo "Extracting LFS..."
tar -xzvf "$dir/$filename" -C "$dir" > /dev/null

echo "Installing LFS..."
sudo "$dir/git-lfs-$version/install.sh"

# Verify installation
verify=$(git lfs install)
if [[ "$verify" != *"Git LFS initialized."* ]]; then
   	echo "Git LFS didn't seem to install properly"; 
	return 2;
fi

echo "Checking ansible-core $ansibleCoreVersion"
pip3 install ansible-core~=$ansibleCoreVersion 1> /dev/null

echo "Checking Ansible Galaxy Community"
ansible-galaxy collection install community.general 1> /dev/null

# Install or pull Git repo 
mkdir -p "$repoDir" || true
git clone "$repoUrl" "$repoDir" || git -C "$repoDir" pull || git -C "$repoDir" restore . && git -C "$repoDir" restore --staged .
gitStatus=$?
if [ $gitStatus -eq 2 ]; then echo "Issue pulling ansible configuration repository." && return 2; fi

# Execute Ansible
inventory="hosts"
playbook="local.yml"

prevDir=$(pwd)
cd "$repoDir"

ansible-playbook $playbook -i $inventory --ask-become-pass || cd "$prevDir"
