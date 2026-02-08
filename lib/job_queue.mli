(** Job queue management using Redis. *)

open Server_logic

(** Unique identifier for a job. *)
type job_id = string [@@deriving yojson]

(** Status of a job. *)
type status =
  | Queued
  | Running
  | Completed of string (** Path to result file *)
  | Failed of string (** Error message *)
[@@deriving yojson]

(** A job wrapper containing the ID and the request. *)
type job = {
  id : job_id;
  request : simulate_request;
} [@@deriving yojson]

(** [create_connection host port] creates a Redis connection pool. *)
val create_connection : string -> int -> unit Lwt.t

(** [enqueue_job req] pushes a new job to the queue and returns its ID. *)
val enqueue_job : simulate_request -> job_id Lwt.t

(** [dequeue_job ()] blocks until a job is available and returns it. *)
val dequeue_job : unit -> job Lwt.t

(** [update_status id status] updates the status of a job. *)
val update_status : job_id -> status -> unit Lwt.t

(** [get_status id] retrieves the status of a job. *)
val get_status : job_id -> status Lwt.t
