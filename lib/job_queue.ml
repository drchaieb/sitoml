open Server_logic
open Redis_lwt

type job_id = string [@@deriving yojson]

type status =
  | Queued
  | Running
  | Completed of string
  | Failed of string
[@@deriving yojson]

type job = {
  id : job_id;
  request : simulate_request;
} [@@deriving yojson]

let conn = ref None

let get_conn () =
  match !conn with
  | Some c -> c
  | None -> failwith "Redis connection not initialized"

let create_connection host port =
  let spec = { Client.host = host; port = port } in
  let%lwt c = Client.connect spec in
  conn := Some c;
  Lwt.return_unit

let job_queue_key = "sito:jobs"
let job_key_prefix = "sito:job:"

let enqueue_job req =
  let id = string_of_float (Unix.time ()) ^ "-" ^ string_of_int (Random.int 10000) in
  let job = { id; request = req } in
  let job_json = job_to_yojson job |> Yojson.Safe.to_string in
  let status_json = status_to_yojson Queued |> Yojson.Safe.to_string in
  
  let c = get_conn () in
  let%lwt _ = Client.set c (job_key_prefix ^ id) status_json in
  let%lwt _ = Client.rpush c job_queue_key [job_json] in
  Lwt.return id

let dequeue_job () =
  let c = get_conn () in
  match%lwt Client.blpop c [job_queue_key] 0 with
  | Some (_, job_json) ->
      (match Yojson.Safe.from_string job_json |> job_of_yojson with
      | Ok job -> Lwt.return job
      | Error e -> Lwt.fail_with ("Failed to parse job: " ^ e))
  | None -> Lwt.fail_with "No job received"

let update_status id status =
  let c = get_conn () in
  let status_json = status_to_yojson status |> Yojson.Safe.to_string in
  let%lwt _ = Client.set c (job_key_prefix ^ id) status_json in
  Lwt.return_unit

let get_status id =
  let c = get_conn () in
  match%lwt Client.get c (job_key_prefix ^ id) with
  | Some json ->
      (match Yojson.Safe.from_string json |> status_of_yojson with
      | Ok s -> Lwt.return s
      | Error e -> Lwt.fail_with ("Failed to parse status: " ^ e))
  | None -> Lwt.fail_with "Job not found"