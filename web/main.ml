open Brr
open Brr_io

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

  let req = {|{
    "drift": "|} ^ drift ^ {|",
    "diffusion": "|} ^ diffusion ^ {|",
    "initial_state": [["S", |} ^ string_of_float s0 ^ {|]],
    "n_steps": |} ^ string_of_int n_steps ^ {|,
    "dt": |} ^ string_of_float dt ^ {|,
    "n_paths": 1
  }|} in
  
  let url = Jstr.v "/api/v1/simulate" in
  let init = Fetch.Request.init ~method':(Jstr.v "POST") ~body:(Fetch.Body.of_jstr (Jstr.v req)) () in
  let fut = Fetch.url url ~init in
  
  Fut.await fut @@ function
  | Error e -> Console.(log [Jstr.v "Fetch error: "; e])
  | Ok response ->
      let body_fut = Fetch.Response.as_body response |> Fetch.Body.json in
      Fut.await body_fut @@ function
      | Error e -> Console.(log [Jstr.v "JSON error: "; e])
      | Ok json ->
          let job_id = Jv.get json "job_id" |> Jv.to_jstr in
          let out = Document.find_el_by_id doc (Jstr.v "output") |> Option.get in
          El.set_children out [El.txt (Jstr.v "Job submitted! ID: "); El.txt job_id]

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
