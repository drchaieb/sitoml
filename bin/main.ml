open Sito_core
open Server_logic
open Job_queue

let simulate_handler request =
  let%lwt body = Dream.body request in
  match Yojson.Safe.from_string body |> simulate_request_of_yojson with
  | Error msg -> Dream.json ~status:`Bad_Request (Printf.sprintf {|{"error": "%s"}|} msg)
  | Ok req ->
      let%lwt job_id = enqueue_job req in
      Dream.json (Printf.sprintf {|{"job_id": "%s", "status": "queued"}|} job_id)

let status_handler job_id _ =
  try%lwt
    let%lwt status = get_status job_id in
    let json = status_to_yojson status |> Yojson.Safe.to_string in
    Dream.json json
  with _ -> Dream.json ~status:`Not_Found {|{"error": "Job not found"}|}

let run ?(port = 8080) () =
  let redis_host = Sys.getenv_opt "REDIS_HOST" |> Option.value ~default:"127.0.0.1" in
  let redis_port = Sys.getenv_opt "REDIS_PORT" |> Option.map int_of_string |> Option.value ~default:6379 in
  Lwt_main.run (
    let%lwt () = create_connection redis_host redis_port in
    Dream.serve ~port
    @@ Dream.logger
    @@ Dream.router [
      Dream.post "/api/v1/simulate" simulate_handler;
      Dream.get "/api/v1/jobs/:id" (fun req -> status_handler (Dream.param req "id") req);
      Dream.get "/**" (Dream.static "web");
    ]
  )

let () = run ()
