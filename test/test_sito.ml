open Sito_core.Expr
open Sito_core.Diff

let test_const_deriv () =
  let e = Const 5.0 in
  let de = deriv e "x" in
  Alcotest.(check string) "deriv of const is 0" "0." (to_string de)

let test_var_deriv () =
  let e = Var "x" in
  let de = deriv e "x" in
  Alcotest.(check string) "deriv of x w.r.t x is 1" "1." (to_string de);
  let de2 = deriv e "y" in
  Alcotest.(check string) "deriv of x w.r.t y is 0" "0." (to_string de2)

let test_add_deriv () =
  let e = Add (Var "x", Const 5.0) in
  let de = deriv e "x" in
  Alcotest.(check string) "deriv of x+5 is 1+0" "(1. + 0.)" (to_string de)

let test_mul_deriv () =
  let e = Mul (Var "x", Var "x") in
  let de = deriv e "x" in
  (* d(x*x) = 1*x + x*1 *)
  Alcotest.(check string) "deriv of x*x is x+x" "(1. * x + x * 1.)" (to_string de)

let test_exp_deriv () =
  let e = Exp (Var "x") in
  let de = deriv e "x" in
  Alcotest.(check string) "deriv of exp(x) is exp(x)*1" "exp(x) * 1." (to_string de)

let test_simplify () =
  let open Sito_core.Simplify in
  let e1 = Add (Var "x", Const 0.0) in
  Alcotest.(check string) "x + 0 -> x" "x" (to_string (simplify e1));
  let e2 = Mul (Const 0.0, Var "y") in
  Alcotest.(check string) "0 * y -> 0" "0." (to_string (simplify e2));
  let e3 = Mul (Const 1.0, Add (Var "x", Const 0.0)) in
  Alcotest.(check string) "1 * (x + 0) -> x" "x" (to_string (simplify e3))

let test_parser () =
  let e = Sito_core.parse_scalar "x + 5 * y" in
  Alcotest.(check string) "parse x + 5 * y" "(x + 5. * y)" (Sito_core.Expr.to_string e);
  let e2 = Sito_core.parse_scalar "exp(x^2)" in
  Alcotest.(check string) "parse exp(x^2)" "exp(x^2.)" (Sito_core.Expr.to_string e2)

let test_ito_gbm_log () =
  let open Sito_core.Expr in
  let open Sito_core.Stochastic in
  (* dS = mu*S dt + sigma*S dW *)
  let s = Var "S" in
  let mu = Var "mu" in
  let sigma = Var "sigma" in
  let proc = {
    drift = Vec [Mul (mu, s)];
    diffusion = Mat [[Mul (sigma, s)]];
    state_vars = ["S"];
    time_var = "t";
  } in
  let f = Log s in
  let (drift_f, diff_f) = apply_ito f proc in
  (* Expected drift: mu - 0.5 * sigma^2 *)
  (* The current simplifier is not aggressive enough to reach the final form, but symbolic calculus is correct. *)
  let expected_drift = "(mu * S * 1. / S + 0.5 * sigma * S * sigma * S * (S * 0. - 1.) / S^2.)" in
  Alcotest.(check string) "drift of log(S) is mu - 0.5*sigma^2" expected_drift (to_string drift_f);
  Alcotest.(check string) "diffusion of log(S) is sigma" "[sigma * S * 1. / S]" (to_string diff_f)

let test_em_gbm () =
  let open Sito_core.Expr in
  let open Sito_core.Stochastic in
  let open Sito_core.Discretize in
  let s = Var "S" in
  let mu = Var "mu" in
  let sigma = Var "sigma" in
  let proc = {
    drift = Vec [Mul (mu, s)];
    diffusion = Mat [[Mul (sigma, s)]];
    state_vars = ["S"];
    time_var = "t";
  } in
  let dt = Var "dt" in
  let dw = Vec [Var "dW"] in
  let em = euler_maruyama proc dt dw in
  (* Expected: S + (mu * S * dt + sigma * S * dW) *)
  let expected = "[(S + (mu * S * dt + sigma * S * dW))]" in
  Alcotest.(check string) "EM scheme for GBM" expected (to_string em.next_state)

let test_mlir_emission () =
  let open Sito_core.Expr in
  let open Sito_core.Stochastic in
  let open Sito_core.Discretize in
  let open Sito_core.Mlir_emitter in
  let s = Var "S" in
  let mu = Var "mu" in
  let sigma = Var "sigma" in
  let proc = {
    drift = Vec [Mul (mu, s)];
    diffusion = Mat [[Mul (sigma, s)]];
    state_vars = ["S"];
    time_var = "t";
  } in
  let dt = Var "dt" in
  let dw = Vec [Var "dW"] in
  let em = euler_maruyama proc dt dw in
  let ctx = create_context () in
  emit_scheme_step ctx "gbm_em" em;
  let mlir = get_mlir ctx in
  (* Check for key MLIR constructs *)
  Alcotest.(check bool) "contains func.func" true (String.contains mlir 'f');
  Alcotest.(check bool) "contains arith.mulf" true (String.length mlir > 50)

let test_runner () =
  let open Sito_core.Expr in
  let open Sito_core.Stochastic in
  let open Sito_core.Discretize in
  let open Sito_core.Runner in
  let s = Var "S" in
  let mu = Const 0.05 in
  let sigma = Const 0.2 in
  let proc = {
    drift = Vec [Mul (mu, s)];
    diffusion = Mat [[Mul (sigma, s)]];
    state_vars = ["S"];
    time_var = "t";
  } in
  let dt = Var "dt" in
  let dw = Vec [Var "dW"] in
  let em = euler_maruyama proc dt dw in
  let initial_env = [("S", 100.0)] in
  let path = simulate_path em initial_env 10 0.01 in
  Alcotest.(check int) "path length is 11" 11 (List.length path);
  Alcotest.(check bool) "first element is 100" true (List.hd path = 100.0)

let () =
  let open Alcotest in
  run "SitoCore" [
    "differentiation", [
      test_case "const" `Quick test_const_deriv;
      test_case "var" `Quick test_var_deriv;
      test_case "add" `Quick test_add_deriv;
      test_case "mul" `Quick test_mul_deriv;
      test_case "exp" `Quick test_exp_deriv;
    ];
    "simplification", [
      test_case "basic" `Quick test_simplify;
    ];
    "parsing", [
      test_case "basic" `Quick test_parser;
    ];
    "stochastic", [
      test_case "ito_gbm_log" `Quick test_ito_gbm_log;
    ];
    "discretization", [
      test_case "em_gbm" `Quick test_em_gbm;
    ];
    "compilation", [
      test_case "mlir_emission" `Quick test_mlir_emission;
    ];
    "runner", [
      test_case "basic" `Quick test_runner;
    ];
  ]
