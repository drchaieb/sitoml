open Expr
open Owl

let rec eval : type a. (string * float) list -> a t -> float =
 fun env e ->
  match e with
  | Const f -> f
  | Var s -> List.assoc s env
  | Add (a, b) -> eval env a +. eval env b
  | Sub (a, b) -> eval env a -. eval env b
  | Mul (a, b) -> eval env a *. eval env b
  | Div (a, b) -> eval env a /. eval env b
  | Pow (a, b) -> eval env a ** eval env b
  | Exp a -> exp (eval env a)
  | Log a -> log (eval env a)
  | Sin a -> sin (eval env a)
  | Cos a -> cos (eval env a)
  | _ -> failwith "Unsupported expression for evaluation"

let simulate_path scheme initial_env n_steps dt_val =
  let current_env = ref initial_env in
  let paths = ref [List.assoc (List.hd scheme.Discretize.state_vars) initial_env] in
  let dt_var = match scheme.delta_t with Var s -> s | _ -> "dt" in
  
  for _ = 1 to n_steps do
    let dw_vals = match scheme.delta_w with
      | Vec vs -> List.map (fun _ -> Stats.gaussian_rvs ~mu:0.0 ~sigma:(sqrt dt_val)) vs
      | _ -> []
    in
    let dw_vars = match scheme.delta_w with
      | Vec vs -> List.map (fun v -> match v with Var s -> s | _ -> "dw") vs
      | _ -> []
    in
    let step_env = (dt_var, dt_val) :: List.combine dw_vars dw_vals @ !current_env in
    let next_vals = match scheme.next_state with
      | Vec vs -> List.map (fun v -> eval step_env v) vs
      | _ -> []
    in
    (* Update env with new state vars *)
    let new_env = List.map2 (fun name value -> (name, value)) scheme.state_vars next_vals in
    current_env := new_env @ (List.filter (fun (k, _) -> not (List.mem k scheme.state_vars)) !current_env);
    paths := List.hd next_vals :: !paths
  done;
  List.rev !paths

let monte_carlo scheme initial_env n_steps dt_val n_paths =
  let all_paths = ref [] in
  for _ = 1 to n_paths do
    all_paths := simulate_path scheme initial_env n_steps dt_val :: !all_paths
  done;
  !all_paths

let parallel_monte_carlo ~domain_mgr scheme initial_env n_steps dt_val n_paths =
  let n_domains = 4 in (* Simple fixed number for now, can be dynamic *)
  let paths_per_domain = n_paths / n_domains in
  let extra_paths = n_paths mod n_domains in
  
  let chunks = List.init n_domains (fun i ->
    if i = 0 then paths_per_domain + extra_paths else paths_per_domain
  ) in
  
  Eio.Fiber.List.map (fun count ->
    if count = 0 then []
    else
      Eio.Domain_manager.run domain_mgr (fun () ->
        monte_carlo scheme initial_env n_steps dt_val count
      )
  ) chunks
  |> List.flatten
