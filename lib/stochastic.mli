(** Stochastic calculus engine.

    This module implements the core operators of Ito Calculus, enabling the automated derivation
    of stochastic dynamics. It handles both drift (L^0) and diffusion (L^j) operators.
*)

open Expr

(** Represents an N-dimensional Ito process: dX_t = a(t, X_t)dt + b(t, X_t)dW_t. *)
type process = {
  drift : vector t;
      (** The drift vector 'a' (N x 1). *)
  diffusion : matrix t;
      (** The diffusion matrix 'b' (N x M), where M is the dimension of the Wiener process. *)
  state_vars : string list;
      (** List of variable names representing the state vector X_t components. *)
  time_var : string;
      (** The variable name representing time 't'. *)
}

(** [l_j f proc j] applies the noise/diffusion operator L^j to a scalar function [f].

    Mathematically: L^j = sum_k b_[k,j] * d/dx_k

    @param f The scalar function to operate on.
    @param proc The stochastic process defining the coefficients.
    @param j The index of the Wiener process component (0-based column index of diffusion matrix).
    @return The resulting scalar expression.
*)
val l_j : scalar t -> process -> int -> scalar t

(** [l_0 f proc] applies the deterministic/drift operator L^0 to a scalar function [f].

    Mathematically: L^0 = d/dt + sum_k a_k * d/dx_k + 0.5 * sum_[k,l] (bb^T)_[k,l] * d^2/dx_k dx_l

    This operator includes the Ito correction term involving the Hessian of [f].

    @param f The scalar function to operate on.
    @param proc The stochastic process defining the coefficients.
    @return The resulting scalar expression.
*)
val l_0 : scalar t -> process -> scalar t

(** [apply_ito f proc] derives the dynamics of the transformed process Y_t = f(t, X_t).

    It applies Ito's Lemma to return the new drift and diffusion coefficients for Y_t.
    dY_t = L^0 f dt + sum_j L^j f dW_t^j

    @param f The transformation function.
    @param proc The original stochastic process X_t.
    @return A pair [(new_drift, new_diffusion_row)] representing the dynamics of Y_t.
*)
val apply_ito : scalar t -> process -> scalar t * vector t