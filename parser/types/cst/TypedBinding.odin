package cst_types

TypedBinding :: struct {
	keys:      [dynamic]TypedExpr,
	type_expr: TypeElem,
	value:     TypedExpr,
}
