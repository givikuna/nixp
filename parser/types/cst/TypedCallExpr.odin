package cst_types

TypedCallExpr :: struct {
	func: TypedExpr,
	args: [dynamic]TypedExpr,
}
