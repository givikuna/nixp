package ast_types

LambdaParam :: struct {
	name:          string,
	has_default:   bool,
	default_value: Expr,
}

LambdaExpr :: struct {
	params:       [dynamic]LambdaParam,
	body:         Expr,
	name_binding: string, // @args
}
