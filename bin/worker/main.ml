open Sito_core
open Server_logic
open Job_queue
open Lwt

let result_dir = "/data/results"

let process_job job =
  let%lwt () = update_status job.id Running in
  
  (* Run simulation in Eio domain *)
  let response = handle_simulate job.request in
  
  (* Write result to file *)
  let filename = Filename.concat result_dir (job.id ^ ".json") in
  let json = simulate_response_to_yojson response |> Yojson.Safe.to_string in
  let ch = open_out filename in
  output_string ch json;
  close_out ch;
  
  update_status job.id (Completed filename)

let rec worker_loop () =
  try%lwt
    let%lwt job = dequeue_job () in
    let%lwt () = process_job job in
    worker_loop ()
  with e ->
    Printf.eprintf "Worker error: %s\n%!" (Printexc.to_string e);
    Lwt_unix.sleep 1.0 >>= worker_loop

let run () =
  let redis_host = Sys.getenv_opt "REDIS_HOST" |> Option.value ~default:"127.0.0.1" in
  let redis_port = Sys.getenv_opt "REDIS_PORT" |> Option.map int_of_string |> Option.value ~default:6379 in
  if not (Sys.file_exists result_dir) then (
    try Unix.mkdir result_dir 0o755 with _ -> ()
  );
  Lwt_main.run (
    let%lwt () = create_connection redis_host redis_port in
    Printf.printf "Worker started. Connected to Redis at %s:%d\n%!" redis_host redis_port;
    worker_loop ()
  )

let () = run ()