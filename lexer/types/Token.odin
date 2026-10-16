package lexer_types

EOFToken :: struct {
	line:   int,
	column: int,
}

IllegalToken :: struct {
	lexeme: string,
	line:   int,
	column: int,
}

Token :: union {
	KeywordToken,
	LiteralToken,
	IdentifierToken,
	OperatorToken,
	PunctuationToken,
	EOFToken,
	IllegalToken,
}

TokenWithPos :: struct {
	token:  Token,
	offset: int,
	length: int,
}
