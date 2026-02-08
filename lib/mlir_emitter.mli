(** MLIR code generator.

    This module translates symbolic discretization schemes into textual MLIR (Multi-Level Intermediate Representation)
    code, targeting the [arith] and [math] dialects. This enables compilation to high-performance machine code via LLVM.
*)

open Discretize

(** Emission context holding the state of the code generation (buffers, variable counters). *)
type context

(** [create_context ()] initializes a fresh emission context. *)
val create_context : unit -> context

(** [emit_scheme_step ctx name scheme] generates an MLIR function representing a single simulation step.

    The generated function signature will be:
    [func @name(%state_vars..., %dt, %dw_vars...) -> f64]

    Currently, it returns the first component of the state vector (MVP limitation).

    @param ctx The emission context.
    @param name The name of the generated MLIR function.
    @param scheme The discretization scheme to compile.
*)
val emit_scheme_step : context -> string -> scheme -> unit

(** [get_mlir ctx] retrieves the complete generated MLIR code as a string. *)
val get_mlir : context -> string