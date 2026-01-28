#!/bin/bash
set -e

# Kubernetes (K3s) Master Install Script - DOCKER MODE
# This script installs K3s configured to use the Docker runtime.

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting K3s Master Setup (Docker Mode)...${NC}"

# 1. Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "This script requires Docker. Please install it first or use install-without-docker.sh."
    exit 1
fi
echo -e "${GREEN}Docker found.${NC}"

# 2. Setup Config (Optional)
CONFIG_SRC="configs/k3s-server-config.yaml"
if [ -f "$CONFIG_SRC" ]; then
    echo -e "${GREEN}Applying configuration from $CONFIG_SRC${NC}"
    mkdir -p /etc/rancher/k3s
    cp "$CONFIG_SRC" /etc/rancher/k3s/config.yaml
fi

# 3. Install K3s with --docker flag
echo -e "${BLUE}Installing K3s...${NC}"
curl -sfL https://get.k3s.io | sh -s - server --docker

# 4. Post-Install Info
HOST_IP=$(hostname -I | awk '{print $1}')
echo ""
echo -e "${GREEN}Installation Complete!${NC}"
echo "---------------------------------------------------"
if [ -f /var/lib/rancher/k3s/server/node-token ]; then
    TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
    echo -e "${BLUE}Node Token:${NC} $TOKEN"
else
    echo "Wait a moment for the token to be generated..."
fi
echo -e "${BLUE}Server IP:${NC} $HOST_IP"
echo "---------------------------------------------------"
echo "To join your Android node, run this on the phone:"
echo "curl -sfL https://get.k3s.io | K3S_URL=https://$HOST_IP:6443 K3S_TOKEN=$TOKEN sh -s - agent"
