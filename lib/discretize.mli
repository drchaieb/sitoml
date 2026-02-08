(** Numerical discretization engine.

    This module transforms continuous-time SDEs into discrete-time recurrence equations suitable
    for Monte Carlo simulation. It supports various strong schemes.
*)

open Expr
open Stochastic

(** A discretized numerical scheme representing the transition X_n -> X_next. *)
type scheme = {
  next_state : vector t;
      (** Vector of expressions calculating X_next based on X_n, delta_t, and delta_W. *)
  state_vars : string list;
      (** Names of the state variables. *)
  delta_t : scalar t;
      (** Expression representing the time step size. *)
  delta_w : vector t;
      (** Expression representing the Wiener increment vector. *)
}

(** [euler_maruyama proc dt dw] generates the Euler-Maruyama scheme (Strong Order 0.5).

    X_next = X_n + a(X_n)dt + b(X_n)dW_n

    @param proc The stochastic process.
    @param dt Expression for the time step.
    @param dw Expression for the Wiener increment vector.
    @return The recurrence scheme.
*)
val euler_maruyama : process -> scalar t -> vector t -> scheme

(** [milstein proc dt dw] generates the Milstein scheme (Strong Order 1.0).

    X_next = X_n + a*dt + b*dW + 0.5*b*b'*(dW^2 - dt)

    Note: Currently supports 1D noise (scalar Wiener process) only.

    @param proc The stochastic process.
    @param dt Expression for the time step.
    @param dw Expression for the Wiener increment vector.
    @return The recurrence scheme.
*)
val milstein : process -> scalar t -> vector t -> scheme