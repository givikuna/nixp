package cst_types

TypedLambdaParam :: struct {
	name:          string,
	type_expr:     TypeElem,
	has_default:   bool,
	default_value: TypedExpr,
}

TypedLambdaExpr :: struct {
	params:        [dynamic]TypedLambdaParam,
	return_type:   TypeElem,
	body:          TypedExpr,
	args_bindings: string,
}
