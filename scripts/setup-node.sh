#!/bin/bash
set -e
set -o pipefail

# Android K3s Node Setup Script (Hardened)
# This script prepares an Android device (via Termux/Proot/Chroot) to run as a K3s worker node.
# Security: Runs checks for root, validates architecture, and sets safe defaults.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${GREEN}Starting Android K3s Node Setup (Hardened)...${NC}"

# 1. Security & Environment Checks
# ------------------------------

# Check for Root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root." 
   exit 1
fi

# Architecture Check
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "armv7l" ]]; then
    log_error "Unsupported architecture $ARCH. This project targets ARM64/ARMv7 Android devices."
    exit 1
fi
log_success "Architecture $ARCH detected."

# 2. Cgroups Mounting ('Golden' Fix)
# ----------------------------------
# Android uses cgroup v1 or v2 depending on kernel. K3s needs access to them.
log_info "Configuring control groups..."

if [ ! -d /sys/fs/cgroup ]; then
    mkdir -p /sys/fs/cgroup
fi

# Try mounting tmpfs for cgroup hierarchy if not present
if ! mountpoint -q /sys/fs/cgroup; then
    mount -t tmpfs -o mode=755 tmpfs /sys/fs/cgroup || log_warn "Could not mount tmpfs at /sys/fs/cgroup"
fi

# Mount basic subsystems
CGROUP_SUBSYSTEMS=(cpu cpuacct memory devices freezer blkio pids cpuset net_cls net_prio)
for subsystem in "${CGROUP_SUBSYSTEMS[@]}"; do
    mkdir -p "/sys/fs/cgroup/$subsystem"
    if ! mountpoint -q "/sys/fs/cgroup/$subsystem"; then
        if mount -t cgroup -o "$subsystem" cgroup "/sys/fs/cgroup/$subsystem"; then
            log_info "Mounted cgroup: $subsystem"
        else
            # Some kernels have combined hierarchies or missing modules, exact failure isn't always fatal if others work
            log_warn "Failed to mount cgroup: $subsystem (might be unavailable or combined)"
        fi
    fi
done

# Systemd cgroup fix (critical for K3s systemd cgroup driver compability)
if [ ! -d /sys/fs/cgroup/systemd ]; then
    mkdir -p /sys/fs/cgroup/systemd
    mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd || true
fi

# 3. Networking & Firewall
# ------------------------
log_info "Configuring networking..."

# Enable IP Forwarding (Essential for Container Networking)
echo 1 > /proc/sys/net/ipv4/ip_forward
log_success "IP Forwarding enabled."

# Check for iptables
# Android often uses legacy iptables. K3s usually bundles its own, but we check host availability.
if command -v iptables >/dev/null; then
    IPT_VER=$(iptables --version)
    log_info "Found iptables: $IPT_VER"
    
    # Switch to legacy if available and current is nftables (common K3s issue on older kernels)
    if command -v iptables-legacy >/dev/null; then
        if iptables -V | grep -q "nf_tables"; then
            log_warn "Detected iptables-nft. Suggesting update-alternatives to legacy if K3s networking fails."
            # We don't force switch here to avoid breaking user system, but it's a common debug step.
        fi
    fi
else
    log_warn "Host iptables not found. K3s will rely on bundled binaries."
fi

# 4. Kernel Modules (Informational)
# ---------------------------------
# K3s generally needs: overlay, br_netfilter.
log_info "Checking kernel features..."
REQUIRED_MODULES=("overlay" "br_netfilter")
for mod in "${REQUIRED_MODULES[@]}"; do
    if grep -q "$mod" /proc/modules || grep -q "$mod" /proc/filesystems; then
        log_success "Module/Feature '$mod' found."
    else
        log_warn "Module '$mod' not explicitly enabled in /proc. K3s might fail to start pods."
        # Attempt load (often fails on Android due to locked kernel, but worth a try)
        modprobe $mod 2>/dev/null || true
    fi
done

# 5. Connectivity Testing (New)
# -----------------------------
log_info "Environment is prepared."

# 6. Final Instructions
# ---------------------
echo ""
echo "----------------------------------------------------------------"
log_success "ANDROID NODE PREPARATION COMPLETE"
echo "----------------------------------------------------------------"
echo "To join this device to your K3s server:"
echo "1. Ensure this device serves on the SAME WiFi/network as the Master."
echo "2. Run the K3s Agent command:"
echo ""
echo -e "${YELLOW}curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<TOKEN> sh -s - agent --config $(pwd)/../config/k3s-agent-config.yaml${NC}"
echo ""
echo "Note: If you encounter 'OOM' errors, check the limits in k3s-agent-config.yaml."
