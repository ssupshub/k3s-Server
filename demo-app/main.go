package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()

	// 1. Health Checks suitable for Kubernetes Probes
	// Liveness: Is the binary running?
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	// Readiness: Can I accept traffic? (Simulated readiness logic)
	// In a real app, you might check database connections here.
	var ready = true
	mux.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
		if ready {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("ready"))
		} else {
			http.Error(w, "service unavailable", http.StatusServiceUnavailable)
		}
	})

	// 2. Main Application Logic
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()
		fmt.Fprintf(w, "Hello from k3s-demo-app! Hostname: %s\n", hostname)
	})

	srv := &http.Server{
		Addr:    ":" + port,
		Handler: mux,
	}

	// 3. Graceful Shutdown Handling associated with SIGTERM
	// This channel will receive OS signals
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("Starting server on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Could not listen on %s: %v\n", port, err)
		}
	}()

	// Block until a signal is received
	<-stop
	log.Println("Shutting down server...")

	// Create a deadline to wait for.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Simulate "draining" connections or marking as not ready
	ready = false 

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown: ", err)
	}

	log.Println("Server exiting")
}
