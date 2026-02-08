open Sito_core
open Server_logic

let simulate_handler domain_mgr request =
  let%lwt body = Dream.body request in
  match Yojson.Safe.from_string body |> simulate_request_of_yojson with
  | Error msg -> Dream.json ~status:`Bad_Request (Printf.sprintf {|{"error": "%s"}|} msg)
  | Ok req ->
      let response = handle_simulate ~domain_mgr req in
      let json = simulate_response_to_yojson response |> Yojson.Safe.to_string in
      Dream.json json

let run ?(port = 8080) () =
  Eio_main.run @@ fun env ->
  let domain_mgr = Eio.Stdenv.domain_mgr env in
  Dream.run ~port
  @@ Dream.logger
  @@ Dream.router [
    Dream.post "/api/v1/simulate" (simulate_handler domain_mgr);
    Dream.get "/**" (Dream.static "web");
  ]

let () = run ()