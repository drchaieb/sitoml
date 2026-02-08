open Expr

type context = {
  mutable next_var : int;
  mutable buffer : string list;
}

let create_context () = { next_var = 0; buffer = [] }

let emit ctx s = ctx.buffer <- s :: ctx.buffer

let fresh_var ctx =
  let v = "%v" ^ string_of_int ctx.next_var in
  ctx.next_var <- ctx.next_var + 1;
  v

let rec emit_expr : type a. context -> a t -> string =
 fun ctx e ->
  match e with
  | Const f ->
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = arith.constant %f : f64" v f);
      v
  | Var s -> "%" ^ s
  | Add (a, b) ->
      let va = emit_expr ctx a in
      let vb = emit_expr ctx b in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = arith.addf %s, %s : f64" v va vb);
      v
  | Sub (a, b) ->
      let va = emit_expr ctx a in
      let vb = emit_expr ctx b in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = arith.subf %s, %s : f64" v va vb);
      v
  | Mul (a, b) ->
      let va = emit_expr ctx a in
      let vb = emit_expr ctx b in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = arith.mulf %s, %s : f64" v va vb);
      v
  | Div (a, b) ->
      let va = emit_expr ctx a in
      let vb = emit_expr ctx b in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = arith.divf %s, %s : f64" v va vb);
      v
  | Pow (a, b) ->
      let va = emit_expr ctx a in
      let vb = emit_expr ctx b in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = math.powf %s, %s : f64" v va vb);
      v
  | Exp a ->
      let va = emit_expr ctx a in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = math.exp %s : f64" v va);
      v
  | Log a ->
      let va = emit_expr ctx a in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = math.log %s : f64" v va);
      v
  | Sin a ->
      let va = emit_expr ctx a in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = math.sin %s : f64" v va);
      v
  | Cos a ->
      let va = emit_expr ctx a in
      let v = fresh_var ctx in
      emit ctx (Printf.sprintf "  %s = math.cos %s : f64" v va);
      v
  | _ -> failwith "Unsupported expression type for MLIR emission"

let emit_scheme_step ctx name scheme =
  let args =
    List.map (fun s -> "%" ^ s ^ ": f64") (scheme.Discretize.state_vars) @
    [Printf.sprintf "%%dt: f64"] @
    (match scheme.delta_w with Vec vs -> List.map (fun v -> (match v with Var s -> "%" ^ s | _ -> "%dw") ^ ": f64") vs | _ -> [])
  in
  let arg_str = String.concat ", " args in
  emit ctx (Printf.sprintf "func.func @%s(%s) -> f64 {" name arg_str);
  let res_v = match scheme.next_state with Vec vs -> emit_expr ctx (List.hd vs) | _ -> failwith "Empty scheme" in
  emit ctx (Printf.sprintf "  return %s : f64" res_v);
  emit ctx "}"

let get_mlir ctx = String.concat "
" (List.rev ctx.buffer)
