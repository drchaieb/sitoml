# Implementation Plan: SITO (OCaml Stack)

This document outlines the phased development of the SITO (Symbolic Ito) platform using OCaml 5.x.

## Phase 1: Core Symbolic Engine (`sito-core`)
**Goal:** Build a robust, type-safe library for stochastic calculus.

### 1.1. AST & Expression Engine
*   [x] Define GADTs for mathematical expressions (Constants, Variables, Basic Functions, Vectors, Matrices).
*   [x] Implement a symbolic simplifier (basic algebraic identities).
*   [x] Implement a thread-safe parser for a mathematical DSL.

### 1.2. Stochastic Calculus Logic
*   [x] Implement symbolic differentiation (`diff : expr -> var -> expr`).
*   [x] Implement the deterministic operator $L^0$ and diffusion operator $L^j$ as defined in *Cyganowski et al. (2001)*.
*   [x] Implement `apply_ito : expr -> process -> expr` to automatically derive dynamics of transformed processes.

### 1.3. Discretization Engine
*   [x] Implement Euler-Maruyama scheme generation.
*   [x] Implement Milstein scheme generation.
*   [ ] Implement higher-order Taylor schemes (1.5 strong, 2.0 weak).

## Phase 2: Compilation & Numerics (`sito-mlir`)
**Goal:** Translate symbolic schemes into executable machine code.

### 2.1. MLIR Emitter
*   [x] Implement a translator from the SITO AST to MLIR's `arith` and `math` dialects (Textual).
*   [ ] Set up `ocaml-mlir` bindings (Blocked: package availability).

### 2.2. Owl Integration
*   [x] Integrate `Owl` for random number generation (Gaussian noise).
*   [x] Implement a JIT runner that interprets the AST via Owl (`Runner` module).
*   [ ] Enable Automatic Differentiation (AD) for sensitivity analysis of simulation results.

## Phase 3: Backend & Concurrency (`sito-api` / `sito-worker`)
**Goal:** Expose the engine via a high-performance REST API.

### 3.1. API Layer
*   [x] Set up a `Dream` server with `ppx_deriving_yojson` for serialization.
*   [x] Define the `/api/v1/simulate` endpoint.
*   [x] Implement request validation and error handling.

### 3.2. Structured Concurrency (`Eio`)
*   [x] Use `Eio` to manage long-running simulation tasks.
*   [x] Implement a task orchestrator that forks simulations into OCaml 5 Domains for parallel execution.

## Phase 4: Frontend UI (`sito-ui`)
**Goal:** Provide an interactive dashboard for quants.

### 4.1. Reactive UI
*   [x] Set up a `js_of_ocaml` project with `Brr`. (Fallback from `Bonsai` due to version constraints).
*   [x] Create a symbolic expression editor with basic parameter inputs.
*   [ ] Implement interactive Plotly charts for path visualization.

### 4.2. Verification Suite
*   [x] Build a "Golden Test" suite that compares SITO results against analytical paper formulas.
*   [x] Implement a "Verification Suite" module in tests.

## Phase 5: Deployment & Infrastructure
**Goal:** Containerize and automate.

*   [x] Create a multi-stage Containerfile.
*   [ ] Set up GitHub Actions for CI.
*   [x] Implement a comprehensive Makefile.

---

## Technical Validation Milestones
1.  **M1 (Symbolic):** `apply_ito` correctly transforms a Geometric Brownian Motion (GBM) via $ln(S_t)$. [PASSED]
2.  **M2 (Numerical):** Euler-Maruyama simulation of GBM produces reasonable bounds. [PASSED]
3.  **M3 (System):** API correctly enqueues jobs to Redis and Worker processes them. [PASSED]