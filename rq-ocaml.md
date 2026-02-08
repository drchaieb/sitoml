# Project Specification: SITO (Symbolic Ito) - OCaml Stack

## 1. Project Overview and Problem Statement

### 1.1. The Problem: The Disconnect in Quantitative Modeling
In quantitative finance and science, Stochastic Differential Equations (SDEs) are fundamental, yet their practical implementation is a major bottleneck. The process of translating a model from a whiteboard to a performant, correct software application is error-prone, slow, and requires a wide range of specialized skills. Key challenges include manual application of Ito's Lemma, complex numerical code implementation, difficult sensitivity analysis, and hardware-specific code that is hard to accelerate.

### 1.2. The Solution: SITO
SITO (Symbolic Ito) is a "compiler for stochastic models" that automates this entire workflow. It provides a platform where users define their models at a high mathematical level, and SITO handles the complex calculus, code generation, and optimization. By leveraging OCaml's strengths in correctness and modern compiler infrastructure (MLIR), SITO generates correct, hardware-portable (CPU/GPU) simulation code that includes exact parameter sensitivities "for free," empowering quants and developers to innovate faster and build more robust systems.

## 2. User Personas

1.  **The Mathematical Modeller ("Quant")**: Wants an interactive, math-centric UI (JIT/Interpreter mode) to rapidly prototype and validate models, prioritizing correctness and ease of use.
2.  **The Quantitative Software Developer ("Quant Dev")**: Needs a robust API (Compiler mode) to generate high-performance, linkable simulation artifacts for integration into production systems, prioritizing performance and scalability.

## 3. Core Functional Requirements

*   **FR1: Symbolic Engine:** The system MUST provide a robust, type-safe symbolic engine for representing and manipulating mathematical expressions (real arithmetic, core functions, vectors, matrices) and performing symbolic differentiation.
*   **FR2: SDE Definition:** Users MUST be able to define Ito processes, either explicitly (`dX = a dt + b dW`) or implicitly (`Y = f(X)`).
*   **FR3: Automated Ito Calculus:** The system MUST automatically and verifiably apply Ito's Lemma.
*   **FR4: Discretization Schemes:** The system MUST generate recurrence equations for multiple schemes (MVP: Euler-Maruyama, Milstein).
*   **FR5: High-Performance Code Generation:** The system MUST compile recurrence equations into optimized simulation code for CPUs and GPUs using MLIR. This code MUST include embedded AD capabilities.
*   **FR6: Scalability & Orchestration:** The system MUST be deployable as a single Docker container and be able to orchestrate multiple workers for large-scale computations, including a cost-estimation feature.
*   **FR7: Intermediate Representation (IR) Export:** The system MUST allow power-users to inspect and export the generated MLIR textual format, enabling integration with custom toolchains.
*   **FR8: In-App Verification Suite:** The UI MUST include a "Verification Suite" where users can run a model against a known analytical solution (e.g., Black-Scholes) and view convergence plots to build trust in the results.

## 4. System Architecture

### 4.1. Technology Stack
*   **Decision:** OCaml is chosen for its superior type safety, which eliminates entire classes of bugs, and its powerful features for building compilers and correct systems (GADTs, pattern matching).
*   **Core Stack:**
    *   **Language:** OCaml 5.x (for native multicore support).
    *   **Symbolic Engine:** A **custom engine built using OCaml's variants and GADTs**. This provides maximum type safety and expressive power for representing mathematical expressions.
    *   **Numerics & AD:** **`Owl`** (OCaml Scientific Computing) - A mature library for dense and sparse matrix operations, with built-in automatic differentiation and GPU support.
    *   **Code Generation:** **`ocaml-mlir`** - Bindings to the MLIR C++ API. The SITO engine will programmatically construct MLIR from its symbolic AST.
    *   **Backend API:** **`Dream`** - A modern, simple, and robust web framework for building the REST API. `gRPC` can be used via OCaml bindings for performant internal communication.
    *   **Orchestration/Concurrency:** **`Eio`** - A library for structured concurrency. Eio's fiber-based model is ideal for managing I/O and parallel computations with robust cancellation and resource management.

### 4.2. Backend Architecture
*   **API Layer:** A `Dream` server acts as the entry point. It parses incoming JSON requests into OCaml types (using `ppx_deriving_yojson`) and launches tasks within the main Eio domain.
*   **Orchestrator (Eio Fiber):** Each incoming request spawns a main "orchestrator" fiber. This fiber uses an `Eio.Switch.t` to manage the lifecycle of all sub-tasks. It calls the core SITO library functions sequentially.
*   **Workers (Eio Fibers):** For computation, the orchestrator forks worker fibers:
    *   **`SimulationWorker`:** A fiber that takes the symbolic AST, generates MLIR, and uses `Owl` to JIT-compile and execute the simulation. Results are returned via an `Eio.Promise`.
    *   **`CompilerWorker`:** A fiber that performs the full AOT compilation to a shared object (`.so`).
    *   Eio's structured concurrency guarantees that if a request is cancelled, all associated worker fibers are automatically cleaned up.

### 4.3. Frontend Specification
*   **MVP:** A web application built with **`js_of_ocaml`** and the **`Bonsai`** UI library from Jane Street. This allows for sharing OCaml types between the frontend and backend, ensuring end-to-end type safety.
*   **Workflow:** Guides the user through the 5 steps: Define, Inspect, Discretize, Simulate, Analyze, and includes the `FR8: Verification Suite`.

### 4.4. Database & Deployment
*   **Database:** PostgreSQL. The **`caqti`** library will be used to provide a type-safe, asynchronous interface to the database.
*   **Deployment (IaC):** Terraform will define the infrastructure. The application will be packaged into a minimal Docker container using a multi-stage build. The first stage uses `dune` to build a statically linked native executable. The second stage copies this single binary into a `scratch` or `alpine` image for a minimal footprint.

## 5. Development Roadmap & Phasing
*   **Phase 1: Core Library (MVP):**
    *   **Goal:** Create a standalone, installable OCaml library `sito_core`.
    *   **Tasks:** Define the symbolic GADTs. Implement the symbolic engine, parser, Ito's applicator, and discretizer. Create a CLI using `Cmdliner`. Test everything rigorously with `Alcotest`.
*   **Phase 2: JIT Simulation Engine:**
    *   **Goal:** Extend `sito_core` with simulation capabilities.
    *   **Tasks:** Implement the `ocaml-mlir` emitter. Add a `simulate` function that uses `Owl`'s AD and JIT capabilities to run the model.
*   **Phase 3: Backend & Basic UI:**
    *   **Goal:** Build the web service around the `sito_core` library.
    *   **Tasks:** Set up the `Dream` server using `Eio` for concurrency. Develop the `Bonsai` UI and compile it with `js_of_ocaml`.

## 6. Testing & Validation Strategy
*   **Unit Tests:** `Alcotest` for comprehensive unit testing, managed via `dune runtest`.
*   **Integration Tests:** Test the full request lifecycle within the Eio environment.
*   **Golden Tests:** An `Alcotest` suite that validates SITO's numerical output against known analytical solutions for canonical SDEs.
*   **CI/CD:** GitHub Actions to run `dune build` and `dune runtest` on every commit, possibly with `ocamlformat` checks.

