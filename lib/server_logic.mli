(** Backend logic and types for the SITO API.

    This module encapsulates the business logic for the REST API, including request/response
    definitions and the orchestration of parsing, discretization, and simulation.
*)

(** Request payload for a simulation. *)
type simulate_request = {
  drift : string;
      (** The drift term as a string (e.g., "0.05 * S"). *)
  diffusion : string;
      (** The diffusion term as a string (e.g., "0.2 * S"). *)
  initial_state : (string * float) list;
      (** Initial values for variables (e.g., [("S", 100.0)]). *)
  n_steps : int;
      (** Number of time steps. *)
  dt : float;
      (** Time step size. *)
  n_paths : int;
      (** Number of Monte Carlo paths to simulate. *)
} [@@deriving yojson]

(** Response payload for a simulation. *)
type simulate_response = {
  paths : float list list;
      (** The generated Monte Carlo paths. *)
} [@@deriving yojson]

(** [handle_simulate ?domain_mgr req] processes a simulation request.

    It parses the drift/diffusion strings, applies the Euler-Maruyama scheme, and runs the simulation.
    If [domain_mgr] is provided, it runs in parallel; otherwise, it runs sequentially.

    @param domain_mgr Optional Eio domain manager for parallelism.
    @param req The simulation request.
    @return The simulation response.
*)
val handle_simulate : ?domain_mgr:_ Eio.Domain_manager.t -> simulate_request -> simulate_response