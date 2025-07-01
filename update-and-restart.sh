#!/bin/bash

# Enhanced DNS FocusGuard Update Script
# Usage: sudo ./update-and-restart.sh [source-path]

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Default source paths
SOURCE_PATHS=(
  "/home/azureuser/git/dns-focusguard"  # Default development path
  "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" # Current script location
)

# Use first argument as source if provided
if [ -n "$1" ]; then
  SOURCE_PATHS=("$1" "${SOURCE_PATHS[@]}")
fi

# Find a valid source directory
SOURCE_DIR=""
for path in "${SOURCE_PATHS[@]}"; do
  if [ -d "$path" ] && [ -f "$path/install.sh" ]; then
    SOURCE_DIR="$path"
    break
  fi
done

if [ -z "$SOURCE_DIR" ]; then
  echo "❌ No valid source directory found. Please specify a path:"
  echo "   sudo ./update-and-restart.sh /path/to/git/repo"
  exit 1
fi

# Installation directory
INSTALL_DIR="/opt/dns-focusguard"

echo "🔄 Updating from source: $SOURCE_DIR"
echo "📂 Target installation: $INSTALL_DIR"

# Copy files from source to installation directory
echo "📦 Synchronizing files..."
rsync -a --delete --exclude='.git' \
  "$SOURCE_DIR/" "$INSTALL_DIR/" || {
  echo "❌ File synchronization failed"
  exit 1
}

# Set permissions
echo "🔒 Setting permissions..."
chmod +x "$INSTALL_DIR"/*.sh
chmod +x "$INSTALL_DIR"/deploy/scripts/*.sh

# Restart services
echo "🔄 Restarting services..."
cd "$INSTALL_DIR"
docker compose -f deploy/docker-compose.yml down
docker compose -f deploy/docker-compose.yml up -d

# Restart DDoS guard
echo "♻️ Restarting DDoS guard..."
systemctl daemon-reload
systemctl restart ddos-guard.service

echo "✅ Configuration updated and services restarted!"
