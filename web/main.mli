(** Main entry point for the SITO web frontend.

    This module initializes the [js_of_ocaml] application, setting up the DOM event listeners
    and binding the simulation logic to the UI elements using [Brr].
*)

(** [init ()] initializes the web application.
    It constructs the UI (input fields, buttons) and attaches the simulation handler to the button click.
*)
val init : unit -> unit