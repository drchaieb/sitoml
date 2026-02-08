# Implementation Plan: SITO K8s Architecture

This document outlines the transition from a local unified server to a distributed Kubernetes-native architecture using Redis and Shared Storage.

## Phase 1: Dependencies & Refactoring
**Goal:** Introduce Redis client and split the monolith.

### 1.1. Dependencies
*   [x] Add `redis-lwt` to `sito_core.opam`.
*   [x] Run `opam install redis-lwt`.

### 1.2. Architecture Split
*   [x] Refactor binaries into `bin/api_exec.ml` and `bin/worker/main.ml`.
*   [x] Create `lib/job_queue.ml` (and `.mli`) to encapsulate Redis logic (enqueue, dequeue, update status).
*   [x] Update `Makefile` to build both binaries.

## Phase 2: Job Queue Implementation
**Goal:** Implement the async job flow.

### 2.1. Redis Logic
*   [x] Implement `enqueue_job : request -> job_id` in `lib/job_queue.ml`.
*   [x] Implement `dequeue_job : unit -> job Lwt.t` (blocking pop).
*   [x] Implement `update_status : job_id -> status -> unit`.

### 2.2. API Service (`sito-api`)
*   [x] Update `POST /api/v1/simulate` to call `enqueue_job` and return `job_id` immediately.
*   [x] Add `GET /api/v1/jobs/<id>` to check status and return results if complete.

### 2.3. Worker Service (`sito-worker`)
*   [x] Implement a main loop in `bin/worker/main.ml` that polls Redis.
*   [x] On job receipt:
    1.  Parse request.
    2.  Run `Server_logic.handle_simulate`.
    3.  Write results to a shared path.
    4.  Update Redis status to `Completed`.

## Phase 3: Containerization
**Goal:** Dockerize the services.

### 3.1. Dockerfile
*   [x] Create a multi-stage `Dockerfile`.
*   [x] Build stage: Compiles `api` and `worker`.
*   [x] Runtime stage: Minimal image copying binaries and `web/` assets.
*   [x] Entrypoint script to switch between `api` and `worker` modes based on env var.

## Phase 4: Kubernetes Manifests
**Goal:** Deploy to K8s.

### 4.1. Infrastructure
*   [x] `k8s/redis.yaml`: Redis Deployment + Service.
*   [x] `k8s/pvc.yaml`: PersistentVolumeClaim for shared storage.

### 4.2. Services
*   [x] `k8s/api.yaml`: Deployment + Service.
*   [x] `k8s/worker.yaml`: Deployment.

## Phase 5: Documentation & Makefile
**Goal:** Ensure usability.

*   [x] Update `docs/USER_GUIDE.md` with K8s deployment instructions.
*   [x] Update `Makefile` with `docker-build`, `k8s-deploy`, and `local-redis`.
*   [x] Verify end-to-end flow with a local Redis docker instance.