#!/bin/bash
set -e

# Kubernetes (K3s) Master Install Script
# Scenarios:
# 1. With Docker (pass --docker)
# 2. Without Docker (default, uses containerd)

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

USE_DOCKER=false
CONFIG_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --docker) USE_DOCKER=true ;;
        --config) CONFIG_FILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo -e "${BLUE}Starting Kubernetes Master Setup...${NC}"

# Pre-flight: Check for Docker if requested
if [ "$USE_DOCKER" = true ]; then
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed but --docker was requested.${NC}"
        echo "Please install Docker first or run without --docker."
        exit 1
    fi
    echo -e "${GREEN}Docker mode enablement selected.${NC}"
fi

# Prepare Install Command
INSTALL_CMD="curl -sfL https://get.k3s.io | sh -s - server"

# Append flags
if [ "$USE_DOCKER" = true ]; then
    INSTALL_CMD="$INSTALL_CMD --docker"
fi

if [ -n "$CONFIG_FILE" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}Using config file: $CONFIG_FILE${NC}"
        # Only copy if it's not already in the default location
        if [ "$CONFIG_FILE" != "/etc/rancher/k3s/config.yaml" ]; then
             mkdir -p /etc/rancher/k3s
             cp "$CONFIG_FILE" /etc/rancher/k3s/config.yaml
        fi
    else
        echo -e "${RED}Warning: Config file $CONFIG_FILE not found. Proceeding with defaults.${NC}"
    fi
fi

# Execute Installation
echo -e "${BLUE}Executing: $INSTALL_CMD${NC}"
eval "$INSTALL_CMD"

# Post-Install Info
echo -e "${GREEN}Installation Complete!${NC}"
echo ""
echo "---------------------------------------------------"
echo -e "${BLUE}Master Node Information:${NC}"

# Get IP
HOST_IP=$(hostname -I | awk '{print $1}')
echo "Server IP: $HOST_IP"

# Get Token
if [ -f /var/lib/rancher/k3s/server/node-token ]; then
    TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
    echo "Node Token: $TOKEN"
else
    echo "Token file not found yet. Try 'sudo cat /var/lib/rancher/k3s/server/node-token' in a moment."
fi

echo "---------------------------------------------------"
echo -e "${BLUE}To join your Android Worker Node:${NC}"
echo "Run this on your phone (inside the k3s-server setup):"
echo ""
echo "curl -sfL https://get.k3s.io | K3S_URL=https://$HOST_IP:6443 K3S_TOKEN=$TOKEN sh -s - agent"
echo "---------------------------------------------------"
