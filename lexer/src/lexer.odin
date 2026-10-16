package lexer

import "../../constants"
import constant_enums "../../constants/enums"

import lexer_types "../types"

Lexer :: struct {
	source: string,
	pos:    int,
	line:   int,
	col:    int,
}

init :: proc(source: string) -> Lexer {
	return Lexer{source = source, pos = 0, line = 1, col = 1}
}

tokenize_all :: proc(
	source: string,
	allocator := context.allocator,
) -> [dynamic]lexer_types.TokenWithPos {
	lexer_obj := init(source)

	tokens := make([dynamic]lexer_types.TokenWithPos, allocator)

	for {
		tok := next_token(&lexer_obj)
		append(&tokens, tok)
		if _, is_eof := tok.token.(lexer_types.EOFToken); is_eof {
			break
		}
	}

	return tokens
}

// helpers


@(private)
peek :: proc(l: ^Lexer, look_ahead := 0) -> u8 {
	if l.pos + look_ahead >= len(l.source) {
		return 0
	}

	return l.source[l.pos + look_ahead]
}

@(private)
advance :: proc(l: ^Lexer) -> u8 {
	if l.pos >= len(l.source) {
		return 0
	}

	ch := l.source[l.pos]
	l.pos += 1

	if ch == '\n' {
		l.line += 1
		l.col = 1
	} else {
		l.col += 1
	}

	return ch
}

@(private)
skip_whitespace_and_comments :: proc(l: ^Lexer) {
	for l.pos < len(l.source) {
		ch := peek(l)

		if ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n' {
			advance(l)
			continue
		}

		if ch == ';' {
			for l.pos < len(l.source) && peek(l) != '\n' {
				advance(l)
			}

			continue
		}

		if ch == '2' && peek(l, 1) == '|' {
			advance(l) // #
			advance(l) // |

			for l.pos < len(l.source) {
				if peek(l) == '|' && peek(l, 1) == '#' {
					advance(l) // |
					advance(l) // #
					break
				}
				advance(l)
			}

			continue
		}

		break
	}
}

next_token :: proc(l: ^Lexer) -> lexer_types.TokenWithPos {
	skip_whitespace_and_comments(l)

	start_pos := l.pos
	start_line := l.line
	start_col := l.col

	if l.pos >= len(l.source) {
		return lexer_types.TokenWithPos {
			token = lexer_types.EOFToken{line = start_line, column = start_col},
			offset = start_pos,
			length = 0,
		}
	}

	ch := peek(l)

	switch ch {
	case '(':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .LParen)
	case ')':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .RParen)
	case '[':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .LBracket)
	case ']':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .RBracket)
	case '{':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .LBrace)
	case '}':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .RBrace)
	case ',':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .Comma)
	case '@':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .At)
	case '?':
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .Question)
	}

	if ch == '$' && peek(l, 1) == '{' {
		advance(l)
		advance(l)
		return mk_punct(start_pos, 2, start_line, start_col, .DollarLBrace)
	}

	if ch == '.' {
		if peek(l, 1) == '.' && peek(l, 2) == '.' {
			advance(l)
			advance(l)
			advance(l)
			return mk_punct(start_pos, 3, start_line, start_col, .Ellipsis)
		}
		if is_digit(peek(l, 1)) {
			return lex_number(l, start_pos, start_line, start_col)
		}
		advance(l)
		return mk_punct(start_pos, 1, start_line, start_col, .Dot)
	}

	// : and ::
	if ch == ':' {
		advance(l)
		if peek(l) == ':' {
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Annotate)
		}
		return mk_punct(start_pos, 1, start_line, start_col, .Colon)
	}

	// strings
	if ch == '"' {
		return lex_string(l, start_pos, start_line, start_col)
	}
	if ch == '\'' && peek(l, 1) == '\'' {
		return lex_indented_string(l, start_pos, start_line, start_col)
	}

	// numbers
	if is_digit(ch) {
		return lex_number(l, start_pos, start_line, start_col)
	}

	// chars and operators
	switch ch {
	case '+':
		advance(l)
		if peek(l) == '+' {
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Concat)
		}
		return mk_op(start_pos, 1, start_line, start_col, .Add)
	case '-':
		advance(l)
		if peek(l) == '>' {
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .TypeArrow)
		}
		return mk_op(start_pos, 1, start_line, start_col, .Sub)
	case '*':
		advance(l)
		return mk_op(start_pos, 1, start_line, start_col, .Mul)
	case '/':
		advance(l)
		if peek(l) == '/' {
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Update)
		}
		return mk_op(start_pos, 1, start_line, start_col, .Div)
	case '=':
		if peek(l, 1) == '=' {
			advance(l)
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Eq)
		}
		if peek(l, 1) == '>' {
			advance(l)
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Implies)
		}
	case '!':
		if peek(l, 1) == '=' {
			advance(l)
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Neq)
		}
	case '<':
		advance(l)
		if peek(l) == '=' {
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Lte)
		}
		return mk_op(start_pos, 1, start_line, start_col, .Lt)
	case '>':
		advance(l)
		if peek(l) == '=' {
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Gte)
		}
		return mk_op(start_pos, 1, start_line, start_col, .Gt)
	case '&':
		if peek(l, 1) == '&' {
			advance(l)
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .And)
		}
	case '|':
		if peek(l, 1) == '|' {
			advance(l)
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Or)
		}
		if peek(l, 1) == '>' {
			advance(l)
			advance(l)
			return mk_op(start_pos, 2, start_line, start_col, .Pipe)
		}
	}

	// identifiers & keywords
	if is_ident_start(ch) {
		return lex_ident_or_keyword(l, start_pos, start_line, start_col)
	}

	// illegals
	advance(l)
	return lexer_types.TokenWithPos {
		token = lexer_types.IllegalToken {
			lexeme = l.source[start_pos:l.pos],
			line = start_line,
			column = start_col,
		},
		offset = start_pos,
		length = l.pos - start_pos,
	}
}

@(private)
lex_ident_or_keyword :: proc(
	l: ^Lexer,
	start_pos, start_line, start_col: int,
) -> lexer_types.TokenWithPos {
	for l.pos < len(l.source) && is_ident_continue(peek(l)) {
		advance(l)
	}
	// Special case for "let*"
	if l.source[start_pos:l.pos] == "let" && peek(l) == '*' {
		advance(l)
	}

	lexeme := l.source[start_pos:l.pos]
	length := l.pos - start_pos

	if kw := constants.lookup_nixp_keyword(lexeme); kw != .Invalid {
		return lexer_types.TokenWithPos {
			token = lexer_types.KeywordToken{keyword = kw, line = start_line, column = start_col},
			offset = start_pos,
			length = length,
		}
	}

	return lexer_types.TokenWithPos {
		token = lexer_types.IdentifierToken{name = lexeme, line = start_line, column = start_col},
		offset = start_pos,
		length = length,
	}
}

@(private)
lex_number :: proc(l: ^Lexer, start_pos, start_line, start_col: int) -> lexer_types.TokenWithPos {
	kind := lexer_types.LiteralKind.Int

	if peek(l) == '.' {
		kind = .Float
		advance(l)
	}

	for l.pos < len(l.source) && is_digit(peek(l)) {
		advance(l)
	}

	// Fractional part (only if followed by a digit, so `123.foo` doesn't eat `.`)
	if kind == .Int && peek(l) == '.' && is_digit(peek(l, 1)) {
		kind = .Float
		advance(l) // consume '.'
		for l.pos < len(l.source) && is_digit(peek(l)) {
			advance(l)
		}
	}

	// Exponent part: e or E
	if peek(l) == 'e' || peek(l) == 'E' {
		kind = .Float
		advance(l)
		if peek(l) == '+' || peek(l) == '-' {
			advance(l)
		}
		for l.pos < len(l.source) && is_digit(peek(l)) {
			advance(l)
		}
	}

	return lexer_types.TokenWithPos {
		token = lexer_types.LiteralToken {
			kind = kind,
			value = l.source[start_pos:l.pos],
			line = start_line,
			column = start_col,
		},
		offset = start_pos,
		length = l.pos - start_pos,
	}
}

@(private)
lex_string :: proc(l: ^Lexer, start_pos, start_line, start_col: int) -> lexer_types.TokenWithPos {
	advance(l) // opening '"'
	for l.pos < len(l.source) {
		ch := advance(l)
		if ch == '\\' && l.pos < len(l.source) {
			advance(l) // skip escaped character
			continue
		}
		if ch == '"' {
			break
		}
	}
	return lexer_types.TokenWithPos {
		token = lexer_types.LiteralToken {
			kind = .String,
			value = l.source[start_pos:l.pos],
			line = start_line,
			column = start_col,
		},
		offset = start_pos,
		length = l.pos - start_pos,
	}
}

@(private)
lex_indented_string :: proc(
	l: ^Lexer,
	start_pos, start_line, start_col: int,
) -> lexer_types.TokenWithPos {
	advance(l) // '
	advance(l) // '
	for l.pos < len(l.source) {
		if peek(l) == '\'' && peek(l, 1) == '\'' {
			// Check for escaped '' (''' or ''$ or ''\)
			if peek(l, 2) == '\'' || peek(l, 2) == '$' || peek(l, 2) == '\\' {
				advance(l)
				advance(l)
				advance(l)
				continue
			}
			advance(l)
			advance(l)
			break
		}
		advance(l)
	}
	return lexer_types.TokenWithPos {
		token = lexer_types.LiteralToken {
			kind = .Indented,
			value = l.source[start_pos:l.pos],
			line = start_line,
			column = start_col,
		},
		offset = start_pos,
		length = l.pos - start_pos,
	}
}

@(private)
is_digit :: proc(ch: u8) -> bool {
	return ch >= '0' && ch <= '9'
}

@(private)
is_ident_start :: proc(ch: u8) -> bool {
	return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

@(private)
is_ident_continue :: proc(ch: u8) -> bool {
	return is_ident_start(ch) || is_digit(ch) || ch == '-' || ch == '\''
}

@(private)
mk_punct :: proc(
	offset, length, line, col: int,
	kind: lexer_types.Punctuation,
) -> lexer_types.TokenWithPos {
	return lexer_types.TokenWithPos {
		token = lexer_types.PunctuationToken{kind = kind, line = line, column = col},
		offset = offset,
		length = length,
	}
}

@(private)
mk_op :: proc(
	offset, length, line, col: int,
	op: constant_enums.NixOperator,
) -> lexer_types.TokenWithPos {
	return lexer_types.TokenWithPos {
		token = lexer_types.OperatorToken{op = op, line = line, column = col},
		offset = offset,
		length = length,
	}
}
