let parse_scalar s =
  let lexbuf = Lexing.from_string s in
  Parser.main Lexer.token lexbuf
