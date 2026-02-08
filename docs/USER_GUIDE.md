# SITO User Guide

SITO (Symbolic Ito) is a compiler for stochastic models. This guide covers how to use SITO in three modes:
1.  **Interactive Mode (UTop):** For prototyping and exploration.
2.  **API & Web UI:** A unified service for programmatic and visual interaction.
3.  **Documentation:** High-quality source-driven API docs.

## 1. Interactive Mode (UTop)

You can use the OCaml toplevel (UTop) to interactively define SDEs and apply stochastic calculus.

### Setup
Start UTop with the SITO library loaded:
```bash
dune utop lib
```

### Example: Geometric Brownian Motion (GBM)

```ocaml
open Sito_core;;
open Expr;;
open Stochastic;;
open Discretize;;

(* Define variables *)
let s = var "S";;
let mu = var "mu";;
let sigma = var "sigma";;

(* Define the Ito process: dS = mu*S dt + sigma*S dW *)
let proc = {
  drift = Vec [mul mu s];
  diffusion = Mat [[mul sigma s]];
  state_vars = ["S"];
  time_var = "t";
};;

(* Apply Ito's Lemma to log(S) *)
let f = Log s;;
let (drift_f, diff_f) = apply_ito f proc;;

(* View the results *)
Printf.printf "Drift of log(S): %s\n" (to_string drift_f);;
(* Output: (mu - (0.5 * sigma^2.)) *)

Printf.printf "Diffusion of log(S): %s\n" (to_string diff_f);;
(* Output: [sigma] *)

(* Discretize using Euler-Maruyama *)
let dt = var "dt";;
let dw = Vec [var "dW"];;
let scheme = euler_maruyama proc dt dw;;

Printf.printf "Next S: %s\n" (to_string scheme.next_state);;
```

## 2. API & Web UI (Unified Mode)

SITO now runs as a unified service. A single binary serves both the REST API and the reactive Web UI.

### Starting the Service
```bash
make run
```
The service will be available at `http://localhost:8080`.

- **Web UI:** Open `http://localhost:8080/index.html` in your browser.
- **REST API:** Endpoint at `http://localhost:8080/api/v1/simulate`.

### Example API Request (GBM)
```bash
curl -X POST http://localhost:8080/api/v1/simulate \
  -H "Content-Type: application/json" \
  -d '{
    "drift": "0.05 * S",
    "diffusion": "0.2 * S",
    "initial_state": [["S", 100.0]],
    "n_steps": 100,
    "dt": 0.01,
    "n_paths": 10
  }'
```

**Response:**
```json
{
  "paths": [
    [100.0, 100.2, 99.8, ...],
    ...
  ]
}
```

## 3. Documentation

SITO uses `odoc` for automated, high-quality documentation generation from source code (similar to Sphinx/MkDocs).

### Generating Documentation
```bash
make doc
```
The documentation will be generated in `_build/default/_doc/_html/index.html`. You can open it in any browser to explore the modules, signatures, and internal documentation strings.