open Expr
open Stochastic
open Simplify

type scheme = {
  next_state : vector t;
  state_vars : string list;
  delta_t : scalar t;
  delta_w : vector t;
}

let euler_maruyama proc dt dW =
  let a =
    match proc.drift with
    | Vec vs -> vs
    | _ -> failwith "Drift must be a vector"
  in
  let b =
    match proc.diffusion with
    | Mat m -> m
    | _ -> failwith "Diffusion must be a matrix"
  in
  let n = List.length proc.state_vars in
  let m = match b with [] -> 0 | r :: _ -> List.length r in
  let dW_list = match dW with Vec vs -> vs | _ -> failwith "dW must be a vector" in
  
  let next_state_list = ref [] in
  for i = 0 to n - 1 do
    let a_i = List.nth a i in
    let drift_term = simplify (Mul (a_i, dt)) in
    let diff_term = ref (Const 0.0) in
    for j = 0 to m - 1 do
      let b_ij = List.nth (List.nth b i) j in
      let dW_j = List.nth dW_list j in
      diff_term := simplify (Add (!diff_term, simplify (Mul (b_ij, dW_j))))
    done;
    let yi = Var (List.nth proc.state_vars i) in
    next_state_list := simplify (Add (yi, simplify (Add (drift_term, !diff_term)))) :: !next_state_list
  done;
  {
    next_state = Vec (List.rev !next_state_list);
    state_vars = proc.state_vars;
    delta_t = dt;
    delta_w = dW;
  }

(* Milstein for 1D scalar noise for now *)
let milstein proc dt dW =
  let em = euler_maruyama proc dt dW in
  let b = match proc.diffusion with Mat m -> m | _ -> failwith "Diffusion must be a matrix" in
  let n = List.length proc.state_vars in
  let m = match b with [] -> 0 | r :: _ -> List.length r in
  if m <> 1 then failwith "Milstein currently only supports 1D noise in this MVP";
  
  let dW_list = match dW with Vec vs -> vs | _ -> failwith "dW must be a vector" in
  let dW_0 = List.nth dW_list 0 in
  
  let next_state_list = ref [] in
  let em_state = match em.next_state with Vec vs -> vs | _ -> [] in
  
  for i = 0 to n - 1 do
    let b_i0 = List.nth (List.nth b i) 0 in
    let mil_term = ref (Const 0.0) in
    for k = 0 to n - 1 do
      let xk = List.nth proc.state_vars k in
      let b_k0 = List.nth (List.nth b k) 0 in
      let db_idxk = Diff.deriv b_i0 xk in
      let term = simplify (Mul (Const 0.5, Mul (Mul (b_k0, db_idxk), Sub (Pow (dW_0, Const 2.0), dt)))) in
      mil_term := simplify (Add (!mil_term, term))
    done;
    next_state_list := simplify (Add (List.nth em_state i, !mil_term)) :: !next_state_list
  done;
  { em with next_state = Vec (List.rev !next_state_list) }
