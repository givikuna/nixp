package ast_types

CondExpr :: struct {
	cond:        Expr,
	then_branch: Expr,
	else_branch: Expr,
}
