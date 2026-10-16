package parser_types

import lexer_types "../../lexer/types"

Expr :: union {
	^LiteralExpr,
	^IdentifierExpr,
	^ListExpr,
	^AttrsExpr,
	^LambdaExpr,
	^CallExpr,
	^LetExpr,
	^CondExpr,
	^PExpr,
}

LiteralExpr :: struct {
	token: lexer_types.LiteralToken,
}

IdentifierExpr :: struct {
	token: lexer_types.IdentifierToken,
}

ListExpr :: struct {
	elements: [dynamic]Expr,
}

AttrsExpr :: struct {
	bindings: [dynamic]AttrBinding,
	is_rec:   bool,
}

AttrBinding :: struct {
	key:   Expr,
	value: Expr,
}

LambdaExpr :: struct {
	params:       Expr,
	body:         Expr,
	name_binding: string, // @args
}

CallExpr :: struct {
	func: Expr,
	arg:  Expr,
}

LetExpr :: struct {
	bindings: [dynamic]LetBinding,
	body:     Expr,
	is_star:  bool,
}

LetBinding :: struct {
	name: string,
	expr: Expr,
}

CondExpr :: struct {
	cond:        Expr,
	then_branch: Expr,
	else_branch: Expr,
}

PExpr :: struct {
	path: Expr,
}
