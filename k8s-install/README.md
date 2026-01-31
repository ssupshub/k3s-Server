# Kubernetes Installation Guide

This folder contains scripts and configurations to set up a Kubernetes (K3s) Master node and connect your Android worker nodes.

## 1. Install Master Node

Choose the script that matches your environment.

### Option A: Standard Install (Recommended)

Uses `containerd` (bundled with K3s). Best for standalone clusters and generally more stable for K3s.

```bash
cd k8s-install
chmod +x install-without-docker.sh
sudo ./install-without-docker.sh
```

### Option B: Archive/Docker Install

Use this if you are already running other containers in Docker and want K3s to manage them, or if you prefer the Docker CLI for debugging.

```bash
cd k8s-install
chmod +x install-with-docker.sh
sudo ./install-with-docker.sh
```

## 2. Configuration & Manifests

- **Configs**: Edit `configs/k3s-server-config.yaml` to customize your installation (e.g., disable Traefik, change ports).
- **Manifests**: Use `manifests/example-deployment.yaml` to test your cluster.

```bash
kubectl apply -f manifests/example-deployment.yaml
# Access at http://<SERVER_IP>:30080
```

### Validate with Demo App (Recommended)

Once your cluster is running, we recommend deploying the **Production-Ready Demo App** included in this repository. It is optimized for Android nodes.

```bash
# From the root directory
kubectl apply -f ../demo-app/deployment.yaml
```

See [../demo-app/README.md](../demo-app/README.md) for full details.

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
