(** SITO: Symbolic Ito Compiler (Core Library).

    This is the main entry point for the library, re-exporting the core modules for convenience.
*)

(** {1 Core Modules} *)

module Expr = Expr
(** Mathematical expression AST and types. *)

module Diff = Diff
(** Symbolic differentiation. *)

module Simplify = Simplify
(** Algebraic simplification. *)

module Stochastic = Stochastic
(** Ito Calculus operators. *)

module Discretize = Discretize
(** Numerical scheme generation. *)

module Mlir_emitter = Mlir_emitter
(** Code generation for MLIR. *)

module Runner = Runner
(** Simulation execution engine. *)

module Server_logic = Server_logic
(** Backend business logic. *)

module Job_queue = Job_queue
(** Redis job queue management. *)

module Parser_util = Parser_util
(** Parsing utilities. *)

(** {1 Convenience Functions} *)

(** [parse_scalar s] is an alias for [Parser_util.parse_scalar]. *)
val parse_scalar : string -> Expr.scalar Expr.t
