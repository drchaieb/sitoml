open Expr

let rec simplify : type a. a t -> a t = function
  | Add (a, b) -> (
      let a' = simplify a in
      let b' = simplify b in
      match (a', b') with
      | Const 0.0, x -> x
      | x, Const 0.0 -> x
      | Const x, Const y -> Const (x +. y)
      | _ -> Add (a', b'))
  | Sub (a, b) -> (
      let a' = simplify a in
      let b' = simplify b in
      match (a', b') with
      | x, Const 0.0 -> x
      | Const x, Const y -> Const (x -. y)
      | x, y -> (match eq_type x y with Some Eq -> zero x | None -> Sub (x, y)))
  | Mul (a, b) -> (
      let a' = simplify a in
      let b' = simplify b in
      match (a', b') with
      | Const 0.0, _ -> zero b'
      | Const 1.0, x -> x
      | _, Const 1.0 -> (match b' with Const 1.0 -> a' | _ -> Mul (a', b'))
      | Const x, Const y -> Const (x *. y)
      (* (a / b) * b -> a *)
      | Div (a, b), c -> (match eq_type b c with Some Eq -> a | None -> Mul (a', b'))
      (* a * (b / a) -> b *)
      | a, Div (b, c) -> (match eq_type a c with Some Eq -> b | None -> Mul (a', b'))
      (* Associativity: (a * b) * c -> a * (b * c) *)
      | Mul (a, b), c -> simplify (Mul (a, simplify (Mul (b, c))))
      | _ -> Mul (a', b'))
  | Div (a, b) -> (
      let a' = simplify a in
      let b' = simplify b in
      match (a', b') with
      | Const 0.0, _ -> zero a'
      | x, y -> (
          match eq_type y (Const 1.0) with
          | Some Eq -> x
          | None -> (
              match eq_type x y with
              | Some Eq -> Const 1.0
              | None -> (
                  match x with
                  | Mul (x1, x2) -> (
                      match eq_type x1 y with
                      | Some Eq -> x2
                      | None -> (
                          match eq_type x2 y with
                          | Some Eq -> x1
                          | None -> Div (a', b')))
                  | _ -> Div (a', b')))))
  | Pow (a, b) -> (
      let a' = simplify a in
      let b' = simplify b in
      match (a', b') with
      | _, Const 0.0 -> Const 1.0
      | x, Const 1.0 -> x
      | Const x, Const y -> Const (x ** y)
      | _ -> Pow (a', b'))
  | Exp (Const 0.0) -> Const 1.0
  | Exp a -> Exp (simplify a)
  | Log (Const 1.0) -> Const 0.0
  | Log a -> (
      let a' = simplify a in
      match a' with
      | Exp x -> x
      | _ -> Log a')
  | Sin (Const 0.0) -> Const 0.0
  | Sin a -> Sin (simplify a)
  | Cos (Const 0.0) -> Const 1.0
  | Cos a -> Cos (simplify a)
  | Vec vs -> Vec (List.map simplify vs)
  | Mat m -> Mat (List.map (fun r -> List.map simplify r) m)
  | Dot (a, b) -> (
      let a' = simplify a in
      let b' = simplify b in
      match (a', b') with
      | Vec vs1, Vec vs2 when List.length vs1 = List.length vs2 ->
          let rec sum = function
            | [], [] -> Const 0.0
            | [x], [y] -> simplify (Mul (x, y))
            | x :: xs, y :: ys -> simplify (Add (Mul (x, y), sum (xs, ys)))
            | _ -> Const 0.0
          in
          sum (vs1, vs2)
      | _ -> Dot (a', b'))
  | MatMul (a, b) -> MatMul (simplify a, simplify b)
  | x -> x