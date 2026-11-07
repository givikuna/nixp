package cst_types

TypedCondExpr :: struct {
	cond:        TypedExpr,
	then_branch: TypedExpr,
	else_branch: TypedExpr,
}
