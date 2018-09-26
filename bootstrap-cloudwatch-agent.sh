#!/bin/bash
set -euxo pipefail

cd /tmp

echo "Writing AWS Logs config"
sudo tee awslogs.conf << 'END'
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/syslog]
file = /var/log/syslog
log_group_name = /var/log/syslog
log_stream_name = vault_{instance_id}
datetime_format = %Y-%m-%dT%H:%M:%S%z
time_zone = LOCAL
initial_position = start_of_file
buffer_duration = 10000
END

echo "Installing AWS CloudWatch Logs agent"
curl https://s3.amazonaws.com//aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
chmod +x ./awslogs-agent-setup.py
sudo ./awslogs-agent-setup.py -n -r ap-southeast-2 -c awslogs.conf