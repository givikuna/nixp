package lexer_types

LiteralKind :: enum {
	Int,
	Float,
	String, // " & ''
	Path,
	Uri,
	Indented,
}

LiteralToken :: struct {
	kind:   LiteralKind,
	value:  string, // raw slice
	line:   int,
	column: int,
}
