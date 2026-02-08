(** Symbolic differentiation engine.

    This module provides functionality to compute exact symbolic derivatives of expressions.
    It operates recursively on the AST defined in {!Expr}.
*)

open Expr

(** [deriv expr var] computes the partial derivative of [expr] with respect to the variable named [var].

    The differentiation rules implemented include:
    - Sum/Difference rules: d(u +/- v) = du +/- dv
    - Product rule: d(u*v) = u'v + uv'
    - Quotient rule: d(u/v) = (u'v - uv') / v^2
    - Chain rule for standard functions (sin, cos, exp, log, pow).
    - Element-wise differentiation for vectors and matrices.

    @param expr The expression to differentiate.
    @param var The name of the variable to differentiate with respect to.
    @return A new expression representing the derivative.
*)
val deriv : 'a t -> string -> 'a t