#!/bin/bash -x
set -euxo pipefail # make sure any failling command will fail the whole script

echo "################################################################################"
echo "Installing Hashicorp Vault"
vault_dir='/usr/local/vault'
vault_version='0.10.3'

sudo mkdir "$vault_dir"
cd "$vault_dir"
sudo wget https://releases.hashicorp.com/vault/$vault_version/vault_${vault_version}_linux_amd64.zip
sudo unzip *.zip
sudo rm *.zip
sudo ln -s "$vault_dir/vault" /usr/local/bin/vault


# Setting up Vault and letsencrypt as services
# See: https://www.monterail.com/blog/2017/lets-encrypt-vault-free-ssl-tls-certificate
echo "Setting up systemd service to run vault server"
sudo tee /etc/systemd/system/vault.service << 'END'
[Unit]
Description=Vault Server
Documentation=https://www.vaultproject.io/docs
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
PermissionsStartOnly=true
ExecStartPre=/sbin/setcap 'cap_ipc_lock=+ep' /usr/local/vault/vault
ExecStart=/usr/local/bin/vault server -config /opt/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
END
sudo chmod 0644 /etc/systemd/system/vault.service


echo "Installing Certbot (letsencrypt)"
cd /usr/local/bin
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
certbot-auto -n --version

sudo mv /tmp/cert-manager /usr/local/bin/cert-manager
sudo chmod +x /usr/local/bin/cert-manager
echo "Setting up systemd service to run letsencrypt via cert-manager"
sudo tee /etc/systemd/system/cert-manager.service << 'END'
[Unit]
Description=Certificate manager service
Documentation=https://certbot.eff.org/#ubuntuxenial-nginx
After=network.target

[Service]
EnvironmentFile=/opt/cert-manager.env
Type=oneshot
ExecStart=/usr/local/bin/cert-manager
ExecStartPost=/bin/systemctl restart vault.service
END

# setup the timer to run the letsencrypt service on a daily basis
# NOTE: the same names of the services!
sudo tee /etc/systemd/system/cert-manager.timer << 'END'
[Unit]
Description=Daily renewal of Let's Encrypt's certificates

[Timer]
OnCalendar=daily
RandomizedDelaySec=10
Persistent=true

[Install]
WantedBy=timers.target
END


echo "################################################################################"
echo "Installing Goldfish (Vault GUI)"
GOLDFISH_VERSION='v0.9.0'

sudo curl -L -o "$vault_dir/goldfish" https://github.com/Caiyeon/goldfish/releases/download/$GOLDFISH_VERSION/goldfish-linux-amd64
sudo chmod +x "$vault_dir/goldfish"
sudo ln -s "$vault_dir/goldfish" /usr/local/bin/goldfish

GOLDFISH_SHASUM='a716db6277afcac21a404b6155d0c52b1d633f27d39fba240aae4b9d67d70943'
echo "$GOLDFISH_SHASUM $vault_dir/goldfish" | sha256sum -c -

echo "Setting up systemd service to run vault server"
sudo tee /etc/systemd/system/goldfish.service << 'END'
[Unit]
Description=Vault GUI Server
Documentation=https://github.com/Caiyeon/goldfish/wiki
StartLimitIntervalSec=0
Requires=vault.service
After=vault.service

[Service]
Restart=on-failure
RestartSec=600
PermissionsStartOnly=true
ExecStart=/usr/local/bin/goldfish -config /opt/goldfish.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
END
sudo chmod 0644 /etc/systemd/system/goldfish.service


echo "################################################################################"
echo "Installing token provider script"

sudo wget -O /usr/local/bin/token_provider https://raw.githubusercontent.com/umccr/infrastructure/master/scripts/token_provider
sudo chmod 0744 /usr/local/bin/token_provider

sudo tee /etc/systemd/system/token_provider.service << 'END'
[Unit]
Description=Token Provider Service
Documentation=https://github.com/umccr/infrastructure/blob/master/scripts/token_provider
Requires=network-online.target
After=network-online.target
StartLimitIntervalSec=0

[Service]
EnvironmentFile=/opt/token_provider.env
Restart=on-failure
RestartSec=600
PermissionsStartOnly=true
ExecStart=/usr/local/bin/token_provider
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
END
sudo chmod 0644 /etc/systemd/system/token_provider.service

sudo tee /etc/systemd/system/token_provider.timer << 'END'
[Unit]
Description=Daily renewal Vault token for Travis

[Timer]
OnCalendar=daily
RandomizedDelaySec=10
Persistent=true

[Install]
WantedBy=timers.target
END
sudo chmod 0644 /etc/systemd/system/token_provider.timer
