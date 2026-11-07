# Architecture

This file is the `Architecture` docs for `Nixp`.

For any unknown words check out `./Glossary.md`.

`Nixp` is a typed frontend for `Nix`.
A `.nixp` file is lexed into tokens, parsed into a `typed CST`, type checked, and then lowered to an `AST`, then transpiled to `Nix AST` and to `Nix` code.

## Lexer (nixp -> tokens)

The `lexer/` directory has two subdirectories that are packages.
`types/` (`lexer_types`) are the token definitions.
`src/` (`lexer`) is the actual lexer algorithm

## Parser (tokens -> CST -> AST)

### CST

In the `parser/types/cst/` directory we have the `cst_types` package with CST node definitions.
`TypedExpr` is the root union.

In the `parser/src/cst/` directory we have the `cst_parser` package which parses the tokens into a CST.

### AST

In the `parser/types/ast/` directory we have the `ast_types` package with AST node definitions.

In the `parser/src/ast/` directory we have `ast_parser` package that parses the CST into an AST (essentially Type Removal)

## Type Checker (CST -> AST)

TO-DO

## Transpiler

TO-DO

### AST -> AST

TO-DO

### AST -> Code

TO-DO
