# SITO Makefile

.PHONY: all setup build test doc run clean deploy-ui docker-build k8s-deploy k8s-clean local-redis stop-redis

# Default target: build everything and generate docs
all: build deploy-ui doc test

# Environment setup (Local Opam Switch)
setup:
	opam switch create . 5.4.0 --no-install -y
	opam install . --deps-only --with-test -y
	opam install odoc -y

# Build core library, server, and web frontend
build:
	opam exec -- dune build

# Deploy compiled JS to the web folder for static serving
deploy-ui: build
	cp _build/default/web/main.bc.js web/

# Run all tests (Symbolic, Server, Verification)
test:
	opam exec -- dune runtest

# Generate high-quality HTML documentation from source code (odoc)
doc:
	opam exec -- dune build @doc

# Run the local unified server (API + UI)
# Dependencies: deploy-ui (JS) and local-redis (Docker)
run: deploy-ui local-redis
	opam exec -- dune exec bin/main.exe

# Start a local Redis instance via Docker
local-redis:
	@docker ps -f name=sito-redis | grep sito-redis > /dev/null || \
	(docker start sito-redis 2>/dev/null || \
	docker run -d --name sito-redis -p 6379:6379 redis:7-alpine)

# Stop the local Redis instance
stop-redis:
	docker stop sito-redis || true

# Docker image build
docker-build:
	docker build -t sito:latest .

# Kubernetes deployment
k8s-deploy:
	kubectl apply -f k8s/redis.yaml
	kubectl apply -f k8s/pvc.yaml
	kubectl apply -f k8s/api.yaml
	kubectl apply -f k8s/worker.yaml

k8s-clean:
	kubectl delete -f k8s/worker.yaml
	kubectl delete -f k8s/api.yaml
	kubectl delete -f k8s/pvc.yaml
	kubectl delete -f k8s/redis.yaml

# Clean build artifacts
clean:
	dune clean
	rm -f web/main.bc.js
