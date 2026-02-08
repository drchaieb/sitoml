(** The SITO REST API server entry point.

    This module configures and starts the [Dream] web server, setting up the routes and the
    [Eio] main loop for handling concurrent simulation requests.
*)

(** [run ~port ()] starts the server on the specified port (default 8080).
    It initializes the Eio environment and blocks until the server is stopped.
*)
val run : ?port:int -> unit -> unit