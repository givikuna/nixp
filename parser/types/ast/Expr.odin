package ast_types

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
