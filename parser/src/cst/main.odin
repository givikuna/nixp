package cst_parser

import lexer_types "../../../lexer/types"
import cst_types "../types/cst"

CSTParserState :: struct {
	tokens: []lexer_types.TokenWithPos,
	pos:    int,
}

init_cst :: proc(tokens: []lexer_types.TokenWithPos) -> CSTParserState {
	return CSTParserState{tokens = tokens, pos = 0}
}

@(private)
peek_cst :: proc(p: ^CSTParserState) -> lexer_types.Token {
	if p.pos >= len(p.tokens) do return lexer_types.EOFToken{}

	return p.tokens[p.pos].token
}

@(private)
advance_cst :: proc(p: ^CST_Parser) -> lexer_types.Token {
	if p.pos >= len(p.tokens) do return lexer_types.EOFToken{}

	m_token = p.tokens[p.pos].token

	p.pos += 1

	return m_token
}
