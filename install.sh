#!/bin/bash

# Enhanced DNS FocusGuard Installer for Ubuntu
# Usage: sudo ./install.sh

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Check for Ubuntu
if ! grep -q 'Ubuntu' /etc/os-release; then
  echo "This installer only works on Ubuntu systems"
  exit 1
fi

# Install dependencies if missing
echo "🔧 Checking and installing required dependencies..."
DEPS=("docker.io" "docker-compose" "ufw" "jq" "net-tools")
for dep in "${DEPS[@]}"; do
  if ! command -v $dep &> /dev/null; then
    echo "Installing $dep..."
    apt update > /dev/null
    apt install -y $dep
  fi
done

# Ensure Docker service is running
if ! systemctl is-active --quiet docker; then
  echo "Starting Docker service..."
  systemctl start docker
  systemctl enable docker
fi

# Create installation directory
echo "📂 Setting up DNS FocusGuard at /opt/dns-focusguard..."
mkdir -p /opt/dns-focusguard
cd /opt/dns-focusguard

# Copy deployment files
echo "⚙️ Configuring services..."
cp -R deploy/config /opt/dns-focusguard/
cp -R deploy/scripts /opt/dns-focusguard/
cp deploy/docker-compose.yml /opt/dns-focusguard/

# Start services
echo "🚀 Starting DNS FocusGuard..."
docker-compose -f docker-compose.yml up -d

# Configure DDoS protection
echo "🛡️ Configuring DDoS guard..."
cp deploy/config/ddos-guard.service /etc/systemd/system/
chmod +x deploy/scripts/ddos-guard.sh
systemctl daemon-reload
systemctl enable ddos-guard.service
systemctl start ddos-guard.service

# Configure firewall
echo "🔥 Configuring firewall..."
if ! systemctl is-active --quiet ufw; then
  ufw enable
fi
ufw allow 53/tcp
ufw allow 53/udp
ufw reload

echo "✅ Installation complete!"
echo "=================================================="
echo "DNS Server IP: $(hostname -I | awk '{print $1}')"
echo "Management Commands:"
echo "  sudo ./update-and-restart.sh   # Apply configuration changes"
echo "  docker logs focusguard         # View DNS server logs"
echo "  systemctl status ddos-guard    # Check DDoS protection"
echo "=================================================="
