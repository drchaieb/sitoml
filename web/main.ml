open Brr
open Sito_core

let simulate () =
  let doc = G.document in
  let get_val id =
    match Document.find_el_by_id doc (Jstr.v id) with
    | Some el -> El.prop El.Prop.value el |> Jstr.to_string
    | None -> ""
  in
  let drift = get_val "drift" in
  let diffusion = get_val "diffusion" in
  let s0 = float_of_string (get_val "s0") in
  let n_steps = int_of_string (get_val "n_steps") in
  let dt = float_of_string (get_val "dt") in

  let req = Server_logic.{
    drift;
    diffusion;
    initial_state = [("S", s0)];
    n_steps;
    dt;
    n_paths = 1;
  } in
  
  let res = Server_logic.handle_simulate req in
  let path = List.hd res.paths in
  let out = Document.find_el_by_id doc (Jstr.v "output") |> Option.get in
  El.set_children out [El.txt (Jstr.v (String.concat ", " (List.map string_of_float path)))]

let init () =
  let doc = G.document in
  let body = Document.body doc in
  let h1 = El.h1 [El.txt (Jstr.v "SITO: Symbolic Ito Simulator")] in
  
  let input_div = El.div [
    El.txt (Jstr.v "Drift: "); El.input ~at:At.[id (Jstr.v "drift"); value (Jstr.v "0.05 * S")] ();
    El.br ();
    El.txt (Jstr.v "Diffusion: "); El.input ~at:At.[id (Jstr.v "diffusion"); value (Jstr.v "0.2 * S")] ();
    El.br ();
    El.txt (Jstr.v "S0: "); El.input ~at:At.[id (Jstr.v "s0"); value (Jstr.v "100")] ();
    El.br ();
    El.txt (Jstr.v "Steps: "); El.input ~at:At.[id (Jstr.v "n_steps"); value (Jstr.v "100")] ();
    El.br ();
    El.txt (Jstr.v "dt: "); El.input ~at:At.[id (Jstr.v "dt"); value (Jstr.v "0.01")] ();
  ] in
  
  let btn = El.button [El.txt (Jstr.v "Simulate")] in
  let out_div = El.div ~at:At.[id (Jstr.v "output")] [] in
  
  ignore (Ev.listen Ev.click (fun _ -> simulate ()) (El.as_target btn));
  
  El.set_children body [h1; input_div; btn; out_div]

let () = init ()
