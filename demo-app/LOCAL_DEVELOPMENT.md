# Local Development with Docker Compose

While Kubernetes is the target for production, `docker-compose` is an excellent tool for local development and rapid iterations.

## Why use Docker Compose?

1.  **Speed**: No need to push images to a registry or wait for Pod scheduling.
2.  **Simplicity**: It runs with a single command on any machine with Docker (no Minikube/K3s required).
3.  **Isolation**: Defines the environment exactly as code, ensuring it works the same for every developer.

## How to Run

### 1. Start the Application

Run the following command in the `demo-app` directory:

```bash
docker-compose up --build
```

- `--build`: Forces a rebuild of the image (useful if you changed `main.go`).
- **Result**: The app will start and listen on `http://localhost:8080`.

### 2. Verify it Works

Open your browser or curl:

- **Health Check**: `curl http://localhost:8080/healthz` -> `ok`
- **Main App**: `curl http://localhost:8080/` -> `Hello from k3s-demo-app...`

### 3. Emulate Limits

The `docker-compose.yml` file is configured with resource limits (0.5 CPU, 128MB RAM) to emulate a constrained environment similar to your Android nodes. This helps catch performance issues early on your powerful development machine.

### 4. Cleanup

To stop and remove containers:

```bash
docker-compose down
```
