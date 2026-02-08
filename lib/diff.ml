open Expr

let rec deriv : type a. a t -> string -> a t =
 fun e x ->
  match e with
  | Const _ -> Const 0.0
  | Var s -> if s = x then Const 1.0 else Const 0.0
  | Add (a, b) -> Add (deriv a x, deriv b x)
  | Sub (a, b) -> Sub (deriv a x, deriv b x)
  | Mul (a, b) ->
      (* d(uv) = u'v + uv' *)
      (* a : scalar t, b : 'a t *)
      let da = deriv a x in
      let db = deriv b x in
      Add (Mul (da, b), Mul (a, db))
  | Div (a, b) ->
      (* d(u/v) = (u'v - uv') / v^2 *)
      (* a : 'a t, b : scalar t *)
      let da = deriv a x in
      let db = deriv b x in
      Div (Sub (Mul (b, da), Mul (db, a)), Pow (b, Const 2.0))
  | Pow (a, b) ->
      (* d(a^b) = b * a^(b-1) * a' + a^b * log(a) * b' *)
      (* a : scalar t, b : scalar t *)
      let da = deriv a x in
      let db = deriv b x in
      Add
        ( Mul (Mul (b, Pow (a, Sub (b, Const 1.0))), da),
          Mul (Mul (Pow (a, b), Log a), db) )
  | Exp a -> Mul (Exp a, deriv a x)
  | Log a -> Div (deriv a x, a)
  | Sin a -> Mul (Cos a, deriv a x)
  | Cos a -> Mul (Sub (Const 0.0, Sin a), deriv a x)
  | Vec vs -> Vec (List.map (fun v -> deriv v x) vs)
  | Mat m -> Mat (List.map (fun r -> List.map (fun v -> deriv v x) r) m)
  | Dot (a, b) ->
      (* d(a.b) = a'.b + a.b' *)
      Add (Dot (deriv a x, b), Dot (a, deriv b x))
  | MatMul (a, b) ->
      (* d(AB) = A'B + AB' *)
      Add (MatMul (deriv a x, b), MatMul (a, deriv b x))
