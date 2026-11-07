package ast_types

LetExpr :: struct {
	bindings: [dynamic]LetBinding,
	body:     Expr,
	is_star:  bool,
}
