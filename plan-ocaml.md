# Implementation Plan: SITO (OCaml Stack)

This document outlines the phased development of the SITO (Symbolic Ito) platform using OCaml 5.x.

## Phase 1: Core Symbolic Engine (`sito-core`)
**Goal:** Build a robust, type-safe library for stochastic calculus.

### 1.1. AST & Expression Engine
*   [ ] Define GADTs for mathematical expressions (Constants, Variables, Basic Functions, Vectors, Matrices).
*   [ ] Implement a symbolic simplifier (basic algebraic identities).
*   [ ] Implement a thread-safe parser for a mathematical DSL.

### 1.2. Stochastic Calculus Logic
*   [ ] Implement symbolic differentiation (`diff : expr -> var -> expr`).
*   [ ] Implement the deterministic operator $L^0$ and diffusion operator $L^j$ as defined in *Cyganowski et al. (2001)*.
*   [ ] Implement `apply_ito : expr -> process -> expr` to automatically derive dynamics of transformed processes.

### 1.3. Discretization Engine
*   [ ] Implement Euler-Maruyama scheme generation.
*   [ ] Implement Milstein scheme generation.
*   [ ] Implement higher-order Taylor schemes (1.5 strong, 2.0 weak).

## Phase 2: Compilation & Numerics (`sito-mlir`)
**Goal:** Translate symbolic schemes into executable machine code.

### 2.1. MLIR Emitter
*   [ ] Set up `ocaml-mlir` bindings.
*   [ ] Implement a translator from the SITO AST to MLIR's `arith` and `math` dialects.
*   [ ] Implement the loop structure for Monte Carlo paths in MLIR.

### 2.2. Owl Integration
*   [ ] Integrate `Owl` for random number generation (Gaussian/Bernoulli noise).
*   [ ] Implement a JIT runner that compiles the generated MLIR and executes it via `Owl`'s backend.
*   [ ] Enable Automatic Differentiation (AD) for sensitivity analysis of simulation results.

## Phase 3: Backend & Concurrency (`sito-server`)
**Goal:** Expose the engine via a high-performance REST API.

### 3.1. API Layer
*   [ ] Set up a `Dream` server with `ppx_deriving_yojson` for serialization.
*   [ ] Define the `/api/v1/simulate` endpoint.
*   [ ] Implement request validation and error handling.

### 3.2. Structured Concurrency (`Eio`)
*   [ ] Use `Eio` to manage long-running simulation tasks.
*   [ ] Implement a task orchestrator that forks simulations into OCaml 5 Domains for parallel execution.
*   [ ] Implement cancellation logic (killing simulations if the HTTP connection is closed).

## Phase 4: Frontend UI (`sito-ui`)
**Goal:** Provide an interactive dashboard for quants.

### 4.1. Reactive UI with Bonsai
*   [ ] Set up a `js_of_ocaml` project with Jane Street's `Bonsai`.
*   [ ] Create a symbolic expression editor with real-time math rendering (MathJax/KaTeX).
*   [ ] Implement interactive Plotly charts for path visualization and convergence plots.

### 4.2. Verification Suite
*   [ ] Build a "Golden Test" UI component that compares SITO results against analytical Black-Scholes formulas.
*   [ ] Implement a "Convergence Checker" that plots error vs. time-step ($\Delta t$).

## Phase 5: Deployment & Infrastructure
**Goal:** Containerize and automate.

*   [ ] Create a multi-stage Dockerfile (Build with Dune -> Scratch image with static binary).
*   [ ] Set up GitHub Actions for CI (linting, Alcotest, property-based testing).
*   [ ] Draft Terraform scripts for AWS/GCP deployment.

---

## Technical Validation Milestones
1.  **M1 (Symbolic):** `apply_ito` correctly transforms a Geometric Brownian Motion (GBM) via $ln(S_t)$.
2.  **M2 (Numerical):** Euler-Maruyama simulation of GBM converges with order 0.5.
3.  **M3 (System):** A single API request triggers a 1-million-path simulation across all CPU cores and returns results in < 2 seconds.
