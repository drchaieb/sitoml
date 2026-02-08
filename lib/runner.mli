(** Simulation runner.

    This module executes simulations using the `Owl` scientific computing library. It acts as an
    interpreter for the symbolic schemes, performing Monte Carlo simulations either sequentially or in parallel.
*)

open Expr
open Discretize

(** [eval env expr] evaluates a symbolic expression to a float value given a variable environment.

    @param env A list of (variable name, value) pairs.
    @param expr The scalar expression to evaluate.
    @return The resulting floating-point value.
    @raise Failure if the expression contains operations not supported by this evaluator (e.g., matrix ops returning non-scalars).
*)
val eval : (string * float) list -> 'a t -> float

(** [simulate_path scheme initial_env n_steps dt] simulates a single sample path.

    @param scheme The discretization scheme.
    @param initial_env Initial values for state variables.
    @param n_steps Number of time steps to simulate.
    @param dt The fixed time step size.
    @return A list of values for the first state variable (MVP limitation), representing the trajectory.
*)
val simulate_path : scheme -> (string * float) list -> int -> float -> float list

(** [monte_carlo scheme initial_env n_steps dt n_paths] performs a sequential Monte Carlo simulation.

    @param n_paths The number of trajectories to generate.
    @return A list of trajectories (list of lists of floats).
*)
val monte_carlo : scheme -> (string * float) list -> int -> float -> int -> float list list

(** [parallel_monte_carlo ~domain_mgr scheme initial_env n_steps dt n_paths] performs a parallel Monte Carlo simulation.

    Utilizes [Eio] domains to distribute the workload across available CPU cores.

    @param domain_mgr The Eio domain manager capability.
    @return A list of trajectories.
*)
val parallel_monte_carlo : domain_mgr:_ Eio.Domain_manager.t -> scheme -> (string * float) list -> int -> float -> int -> float list list
