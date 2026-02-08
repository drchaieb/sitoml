{
open Parser
}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let id = alpha (alpha | digit | '_')*
let whitespace = [' ' '	' '
' '']+

rule token = parse
| whitespace { token lexbuf }
| "(" { LPAREN }
| ")" { RPAREN }
| "+" { PLUS }
| "-" { MINUS }
| "*" { TIMES }
| "/" { DIVIDE }
| "^" { POW }
| "exp" { EXP }
| "log" { LOG }
| "sin" { SIN }
| "cos" { COS }
| digit+ ('.' digit*)? as f { FLOAT (float_of_string f) }
| id as s { ID s }
| eof { EOF }
