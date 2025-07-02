#!/bin/bash

# Robust DNS FocusGuard Installer for Ubuntu
# Usage: sudo ./install.sh [-f]

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

# Parse options
FORCE=0
while getopts ":f" opt; do
  case $opt in
    f)
      FORCE=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Check for existing installation
if [ -d "/opt/dns-focusguard" ] && [ "$FORCE" -eq 0 ]; then
  echo "⚠️ WARNING: Existing installation detected at /opt/dns-focusguard"
  echo "This installer should only be used on a new Ubuntu server"
  echo "If you want to force a reinstall, use: sudo ./install.sh -f"
  echo "Otherwise, use update-and-restart.sh for updates"
  exit 1
fi

# Capture running containers before force reinstall
if [ "$FORCE" -eq 1 ]; then
  echo "⚠️ FORCE REINSTALL: Preparing to reinstall DNS FocusGuard..."
  
  # Capture all running containers except FocusGuard
  OTHER_CONTAINERS=()
  while IFS= read -r line; do
    if [[ ! "$line" =~ focusguard ]]; then
      OTHER_CONTAINERS+=("$line")
    fi
  done < <(docker ps --format "{{.Names}}" 2>/dev/null)
  
  # Stop FocusGuard services
  echo "🛑 Stopping FocusGuard services..."
  systemctl stop ddos-guard.service 2>/dev/null
  docker-compose -f /opt/dns-focusguard/deploy/docker-compose.yml down 2>/dev/null
  
  # Remove FocusGuard resources
  echo "🗑️ Removing existing FocusGuard installation..."
  rm -rf /opt/dns-focusguard
  docker rmi spx01/blocky 2>/dev/null
  systemctl disable ddos-guard.service 2>/dev/null
  rm -f /etc/systemd/system/ddos-guard.service
  
  echo "✅ Existing FocusGuard installation removed"
fi

# Install Docker only if needed
if ! command -v docker &> /dev/null; then
  echo "🐳 Docker not found. Installing Docker..."
  # Add Docker's official GPG key
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  
  # Add Docker repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  # Install Docker
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

# Install other dependencies
echo "📦 Installing dependencies..."
DEPS=("ufw" "jq" "net-tools")
for dep in "${DEPS[@]}"; do
  if ! command -v $dep &> /dev/null; then
    echo "Installing $dep..."
    apt-get install -y $dep
  fi
done

# Ensure Docker service is running
if ! systemctl is-active --quiet docker; then
  echo "Starting Docker service..."
  systemctl start docker
  systemctl enable docker
fi

# Check if systemd-resolved needs to be disabled
if systemctl is-active --quiet systemd-resolved; then
  echo "🛑 Disabling systemd-resolved to free port 53..."
  systemctl stop systemd-resolved
  systemctl disable systemd-resolved
fi

# Update resolv.conf only if it points to localhost
if grep -q "127.0.0.53" /etc/resolv.conf; then
  echo "🔄 Updating DNS resolver configuration..."
  rm -f /etc/resolv.conf
  echo "nameserver 1.1.1.1" > /etc/resolv.conf
  echo "nameserver 8.8.8.8" >> /etc/resolv.conf
  chattr +i /etc/resolv.conf 2>/dev/null || echo "⚠️ Could not lock resolv.conf (chattr not supported?)"
fi

# Create installation directory
echo "📂 Setting up DNS FocusGuard at /opt/dns-focusguard..."
mkdir -p /opt/dns-focusguard/config
cd /opt/dns-focusguard || exit 1

# Copy repository files
echo "📦 Copying repository files..."
#cp "$(realpath "${SCRIPT_DIR}/deploy/config/blocky-config.yaml")" /opt/dns-focusguard/config/
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cp -R "${SCRIPT_DIR}"/* /opt/dns-focusguard/ 2>/dev/null || \
cp -R /home/azureuser/git/dns-focusguard/* /opt/dns-focusguard/

chmod +x /opt/dns-focusguard/*.sh
chmod +x /opt/dns-focusguard/deploy/scripts/*.sh

# Start services
echo "🚀 Starting DNS FocusGuard..."
cd /opt/dns-focusguard
docker-compose -f deploy/docker-compose.yml down 2>/dev/null
docker-compose -f deploy/docker-compose.yml up -d

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
  ufw --force enable
fi
ufw allow 53/tcp
ufw allow 53/udp
ufw reload

# Restart other containers if we did a force reinstall
if [ "$FORCE" -eq 1 ] && [ ${#OTHER_CONTAINERS[@]} -gt 0 ]; then
  echo "🔁 Restoring other Docker containers..."
  for container in "${OTHER_CONTAINERS[@]}"; do
    echo "Starting container: $container"
    docker start "$container"
  done
fi

echo "✅ Installation complete!"
echo "=================================================="
echo "DNS Server IP: $(hostname -I | awk '{print $1}')"
echo "Management Commands:"
echo "  sudo /opt/dns-focusguard/update-and-restart.sh"
echo "  docker logs focusguard"
echo "  systemctl status ddos-guard"
echo "=================================================="
echo "⚠️ IMPORTANT: This tool should only be installed on a dedicated Ubuntu server"
echo "It modifies system DNS settings and may conflict with other services"
