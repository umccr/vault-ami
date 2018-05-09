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

echo "Setting up systemd service to run vault server"
sudo tee /etc/systemd/system/vault.service << 'END'
[Unit]
Description=Vault Server
Documentation=https://www.vaultproject.io/docs/
After=network-online.target

[Service]
Type=simple
EnvironmentFile=-/opt/vault.env
ExecStart=/usr/local/bin/vault server $OPTIONS -config $CONFIG
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
END


echo "Installing Certbot (letsencrypt)"
cd /usr/local/bin
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
certbot-auto -n --version

echo "Setting up systemd service to run letsencrypt"
sudo tee /etc/systemd/system/letsencrypt.service << 'END'
[Unit]
Description=Let's Encrypt renewal service
Documentation=https://certbot.eff.org/#ubuntuxenial-nginx
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/certbot-auto renew --agree-tos
ExecStartPost=/bin/systemctl reload vault.service
END

sudo tee /etc/systemd/system/letsencrypt.timer << 'END'
[Unit]
Description=Daily renewal of Let's Encrypt's certificates

[Timer]
OnCalendar=daily
RandomizedDelaySec=10
Persistent=true

[Install]
WantedBy=timers.target
END
