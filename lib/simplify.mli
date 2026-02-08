(** Symbolic expression simplifier.

    This module implements an algebraic simplification engine. It reduces the size and complexity
    of expression trees using standard identities and constant folding.
*)

open Expr

(** [simplify expr] recursively applies algebraic simplification rules to [expr].

    Optimizations include:
    - Identity operations: [x + 0 -> x], [x * 1 -> x], [x ^ 1 -> x].
    - Annihilators: [x * 0 -> 0], [0 / x -> 0].
    - Constant folding: [Const a + Const b -> Const (a + b)].
    - cancellation: [x - x -> 0], [x / x -> 1].
    - Associativity/Distribution adjustments (limited scope).
    - Trigonometric identities (e.g., [sin(0) -> 0]).

    This function should be called after operations like differentiation or Ito's lemma application
    to keep the resulting expressions manageable.

    @param expr The expression to simplify.
    @return A simplified, semantically equivalent expression.
*)
val simplify : 'a t -> 'a t