#!/bin/bash

# Exit on any error
set -e

# Update package list
# apt-get update -y

# Install nginx
apt-get install git nginx -y

# Download and install CloudWatch agent
wget https://amazoncloudwatch-agent.s3.amazonaws.com/debian/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create custom index page (fixed hostname variable)s
echo "Hello from $(hostname)" | tee /var/www/html/index.nginx-debian.html

# Backup rsyslog config before modifying
cp /etc/rsyslog.d/50-default.conf /etc/rsyslog.d/50-default.conf.backup

# Modify rsyslog configuration (fixed sed command)
sed -i 's/authpriv\.none/authpriv.none;*.!err;*.!crit/' /etc/rsyslog.d/50-default.conf

# Add error logging configuration (safer approach)
if ! grep -q "*.err;*.crit.*-/var/log/error.log" /etc/rsyslog.d/50-default.conf; then
    awk '/user\.log/ {print; print "*.err;*.crit                    -/var/log/error.log"; next} 1' /etc/rsyslog.d/50-default.conf > /tmp/rsyslog_temp
    mv /tmp/rsyslog_temp /etc/rsyslog.d/50-default.conf
fi

# Restart rsyslog to apply changes
systemctl restart rsyslog

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Clean up downloaded file
rm -f ./amazon-cloudwatch-agent.deb

# Get amazon-cloudwatch-agent.json file
git clone https://github.com/askargd/task-aix .
mv amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Enable and start cloudwatch agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent.json

# Launch a cron job
(crontab -l 2>/dev/null; echo "0 15 * * * /root/archive_logs.sh") | crontab -