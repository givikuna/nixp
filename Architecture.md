Nixp -> Token Array -> CST -> AST -> Nix AST -> Nix Code

CST -> AST transition does the type checking.

Lexer: Nixp -> Token Array
CST_Parser: Token Array -> CST
Type_Checker: CST -> Result<boolean>
AST_Parser: CST -> AST
AST_Translator: AST -> Nix AST
Nix_Unparser: Nix AST -> Nix Code
