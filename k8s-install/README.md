# Kubernetes Installation Guide

This folder contains scripts and configurations to set up a Kubernetes (K3s) Master node and connect your Android worker nodes.

## 1. Install Master Node

You can install the master node on any Linux computer/server (VM, VPS, or bare metal).

### Prerequisites

- Linux running on x86_64 or ARM64.
- Root access (`sudo`).
- Static IP is recommended for the server.

### Option A: Standard Install (Recommended)

Uses `containerd` (bundled with K3s). Best for standalone clusters.

```bash
cd k8s-install
chmod +x install-server.sh
sudo ./install-server.sh --config configs/k3s-server-config.yaml
```

### Option B: With Docker via `--docker`

If you already use Docker and want K3s to use it as the runtime.

```bash
sudo ./install-server.sh --docker
```

## 2. Configuration & Manifests

- **Configs**: Edit `configs/k3s-server-config.yaml` to customize your installation (e.g., disable Traefik, change ports).
- **Manifests**: Use `manifests/example-deployment.yaml` to test your cluster.

```bash
kubectl apply -f manifests/example-deployment.yaml
# Access at http://<SERVER_IP>:30080
```

## 3. Connecting the Android Worker

After the master is installed, the script will output a command. It looks like this:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_IP>:6443 K3S_TOKEN=<TOKEN> sh -s - agent
```

### Android Specifics

On your Android device (inside Termux/Linux Deploy):

1.  Navigate to the `k3s-server` root.
2.  Run the golden setup script first (from the parent folder):
    ```bash
    sudo ../scripts/setup-node.sh
    ```
3.  **THEN** run the join command you got from the master.

## Troubleshooting

- **Firewall**: Ensure port **6443** (API) and **10250** (Metrics) are open on the master.
- **Network**: If the phone is on WiFi and Master is on LAN, ensure they can ping each other.
