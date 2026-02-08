(** Core mathematical expression GADT and associated types.

    This module defines the fundamental data structures for representing mathematical
    expressions in a type-safe manner using Generalized Algebraic Data Types (GADTs).
    It distinguishes between scalars, vectors, and matrices at the type level, preventing
    invalid mathematical operations (e.g., adding a scalar to a matrix) at compile time.
*)

(** {1 Type Definitions} *)

(** Phantom type representing a scalar value. *)
type scalar = Scalar

(** Phantom type representing a vector value. *)
type vector = Vector

(** Phantom type representing a matrix value. *)
type matrix = Matrix

(** The Generalized Algebraic Data Type (GADT) for expressions.
    The type parameter index indicates the mathematical kind of the expression
    ([scalar], [vector], or [matrix]).
*)
type _ t =
  | Const : float -> scalar t
      (** A constant floating-point value. *)
  | Var : string -> scalar t
      (** A named variable (e.g., "x", "t", "sigma"). *)
  | Add : 'a t * 'a t -> 'a t
      (** Element-wise addition of two expressions of the same kind. *)
  | Sub : 'a t * 'a t -> 'a t
      (** Element-wise subtraction of two expressions of the same kind. *)
  | Mul : scalar t * 'a t -> 'a t
      (** Scalar multiplication. Multiplies an expression of any kind by a scalar. *)
  | Div : 'a t * scalar t -> 'a t
      (** Scalar division. Divides an expression of any kind by a scalar. *)
  | Pow : scalar t * scalar t -> scalar t
      (** Power function (scalar only): [Pow(base, exponent)]. *)
  | Exp : scalar t -> scalar t
      (** Exponential function [exp(x)] (scalar only). *)
  | Log : scalar t -> scalar t
      (** Natural logarithm [log(x)] (scalar only). *)
  | Sin : scalar t -> scalar t
      (** Sine function [sin(x)] (scalar only). *)
  | Cos : scalar t -> scalar t
      (** Cosine function [cos(x)] (scalar only). *)
  | Vec : scalar t list -> vector t
      (** Construction of a vector from a list of scalar expressions. *)
  | Mat : scalar t list list -> matrix t
      (** Construction of a matrix from a list of rows (lists of scalars). *)
  | Dot : vector t * vector t -> scalar t
      (** Dot product of two vectors. *)
  | MatMul : matrix t * 'a t -> 'a t
      (** Matrix multiplication. Can multiply a matrix by a vector or another matrix. *)

(** {1 Construction Helpers} *)

(** [const f] creates a constant scalar expression from float [f]. *)
val const : float -> scalar t

(** [var s] creates a variable scalar expression with name [s]. *)
val var : string -> scalar t

(** [add a b] creates an addition expression [a + b]. *)
val add : 'a t -> 'a t -> 'a t

(** [sub a b] creates a subtraction expression [a - b]. *)
val sub : 'a t -> 'a t -> 'a t

(** [mul s a] creates a multiplication expression [s * a] where [s] is a scalar. *)
val mul : scalar t -> 'a t -> 'a t

(** [div a s] creates a division expression [a / s] where [s] is a scalar. *)
val div : 'a t -> scalar t -> 'a t

(** {1 Utilities} *)

(** [to_string expr] converts the expression [expr] to a human-readable string representation.
    Useful for debugging and display purposes.
*)
val to_string : 'a t -> string

(** [zero expr] returns a zero value representing the same shape/type as [expr].
    - For a scalar, returns [Const 0.0].
    - For a vector, returns a vector of zeros of the same length.
    - For a matrix, returns a matrix of zeros of the same dimensions.
*)
val zero : 'a t -> 'a t

(** {1 Type Equality} *)

(** A witness type for proving equality between two types. *)
type (_, _) eq = Eq : ('a, 'a) eq

(** [eq_type a b] attempts to prove that expressions [a] and [b] have the same type.
    Returns [Some Eq] if they do, or [None] otherwise.
    Note: This is a structural check on the AST nodes provided, primarily used for simplification logic.
*)
val eq_type : 'a t -> 'b t -> ('a, 'b) eq option