package cst_types

// the as expr as a CST type

TypedAsExpr :: struct {
	type: TypeElem,
	expr: TypedExpr,
}
