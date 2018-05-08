#!/bin/bash -x
set -euxo pipefail # make sure any failling command will fail the whole script

echo "Installing Hashicorp Vault"
vault_dir='/usr/local/vault'
vault_version='0.10.1'

sudo mkdir $vault_dir
cd $vault_dir
sudo wget https://releases.hashicorp.com/vault/$vault_version/vault_${vault_version}_linux_amd64.zip
sudo unzip *.zip
sudo rm *.zip
sudo ln -s $vault_dir/vault /usr/local/bin/vault

cd ~
vault --version
