# GEMINI.md - Project Context & Operational Guide

**Project:** SITO (Symbolic Ito)
**Stack:** OCaml 5.x (Multicore) / MLIR / Owl / Kubernetes / Redis
**Last Updated:** February 2026

---

## 1. Project Intent & Philosophy
SITO is a "Compiler for Stochastic Models." It aims to bridge the disconnect between high-level mathematical modeling on a whiteboard and performant, correct software implementation.
*   **The Goal:** Allow users to define Stochastic Differential Equations (SDEs) in symbolic form and automatically generate high-performance simulation code (CPU/GPU), perform sensitivity analysis via AD, and visualize results.
*   **The "Why":** Manual implementation of Ito's Lemma, discretization schemes (Milstein, Taylor), and gradient calculations is error-prone and tedious. SITO automates this using a type-safe symbolic engine and MLIR-based compilation.

## 2. Theoretical Foundation
The mathematical core is based on the principles outlined in *MAPLE for Stochastic Differential Equations (Cyganowski, Grüne, Kloeden, 2001)*, leveraging symbolic differential operators to generate numerical schemes.

### 2.1. Stochastic Calculus
*   **Ito Process:** Standard form $dX_t = a(t, X_t)dt + b(t, X_t)dW_t$.
*   **Stratonovich Process:** Supported via conversion formulas to Ito form (Drift Correction).
*   **Differential Operators:**
    *   **$L^0$:** Deterministic/Drift operator (includes the Ito correction term $\frac{1}{2} b^2 \frac{\partial^2}{\partial x^2}$).
    *   **$L^j$:** Noise/Diffusion operator.
    *   *Implementation:* These operators are implemented as recursive functions over the symbolic AST (GADT) to generate higher-order schemes.

### 2.2. Numerical Schemes
*   **Strong Schemes (Pathwise Convergence):**
    *   **Euler-Maruyama (Order 0.5):** $Y_{n+1} = Y_n + a\Delta + b\Delta W$.
    *   **Milstein (Order 1.0):** Adds $\frac{1}{2}b b' ((\Delta W)^2 - \Delta)$.
    *   **Taylor 1.5 (Order 1.5):** Includes higher-order terms involving $L^0 b, L^j a$ and multiple integrals.
*   **Weak Schemes (Distributional Convergence):**
    *   **Weak Euler (Order 1.0):** Simplified noise matching first moments.
    *   **Weak Taylor 2.0 (Order 2.0):** Higher-order corrections for accurate statistical moments.

## 3. System Architecture (Kubernetes Native)

SITO uses a **Control Plane / Data Plane** architecture with asynchronous job processing.

### 3.1. Components
1.  **API Service (`sito-api`)**:
    *   **Role:** User-facing REST API and Web UI (`Dream`).
    *   **Responsibility:** Validates requests, estimates workload cost, pushes jobs to Redis, and serves simulation results.
    *   **Scaling:** Stateless, scales on HTTP request load.

2.  **Worker Service (`sito-worker`)**:
    *   **Role:** High-performance simulation engine (`Owl` + `Eio`).
    *   **Responsibility:** Pulls jobs from Redis, executes Monte Carlo simulations, writes full results to Shared Storage, and updates status in Redis.
    *   **Scaling:** Scales via HPA based on Queue Depth / Workload Estimate.

3.  **Message Broker (Redis)**:
    *   **Job Queue:** Holds pending simulation tasks.
    *   **Status DB:** Stores job status (Queued, Running, Completed, Failed) and metadata (progress, stats).

4.  **Storage (PVC)**:
    *   **Shared Volume:** A Kubernetes `PersistentVolume` accessible by all workers and the API to store large simulation artifacts (e.g., CSV/Parquet files).

### 3.2. Data Flow
1.  **Submit:** User POSTs `/api/v1/simulate` -> API pushes job to Redis Queue -> Returns `job_id`.
2.  **Process:** Worker pops job -> Simulates (Multicore) -> Writes to `/data/results/<job_id>.csv` -> Updates Redis Status.
3.  **Retrieve:** User polls `/api/v1/jobs/<job_id>` -> API checks Redis -> If complete, serves file from Shared Volume.

## 4. Technology Stack

| Component | Technology | Rationale |
| :--- | :--- | :--- |
| **Language** | **OCaml 5.x** | Superior type safety (GADTs), multicore support, and compiler-building pedigree. |
| **Symbolics** | Custom GADTs | Maximum correctness for mathematical transformations. |
| **Concurrency** | `Eio` | Structured concurrency for robust resource management. |
| **Numerics/AD** | `Owl` | Performant OCaml scientific computing with built-in AD and GPU support. |
| **Code Gen** | `ocaml-mlir` | Modern compiler infrastructure for hardware-portable performance. |
| **Web API** | `Dream` | Modern, simple, and composable web framework. |
| **Messaging** | `redis-lwt` | Fast, lightweight message broker for job queuing. |
| **Frontend** | `Bonsai` | Functional UI library allowing code sharing (types) with the backend. |
| **Deployment** | Podman / K8s | Scalable container orchestration. |

## 5. Software Development Cycle

### 5.1. Development Standards
*   **Module-Driven Development:** All features MUST be implemented using a module-driven approach.
*   **Interface-First:** Every `.ml` file MUST have a corresponding `.mli` signature file.
*   **Encapsulation:** Use Abstract Data Types (ADTs) in signatures to hide implementation details and maintain invariants.
*   **Documentation:** `.mli` files serve as the primary API documentation using `(** ... *)` comments.
*   **Judicious `open`:** Avoid global `open` statements; prefer qualified names or local `open` to maintain clarity.

### 5.2. Tooling
*   **Build System:** `dune`.
*   **Package Manager:** `opam`.
*   **Formatter:** `ocamlformat`.
*   **Linter:** `bisect_ppx` (for coverage).

### 5.3. Testing (`dune runtest`)
1.  **Unit Tests:** `Alcotest` for symbolic logic and GADT transformations.
2.  **Golden Tests:** Compare simulation results of Geometric Brownian Motion (GBM) against analytical formulas.
3.  **Property-Based Testing:** `QCheck` for validating symbolic identities (e.g., $d(XY) = XdY + YdX + dXdY$).

## 6. Current Status & Known Issues
*   **Status:** Complete. Core library, Backend, and Frontend are implemented and verified.
*   **Documentation:** See `docs/USER_GUIDE.md` for usage instructions. Source documentation is generated in `_doc/_html`.
*   **Verification:** `dune runtest` passes all symbolic and numerical verification tests.

## 7. Operational Commands (CLI)
*   **Local Environment:** Always use a local opam switch (`opam switch create . --no-install`).
*   **Setup:** `make setup`
*   **Build:** `make build`
*   **Test:** `make test`
*   **Run Local (API + UI + Redis):** `make run` (Binds to `0.0.0.0:8080` for WSL/Container access)
*   **Run Worker Local:** `REDIS_HOST=127.0.0.1 opam exec -- dune exec bin/worker/main.exe`
*   **Run K8s:** `make podman-build && make k8s-deploy`
