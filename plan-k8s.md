# Implementation Plan: SITO K8s Architecture

This document outlines the transition from a local unified server to a distributed Kubernetes-native architecture using Redis and Shared Storage.

## Phase 1: Dependencies & Refactoring
**Goal:** Introduce Redis client and split the monolith.

### 1.1. Dependencies
*   [ ] Add `redis-lwt` to `sito_core.opam`.
*   [ ] Run `opam install redis-lwt`.

### 1.2. Architecture Split
*   [ ] Refactor `bin/server.ml` into `bin/api.ml` (Producer) and `bin/worker.ml` (Consumer).
*   [ ] Create `lib/job_queue.ml` (and `.mli`) to encapsulate Redis logic (enqueue, dequeue, update status).
*   [ ] Update `Makefile` to build both binaries.

## Phase 2: Job Queue Implementation
**Goal:** Implement the async job flow.

### 2.1. Redis Logic
*   [ ] Implement `enqueue_job : request -> job_id` in `lib/job_queue.ml`.
*   [ ] Implement `dequeue_job : unit -> job option` (blocking pop).
*   [ ] Implement `update_status : job_id -> status -> unit`.

### 2.2. API Service (`sito-api`)
*   [ ] Update `POST /api/v1/simulate` to call `enqueue_job` and return `job_id` immediately.
*   [ ] Add `GET /api/v1/jobs/<id>` to check status and return results if complete.

### 2.3. Worker Service (`sito-worker`)
*   [ ] Implement a main loop in `bin/worker.ml` that polls Redis.
*   [ ] On job receipt:
    1.  Parse request.
    2.  Run `Server_logic.handle_simulate`.
    3.  Write results to a shared path (e.g., `/data/results/<id>.json`).
    4.  Update Redis status to `Completed`.

## Phase 3: Containerization
**Goal:** Dockerize the services.

### 3.1. Dockerfile
*   [ ] Create a multi-stage `Dockerfile`.
*   [ ] Build stage: Compiles `api.exe` and `worker.exe`.
*   [ ] Runtime stage: Minimal image copying binaries and `web/` assets.
*   [ ] Entrypoint script to switch between `api` and `worker` modes based on env var.

## Phase 4: Kubernetes Manifests
**Goal:** Deploy to K8s.

### 4.1. Infrastructure
*   [ ] `k8s/redis.yaml`: Redis Deployment + Service.
*   [ ] `k8s/pvc.yaml`: PersistentVolumeClaim for shared storage.

### 4.2. Services
*   [ ] `k8s/api.yaml`: Deployment (Replicas=2) + Service (LoadBalancer).
*   [ ] `k8s/worker.yaml`: Deployment (Replicas=Auto) + HPA (CPU/Queue based).

## Phase 5: Documentation & Verification
**Goal:** Ensure usability.

*   [ ] Update `docs/USER_GUIDE.md` with K8s deployment instructions.
*   [ ] Update `Makefile` with `docker-build` and `k8s-deploy` targets.
*   [ ] Verify end-to-end flow with a local Kind/Minikube cluster (simulated).
