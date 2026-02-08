type scalar = Scalar
type vector = Vector
type matrix = Matrix

type _ t =
  | Const : float -> scalar t
  | Var : string -> scalar t
  | Add : 'a t * 'a t -> 'a t
  | Sub : 'a t * 'a t -> 'a t
  | Mul : scalar t * 'a t -> 'a t
  | Div : 'a t * scalar t -> 'a t
  | Pow : scalar t * scalar t -> scalar t
  | Exp : scalar t -> scalar t
  | Log : scalar t -> scalar t
  | Sin : scalar t -> scalar t
  | Cos : scalar t -> scalar t
  | Vec : scalar t list -> vector t
  | Mat : scalar t list list -> matrix t
  | Dot : vector t * vector t -> scalar t
  | MatMul : matrix t * 'a t -> 'a t (* 'a can be vector or matrix *)

let const x = Const x
let var s = Var s
let add x y = Add (x, y)
let sub x y = Sub (x, y)
let mul x y = Mul (x, y)
let div x y = Div (x, y)

(* Helper for printing *)
let rec to_string : type a. a t -> string = function
  | Const f -> string_of_float f
  | Var s -> s
  | Add (a, b) -> "(" ^ to_string a ^ " + " ^ to_string b ^ ")"
  | Sub (a, b) -> "(" ^ to_string a ^ " - " ^ to_string b ^ ")"
  | Mul (a, b) -> to_string a ^ " * " ^ to_string b
  | Div (a, b) -> to_string a ^ " / " ^ to_string b
  | Pow (a, b) -> to_string a ^ "^" ^ to_string b
  | Exp a -> "exp(" ^ to_string a ^ ")"
  | Log a -> "log(" ^ to_string a ^ ")"
  | Sin a -> "sin(" ^ to_string a ^ ")"
  | Cos a -> "cos(" ^ to_string a ^ ")"
  | Vec vs -> "[" ^ String.concat ", " (List.map to_string vs) ^ "]"
  | Mat m ->
      "[" ^ String.concat "; " (List.map (fun r -> String.concat ", " (List.map to_string r)) m) ^ "]"
  | Dot (a, b) -> to_string a ^ " . " ^ to_string b
  | MatMul (a, b) -> to_string a ^ " @ " ^ to_string b

let rec zero : type a. a t -> a t = function
  | Const _ -> Const 0.0
  | Var _ -> Const 0.0
  | Add (a, _) -> zero a
  | Sub (a, _) -> zero a
  | Mul (_, b) -> zero b
  | Div (a, _) -> zero a
  | Pow _ -> Const 0.0
  | Exp _ -> Const 0.0
  | Log _ -> Const 0.0
  | Sin _ -> Const 0.0
  | Cos _ -> Const 0.0
  | Vec vs -> Vec (List.map zero vs)
  | Mat m -> Mat (List.map (fun r -> List.map zero r) m)
  | Dot _ -> Const 0.0
  | MatMul (_, b) -> zero b

type (_, _) eq = Eq : ('a, 'a) eq

let eq_type : type a b. a t -> b t -> (a, b) eq option =
 fun a b ->
  match (a, b) with
  | Const _, Const _ -> Some Eq
  | Var s1, Var s2 when s1 = s2 -> Some Eq
  | Const _, Var _ -> None
  | Var _, Const _ -> None
  | _ -> None (* Simplified for now, can be extended *)
