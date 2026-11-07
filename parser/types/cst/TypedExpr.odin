package cst_types

TypedExpr :: union {
	^TypedLiteralExpr,
	^TypedIdentifierExpr,
	^TypedListExpr,
	^TypedAttrsExpr,
	^TypedLambdaExpr,
	^TypedCallExpr,
	^TypedLetExpr,
	^TypedCondExpr,
	^TypedPExpr,

	//
	^TypedAsExpr,
	^DeftypeExpr,
	^TypedDecExpr,
}
