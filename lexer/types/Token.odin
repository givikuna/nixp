package lexer_types

Token :: union {
	KeywordToken,
	LiteralToken,
	IdentifierToken,
	OperatorToken,
	PunctuationToken,
}

TokenWithPos :: struct {
	token:  Token,
	offset: int,
	length: int,
}
