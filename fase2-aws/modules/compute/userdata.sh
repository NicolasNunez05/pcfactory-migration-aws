#!/bin/bash
set -x
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== PCFactory Setup Started ==="

# Variables
PROJECT_NAME="${project_name}"
AWS_REGION="${aws_region}"
LOG_GROUP_APP="${log_group_app}"
LOG_GROUP_SYSTEM="${log_group_system}"
DB_HOST="${DB_HOST}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
ENABLE_XRAY="${enable_xray}"

# Update system
yum update -y
yum install -y python3 python3-pip postgresql15

# CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Directories
mkdir -p /opt/pcfactory-app /var/log/application

# Flask App
cat > /opt/pcfactory-app/app.py <<'EOF'
from flask import Flask, jsonify
import socket
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'message': 'PCFactory on AWS',
        'hostname': socket.gethostname(),
        'status': 'running'
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

@app.route('/info')
def info():
    return jsonify({
        'hostname': socket.gethostname(),
        'db_host': os.environ.get('DB_HOST', 'not-set'),
        'db_name': os.environ.get('DB_NAME', 'not-set')
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Install Flask
pip3 install flask gunicorn boto3

# CloudWatch Agent Config
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOFCW
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "$LOG_GROUP_SYSTEM",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/application/app.log",
            "log_group_name": "$LOG_GROUP_APP",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "PCFactory/EC2",
    "metrics_collected": {
      "mem": {
        "measurement": [{"name": "mem_used_percent"}],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [{"name": "used_percent"}],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  }
}
EOFCW

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Systemd service
cat > /etc/systemd/system/pcfactory.service <<'EOFSVC'
[Unit]
Description=PCFactory App
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/pcfactory-app
Environment="DB_HOST=${DB_HOST}"
Environment="DB_NAME=${DB_NAME}"
Environment="DB_USER=${DB_USER}"
ExecStart=/usr/local/bin/gunicorn --workers 2 --bind 0.0.0.0:8080 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOFSVC

# X-Ray daemon (if enabled)
if [ "$ENABLE_XRAY" = "true" ]; then
  wget https://s3.us-east-1.amazonaws.com/aws-xray-assets.us-east-1/xray-daemon/aws-xray-daemon-linux-3.x.rpm
  yum install -y aws-xray-daemon-linux-3.x.rpm
  systemctl enable xray
  systemctl start xray
  pip3 install aws-xray-sdk
fi

# Start app
systemctl daemon-reload
systemctl enable pcfactory
systemctl start pcfactory

echo "=== Setup Complete ==="
