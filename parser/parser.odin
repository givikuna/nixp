package parser

import constant_enums "../constants/enums"
import lexer_types "../lexer/types"
import parser_types "./types"

Parser :: struct {
	tokens: []lexer_types.TokenWithPos,
	pos:    int,
}

init :: proc(tokens: []lexer_types.TokenWithPos) -> Parser {
	return Parser{tokens = tokens, pos = 0}
}

@(private)
peek :: proc(p: ^Parser) -> lexer_types.Token {
	if p.pos >= len(p.tokens) {
		return lexer_types.EOFToken{}
	}

	return p.tokens[p.pos].token
}

@(private)
advance :: proc(p: ^Parser) -> lexer_types.Token {
	if p.pos >= len(p.tokens) {
		return lexer_types.EOFToken{}
	}

	tok := p.tokens[p.pos].token
	p.pos += 1

	return tok
}

prs_expr :: proc(p: ^Parser, allocator := context.allocator) -> parser_types.Expr {
	tok := peek(p)

	switch t in tok {
	case lexer_types.LiteralToken:
		advance(p)

		lit := new(parser_types.LiteralExpr, allocator)
		lit^ = parser_types.LiteralExpr {
			token = t,
		}

		return lit

	case lexer_types.IdentifierToken:
		advance(p)

		ident := new(parser_types.IdentifierExpr, allocator)
		ident^ = parser_types.IdentifierExpr {
			token = t,
		}

		return ident

	case lexer_types.PunctuationToken:
		if t.kind == .LParen {
			advance(p)
			expr := prs_form(p, allocator)
			if r, ok := peek(p).(lexer_types.PunctuationToken); ok && r.kind == .RParen {
				advance(p)
			}
			return expr
		}

	case lexer_types.KeywordToken:
		advance(p)

	case lexer_types.OperatorToken, lexer_types.EOFToken, lexer_types.IllegalToken:
		advance(p)
	}

	return nil
}

@(private)
prs_form :: proc(p: ^Parser, allocator := context.allocator) -> parser_types.Expr {
	tok := peek(p)

	if kw_tok, ok := tok.(lexer_types.KeywordToken); ok {
		advance(p)
		#partial switch kw_tok.keyword {
		case .Attrs, .Attrs_Rec:
			is_rec := kw_tok.keyword == .Attrs_Rec
			return prs_attrs_form(p, is_rec, allocator)
		case .List:
			return prs_list_form(p, allocator)
		case .Lambda:
			return prs_lambda_form(p, allocator)
		case .Let, .Let_Star:
			is_star := kw_tok.keyword == .Let_Star
			return prs_let_form(p, is_star, allocator)
		case .Cond:
			return prs_cond_form(p, allocator)
		case .P:
			return prs_p_form(p, allocator)
		case:
			return nil
		}
	}

	func_expr := prs_expr(p, allocator)
	arg_expr := prs_expr(p, allocator)

	call := new(parser_types.CallExpr, allocator)
	call^ = parser_types.CallExpr {
		func = func_expr,
		arg  = arg_expr,
	}

	return call
}

@(private)
prs_list_form :: proc(p: ^Parser, allocator := context.allocator) -> parser_types.Expr {
	list_expr := new(parser_types.ListExpr, allocator)
	list_expr^ = parser_types.ListExpr {
		elements = make([dynamic]parser_types.Expr, allocator),
	}

	for {
		if _, is_rp := peek(p).(lexer_types.PunctuationToken); is_rp {
			break
		}

		if _, is_eof := peek(p).(lexer_types.EOFToken); is_eof {
			break
		}

		append(&list_expr.elements, prs_expr(p, allocator))
	}

	return list_expr
}

@(private)
prs_attrs_form :: proc(
	p: ^Parser,
	is_rec: bool,
	allocator := context.allocator,
) -> parser_types.Expr {
	//

	attrs := new(parser_types.AttrsExpr, allocator)
	attrs^ = parser_types.AttrsExpr {
		bindings = make([dynamic]parser_types.AttrBinding, allocator),
		is_rec   = is_rec,
	}

	if punct, ok := peek(p).(lexer_types.PunctuationToken); ok && punct.kind == .LParen {
		advance(p)
		for {
			if p_tok, ok := peek(p).(lexer_types.PunctuationToken); ok && p_tok.kind == .RParen {
				advance(p)
				break
			}

			if _, ok := peek(p).(lexer_types.EOFToken); ok {
				break
			}

			if b_open, ok := peek(p).(lexer_types.PunctuationToken);
			   ok && b_open.kind == .LBracket {
				advance(p)
				k := prs_expr(p, allocator)
				v := prs_expr(p, allocator)
				if b_close, ok := peek(p).(lexer_types.PunctuationToken);
				   ok && b_close.kind == .RBracket {
					advance(p)
				}
				append(&attrs.bindings, parser_types.AttrBinding{key = k, value = v})
			} else {
				advance(p)
			}
		}
	}
	return attrs
}

@(private)
prs_lambda_form :: proc(p: ^Parser, allocator := context.allocator) -> parser_types.Expr {
	lambda := new(parser_types.LambdaExpr, allocator)

	lambda.params = prs_expr(p, allocator)
	lambda.body = prs_expr(p, allocator)

	return lambda
}

@(private)
prs_let_form :: proc(
	p: ^Parser,
	is_star: bool,
	allocator := context.allocator,
) -> parser_types.Expr {
	//

	let_expr := new(parser_types.LetExpr, allocator)

	let_expr.is_star = is_star
	let_expr.bindings = make([dynamic]parser_types.LetBinding, allocator)

	if punct, ok := peek(p).(lexer_types.PunctuationToken); ok && punct.kind == .LParen {
		advance(p)
		for {
			if p_tok, ok := peek(p).(lexer_types.PunctuationToken); ok && p_tok.kind == .RParen {
				advance(p)
				break
			}

			if _, ok := peek(p).(lexer_types.EOFToken); ok {
				break
			}

			if b_open, ok := peek(p).(lexer_types.PunctuationToken);
			   ok && b_open.kind == .LBracket {
				advance(p)
				if ident, ok := peek(p).(lexer_types.IdentifierToken); ok {
					advance(p)
					name := ident.name
					val := prs_expr(p, allocator)
					append(&let_expr.bindings, parser_types.LetBinding{name = name, expr = val})
				}
				if b_close, ok := peek(p).(lexer_types.PunctuationToken);
				   ok && b_close.kind == .RBracket {
					advance(p)
				}
			} else {
				advance(p)
			}
		}
	}

	let_expr.body = prs_expr(p, allocator)

	return let_expr
}

@(private)
prs_cond_form :: proc(p: ^Parser, allocator := context.allocator) -> parser_types.Expr {
	cond := new(parser_types.CondExpr, allocator)

	cond.cond = prs_expr(p, allocator)
	cond.then_branch = prs_expr(p, allocator)
	cond.else_branch = prs_expr(p, allocator)

	return cond
}

@(private)
prs_p_form :: proc(p: ^Parser, allocator := context.allocator) -> parser_types.Expr {
	p_expr := new(parser_types.PExpr, allocator)
	p_expr.path = prs_expr(p, allocator)

	return p_expr
}
