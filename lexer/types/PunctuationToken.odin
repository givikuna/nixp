package lexer_types

Punctuation :: enum {
	LParen,
	RParen,
	LBracket,
	RBracket,
	LBrace,
	RBrace,
	Semicolon,
	Comma,
	Dot,
	Colon,
	DoubleColon,
	At,
	Question,
	Ellipsis,
}

PunctuationToken :: struct {
	kind:   Punctuation,
	line:   int,
	column: int,
}
