open Expr
open Diff
open Simplify

type process = {
  drift : vector t;
  diffusion : matrix t;
  state_vars : string list;
  time_var : string;
}

(* L^j operator: sum_i B_ij * df/dx_i *)
let l_j f proc j =
  let b = proc.diffusion in
  (* Get the j-th column of B *)
  let col_j =
    match b with
    | Mat m -> List.map (fun row -> List.nth row j) m
    | _ -> failwith "Diffusion must be a matrix"
  in
  let terms =
    List.map2
      (fun b_ij xi -> simplify (Mul (b_ij, deriv f xi)))
      col_j proc.state_vars
  in
  List.fold_left (fun acc t -> simplify (Add (acc, t))) (Const 0.0) terms

(* L^0 operator: df/dt + sum a_i df/dx_i + 1/2 sum (BB^T)_ik d^2f/dx_idx_k *)
let l_0 f proc =
  let dt = deriv f proc.time_var in
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
  let drift_term =
    List.map2
      (fun a_i xi -> simplify (Mul (a_i, deriv f xi)))
      a proc.state_vars
    |> List.fold_left (fun acc t -> simplify (Add (acc, t))) (Const 0.0)
  in
  (* Ito term: 1/2 sum_j sum_i sum_k B_ij B_kj d^2f/dx_idx_k *)
  (* Equivalent to 1/2 Tr(B B^T H) where H is Hessian *)
  let n = List.length proc.state_vars in
  let m = match b with [] -> 0 | r :: _ -> List.length r in
  let ito_term = ref (Const 0.0) in
  for j = 0 to m - 1 do
    for i = 0 to n - 1 do
      for k = 0 to n - 1 do
        let b_ij = List.nth (List.nth b i) j in
        let b_kj = List.nth (List.nth b k) j in
        let xi = List.nth proc.state_vars i in
        let xk = List.nth proc.state_vars k in
        let d2f = deriv (deriv f xi) xk in
        let term = simplify (Mul (Const 0.5, Mul (Mul (b_ij, b_kj), d2f))) in
        ito_term := simplify (Add (!ito_term, term))
      done
    done
  done;
  simplify (Add (dt, Add (drift_term, !ito_term)))

let apply_ito f proc =
  let d_drift = l_0 f proc in
  let m = match proc.diffusion with Mat m -> (match m with [] -> 0 | r :: _ -> List.length r) | _ -> 0 in
  let d_diff = Vec (List.init m (fun j -> l_j f proc j)) in
  (d_drift, d_diff)
