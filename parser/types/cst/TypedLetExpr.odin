package cst_types

TypedLetExpr :: struct {
	bindings: [dynamic]TypedBinding,
	body:     TypedExpr,
	is_star:  bool,
}
