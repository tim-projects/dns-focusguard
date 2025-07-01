#!/bin/bash

# DNS FocusGuard Update Script
# Usage: sudo ./update-and-restart.sh

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

cd /opt/dns-focusguard

# Update from Git
echo "🔄 Updating from repository..."
git pull origin main

# Refresh configs
echo "♻️ Refreshing configurations..."
cp -R deploy/config ./
cp -R deploy/scripts ./
cp deploy/docker-compose.yml ./

# Restart services
echo "🔄 Restarting services..."
docker-compose -f docker-compose.yml down
docker-compose -f docker-compose.yml up -d
systemctl restart ddos-guard.service

echo "✅ Configuration updated and services restarted!"
