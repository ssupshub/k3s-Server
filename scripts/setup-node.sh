#!/bin/bash
set -e

# Android K3s Node Setup Script
# This script prepares an Android device (via Termux/Linux Deploy/Chroot) to run as a K3s worker node.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting Android K3s Node Setup...${NC}"

# 1. Architecture Check
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "armv7l" ]]; then
    echo -e "${RED}Error: Unsupported architecture $ARCH. This project targets ARM64/ARMv7 Android devices.${NC}"
    exit 1
fi
echo -e "${GREEN}Architecture $ARCH detected. Good.${NC}"

# 2. Check for Root (Required for cgroups/mounts)
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root. Please run with sudo or in a root shell.${NC}" 
   exit 1
fi

# 3. Mount Cgroups (The 'Golden' Fix)
# Android kernels often lack standard cgroup mounting expected by K3s/Containerd.
echo -e "${YELLOW}Checking and mounting cgroups...${NC}"

if [ ! -d /sys/fs/cgroup ]; then
    mkdir -p /sys/fs/cgroup
fi

# Mount cgroup v1 hierarchy if not present (K3s usually needs standard hierarchy)
mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup || true

for subsystem in cpu cpuacct memory devices freezer blkio pids cpuset; do
    if [ ! -d /sys/fs/cgroup/$subsystem ]; then
        mkdir -p /sys/fs/cgroup/$subsystem
        mount -t cgroup -o $subsystem cgroup /sys/fs/cgroup/$subsystem || echo -e "${YELLOW}Warning: Could not mount $subsystem cgroup.${NC}"
    fi
done

# Fix for common "cgroups: cannot found cgroup mount destination: unknown"
if [ ! -e /sys/fs/cgroup/systemd ]; then
    mkdir /sys/fs/cgroup/systemd
    mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd || true
fi

echo -e "${GREEN}Cgroups setup attempt complete.${NC}"

# 4. Kernel Module Check (Informational)
echo -e "${YELLOW}Checking for critical kernel modules...${NC}"
MISSING_MODULES=0
# List of some common modules k3s/overlayfs/networking might need. 
# Many Android kernels compile these in-built, so modprobe might fail but features exist.
# We'll just check if features seem available via /proc or similar if possible, but for now simple modprobe check or warn.
MODS=("overlay" "br_netfilter")
for mod in "${MODS[@]}"; do
    if grep -q "$mod" /proc/modules || grep -q "$mod" /proc/filesystems; then
        echo "Module $mod found."
    else
        echo -e "${YELLOW}Warning: Module $mod not explicitly found in /proc/modules (might be builtin).${NC}"
    fi
done

# 5. Enable IP Forwarding
echo "1" > /proc/sys/net/ipv4/ip_forward
echo -e "${GREEN}IP Forwarding enabled.${NC}"

# 6. Legacy headers fix (common in Termux)
# K3s sometimes looks for iptables in legacy locations or needs specific alternatives.
# We assume the user has installed iptables.

# 7. K3s Installation
# We will not run the install command automatically to prevent accidental execution without config.
# Instead, we prepare the environment.

echo -e "${GREEN}Setup complete!${NC}"
echo -e "You are now ready to install K3s. Run the installation command with your server token:"
echo -e "${YELLOW}curl -sfL https://get.k3s.io | K3S_URL=https://<SERVER_IP>:6443 K3S_TOKEN=<TOKEN> sh -s - agent --config /path/to/k3s-agent-config.yaml${NC}"
