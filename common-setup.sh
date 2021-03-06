#!/bin/bash -x
set -euxo pipefail # make sure any failling command will fail the whole script


echo "--------------------------------------------------------------------------------"
echo "Set timezone"
# set to Melbourne local time
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
sudo ls -al /etc/localtime


echo "--------------------------------------------------------------------------------"
echo "Configure SSH"
echo "GatewayPorts yes" | sudo tee -a /etc/ssh/sshd_config


echo "--------------------------------------------------------------------------------"
echo "Update packages (APT)"
# this delay is crucial for the apt to update properly, without it following install commands will result in package not found errors
while pgrep unattended; do sleep 10; done;
sudo apt-get update -yq --fix-missing
# sudo apt-get -y upgrade

echo "--------------------------------------------------------------------------------"
echo "Install tools"
while pgrep unattended; do sleep 10; done;

for attempt in 1 2 3; do
  if [ ! -z "`which jq`" ]; then
    break
  fi
  echo "Trying to install jq, attempt $attempt"
  sudo apt-get update -yq --fix-missing
  sudo apt-get install -yq jq
done
for attempt in 1 2 3; do
  if [ ! -z "`which wget`" ]; then
    break
  fi
  echo "Trying to install wget, attempt $attempt"
  sudo apt-get update -yq --fix-missing
  sudo apt-get install -yq wget
done
for attempt in 1 2 3; do
  if [ ! -z "`which zip`" ]; then
    break
  fi
  echo "Trying to install zip, attempt $attempt"
  sudo apt-get update -yq --fix-missing
  sudo apt-get install -yq zip
done


echo "--------------------------------------------------------------------------------"
echo "Install awscli"
sudo apt-get install -y python-pip
pip install awscli --upgrade


echo "--------------------------------------------------------------------------------"
echo "Adding SSH public keys"
# Allows *public* members on UMCCR org to SSH to our AMIs
ORG="UMCCR"

echo "Fetching GitHub SSH keys for $ORG members..."
org_ssh_keys=`curl -s https://api.github.com/orgs/$ORG/members | jq -r .[].html_url | sed 's/$/.keys/'`
for ssh_key in $org_ssh_keys
do
	wget $ssh_key -O - >> ~/.ssh/authorized_keys
done
echo "All SSH keys from $ORG added to the AMI's ~/.ssh/authorized_keys"
