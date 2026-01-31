# Build Stage
# Use specific version for reproducibility, alpine for size
FROM golang:1.23-alpine AS builder

# Set working directory
WORKDIR /app

# Copy source code
COPY main.go .

# Build the binary
# -o app: output filename
# CGO_ENABLED=0: static binary, no C dependencies (crucial for distroless/static)
# -ldflags="-s -w": strip debug symbols to reduce size
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o app main.go

# Runtime Stage
# Use distroless static image for security (no shell, no package manager) and size
# :nonroot tag ensures we don't run as root by default
FROM gcr.io/distroless/static:nonroot

# Copy binary from builder
COPY --from=builder /app/app /

# Expose the port (informative only, K8s uses containerPort)
EXPOSE 8080

# Run as non-root user (id 65532 is the nonroot user in distroless)
# While the base image sets this, explicitly stating it in K8s manifest is also good practice
USER 65532:65532

# Health check (Optional in Dockerfile if using K8s probes, but good for pure Docker usage)
# Since distroless has no curl/wget, we can use the built-in go implementation or rely on K8s probes.
# For strictly K8s usage, we skip HEALTHCHECK instruction to avoid confusing runtime behavior vs K8s probes.

# Command to run
ENTRYPOINT ["/app"]
