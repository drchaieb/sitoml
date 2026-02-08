open Sito_core.Server_logic

let test_handle_simulate () =
  let req = {
    drift = "0.05 * S";
    diffusion = "0.2 * S";
    initial_state = [("S", 100.0)];
    n_steps = 5;
    dt = 0.01;
    n_paths = 2;
  } in
  let res = handle_simulate req in
  Alcotest.(check int) "has 2 paths" 2 (List.length res.paths);
  List.iter (fun path -> 
    Alcotest.(check int) "path length is 6" 6 (List.length path)
  ) res.paths

let test_handle_simulate_parallel () =
  Eio_main.run @@ fun env ->
  let domain_mgr = Eio.Stdenv.domain_mgr env in
  let req = {
    drift = "0.05 * S";
    diffusion = "0.2 * S";
    initial_state = [("S", 100.0)];
    n_steps = 5;
    dt = 0.01;
    n_paths = 10;
  } in
  let res = handle_simulate ~domain_mgr req in
  Alcotest.(check int) "has 10 paths" 10 (List.length res.paths)

let () =
  let open Alcotest in
  run "SitoServer" [
    "logic", [
      test_case "handle_simulate" `Quick test_handle_simulate;
      test_case "handle_simulate_parallel" `Quick test_handle_simulate_parallel;
    ];
  ]
