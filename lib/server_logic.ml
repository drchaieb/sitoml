open Expr
open Stochastic
open Discretize
open Runner

type simulate_request = {
  drift : string;
  diffusion : string;
  initial_state : (string * float) list;
  n_steps : int;
  dt : float;
  n_paths : int;
} [@@deriving yojson]

type simulate_response = {
  paths : float list list;
} [@@deriving yojson]

let handle_simulate ?domain_mgr req =
  let drift_expr = Parser_util.parse_scalar req.drift in
  let diff_expr = Parser_util.parse_scalar req.diffusion in
  let state_vars = List.map fst req.initial_state in
  let proc = {
    drift = Vec [drift_expr];
    diffusion = Mat [[diff_expr]];
    state_vars = state_vars;
    time_var = "t";
  } in
  let dt_expr = Var "dt" in
  let dw_expr = Vec [Var "dW"] in
  let scheme = euler_maruyama proc dt_expr dw_expr in
  let result = 
    match domain_mgr with
    | Some mgr -> parallel_monte_carlo ~domain_mgr:mgr scheme req.initial_state req.n_steps req.dt req.n_paths
    | None -> monte_carlo scheme req.initial_state req.n_steps req.dt req.n_paths
  in
  { paths = result }
