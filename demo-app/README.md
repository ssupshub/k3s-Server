# Demo App: Production-Ready Go Service

This directory contains a "Gold Standard" reference implementation for running workloads on your Android K3s nodes. It demonstrates how to build secure, lightweight, and resilient applications optimized for resource-constrained environments.

## 1. Local Development (Docker Compose)

While Kubernetes is the target for production, `docker-compose` is an excellent tool for local development and rapid iterations.

### Why use Docker Compose?

- **Speed**: No need to push images to a registry or wait for Pod scheduling.
- **Simplicity**: It runs with a single command on any machine with Docker.
- **Emulation**: The `docker-compose.yml` is configured with resource limits (0.5 CPU, 128MB RAM) to emulate your Android nodes locally.

### Interactive Workflow

1. **Start the App**:

   ```bash
   docker-compose up --build
   ```

   _The app will start at `http://localhost:8080`_

2. **Verify Endpoints**:
   - **Health**: `curl http://localhost:8080/healthz` -> `ok`
   - **Main**: `curl http://localhost:8080/` -> `Hello...`

3. **Cleanup**:
   ```bash
   docker-compose down
   ```

---

## 2. Kubernetes Best Practices

This section explains the critical design choices made in `Dockerfile` and `deployment.yaml` for production.

### Dockerfile Optimization

#### Multi-Stage Builds

**Why:** Separation of "Build" and "Runtime" environments keeps the final image tiny (< 15MB) by excluding compilers and build tools.

<div align="center">
  <img src="../assets/docker_multistage_build_flow_1769879426427.png" alt="Docker Multi-Stage Build" width="80%">
</div>

#### Distroless & Non-Root

**Why:** We use `gcr.io/distroless/static:nonroot`.

- **Security**: Contains _only_ the binary. No shell, no package manager.
- **Safety**: Runs as user `65532` (non-root) by default, preventing potential host escalations.

### Kubernetes Integration

#### Liveness & Readiness Probes

**Why:** Vital for zero-downtime updates and self-healing.

- **Liveness (`/healthz`)**: "I am broken, kill me." (Restarts pod)
- **Readiness (`/readyz`)**: "I am busy, don't send traffic." (Removes from Service endpoints)

<div align="center">
  <img src="../assets/k8s_probes_visual_1769879452702.png" alt="Kubernetes Probes Visual" width="80%">
</div>

#### Resource Limits

**Why:** Your Android nodes have limited RAM/CPU. Without limits, a single runaway pod can crash the phone.

- **Requests**: Minimum reserved resources.
- **Limits**: Hard ceiling.

<div align="center">
  <img src="../assets/k8s_resource_limits_visual_1769879473094.png" alt="Kubernetes Resource Limits Visual" width="80%">
</div>

#### Graceful Shutdown

**Why:** Kubernetes sends `SIGTERM` before killing a pod. The app handles this signal to finish active requests before exiting, ensuring no dropped connections during updates.
