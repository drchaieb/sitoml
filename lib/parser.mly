%{
open Expr
%}

%token <float> FLOAT
%token <string> ID
%token PLUS MINUS TIMES DIVIDE POW
%token LPAREN RPAREN
%token EXP LOG SIN COS
%token EOF

%left PLUS MINUS
%left TIMES DIVIDE
%right POW
%nonassoc UMINUS

%start <Expr.scalar Expr.t> main
%%

main:
| e = expr EOF { e }

expr:
| f = FLOAT { Const f }
| s = ID { Var s }
| e1 = expr PLUS e2 = expr { Add (e1, e2) }
| e1 = expr MINUS e2 = expr { Sub (e1, e2) }
| e1 = expr TIMES e2 = expr { Mul (e1, e2) }
| e1 = expr DIVIDE e2 = expr { Div (e1, e2) }
| e1 = expr POW e2 = expr { Pow (e1, e2) }
| EXP LPAREN e = expr RPAREN { Exp e }
| LOG LPAREN e = expr RPAREN { Log e }
| SIN LPAREN e = expr RPAREN { Sin e }
| COS LPAREN e = expr RPAREN { Cos e }
| LPAREN e = expr RPAREN { e }
| MINUS e = expr %prec UMINUS { Sub (Const 0.0, e) }
%%
