package cst_parser

import lexer_types "../../../lexer/types"
import cst_types "../../types/cst"

CSTParserState :: struct {
	tokens: []lexer_types.TokenWithPos,
	pos:    int,
}

init_cst :: proc(tokens: []lexer_types.TokenWithPos) -> CSTParserState {
	return CSTParserState{tokens = tokens, pos = 0}
}

parse_expr :: proc(p: ^CSTParserState, allocator := context.allocator) -> cst_types.TypedExpr {
	tok := peek_cst(p)

	#partial switch t in tok {
	case lexer_types.LiteralToken:
		advance_cst(p)
		lit := new(cst_types.TypedLiteralExpr, allocator)
		lit^ = cst_types.TypedLiteralExpr {
			token = t,
		}
		return lit
	case lexer_types.IdentifierToken:
		advance_cst(p)
		ident := new(cst_types.TypedIdentifierExpr, allocator)
		ident^ = cst_types.TypedIdentifierExpr {
			token = t,
		}
		return ident
	case lexer_types.OperatorToken:
		advance_cst(p)
		ident := new(cst_types.TypedIdentifierExpr, allocator)
		ident.token = lexer_types.IdentifierToken {
			name   = fmt.tprint(t.op),
			line   = t.line,
			column = t.column,
		}
		return ident
	case lexer_types.PunctuationToken:
		if t.kind == .LParen {
			advance_cst(p)
			expr := parse_form(p, allocator)
			if r, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && r.kind == .RParen {
				advance_cst(p)
			}
			return expr
		}
	case lexer_types.KeywordToken:
		// standalone kw
		advance_cst(p)
	}

	// Skip illegal/EOF fallback
	advance_cst(p)
	return nil
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

// parsing functions

@(private)
parse_cond_form :: proc(
	p: ^CSTParserState,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	cond := new(cst_types.TypedCondExpr, allocator)
	cond.cond = parse_expr(p, allocator)
	cond.then_branch = parse_expr(p, allocator)
	cond.else_branch = parse_expr(p, allocator)

	return cond
}

@(private)
parse_deftype_form :: proc(
	p: ^CSTParserState,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	deftype := new(cst_types.DeftypeExpr, allocator)

	if ident, ok := peek_cst(p).(lexer_types.IdentifierToken); ok {
		deftype.name = ident.name
		advance_cst(p)
	}

	deftype.type = parse_type_elem(p, allocator)

	return deftype
}

@(private)
parse_let_form :: proc(
	p: ^CSTParserState,
	is_star: bool,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	let_expr := new(cst_types.TypedLetExpr, allocator)
	let_expr.is_star = is_star
	let_expr.bindings = make([dynamic]cst_types.TypedBinding, allocator)

	if punct, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && punct.kind == .LParen {
		advance_cst(p)
		for {
			if p_tok, ok := peek_cst(p).(lexer_types.PunctuationToken);
			   ok && p_tok.kind == .RParen {
				advance_cst(p)
				break
			}
			if _, eof := peek_cst(p).(lexer_types.EOFToken); eof do break

			append(&let_expr.bindings, parse_binding(p, allocator))
		}
	}

	let_expr.body = parse_expr(p, allocator)
	return let_expr
}

@(private)
parse_binding :: proc(
	p: ^CSTParserState,
	allocator := context.allocator,
) -> cst_types.TypedBinding {
	binding := cst_types.TypedBinding{}
	binding.keys = make([dynamic]cst_types.TypedExpr, allocator)

	if punct, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && punct.kind == .LBracket {
		advance_cst(p)

		has_inner_bracket := false
		if inner_punct, ok := peek_cst(p).(lexer_types.PunctuationToken);
		   ok && inner_punct.kind == .LBracket {
			advance_cst(p)
			has_inner_bracket = true
		}

		for {
			key_expr := parse_expr(p, allocator)

			if key_expr != nil do append(&binding.keys, key_expr)

			if pt, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && pt.kind == .Dot {
				advance_cst(p)
			} else do break
		}

		if op, ok := peek_cst(p).(lexer_types.OperatorToken); ok && op.op == .Annotate {
			advance_cst(p)
			binding.type_expr = parse_type_elem(p, allocator)
		}

		if has_inner_bracket {
			if c, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && c.kind == .RBracket {
				advance_cst(p)
			}
		}

		binding.value = parse_expr(p, allocator)

		if c, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && c.kind == .RBracket {
			advance_cst(p)
		}
	}

	return binding
}
@(private)
parse_attrs_form :: proc(
	p: ^CSTParserState,
	is_rec: bool,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	attrs := new(cst_types.TypedAttrsExpr, allocator)
	attrs.is_rec = is_rec
	attrs.bindings = make([dynamic]cst_types.TypedBinding, allocator)

	if punct, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && punct.kind == .LParen {
		advance_cst(p)

		for {
			if p_tok, ok := peek_cst(p).(lexer_types.PunctuationToken);
			   ok && p_tok.kind == .RParen {
				advance_cst(p)
				break
			}

			if _, eof := peek_cst(p).(lexer_types.EOFToken); eof do break

			append(&attrs.bindings, parse_binding(p, allocator))
		}
	}

	return attrs
}

@(private)
parse_type_elem :: proc(p: ^CSTParserState, allocator := context.allocator) -> cst_types.TypeElem {
	tok := peek_cst(p)

	#partial switch t in tok {
	case lexer_types.IdentifierToken:
		advance_cst(p)

		ident := new(cst_types.TypeIdent, allocator)
		ident.name = t.name

		return ident

	case lexer_types.PunctuationToken:
		if t.kind == .Question {
			advance_cst(p)

			opt := new(cst_types.TypeOptional, allocator)
			opt.inner = parse_type_elem(p, allocator)

			return opt
		}
		if t.kind == .LParen {
			advance_cst(p)

			inner := parse_type_elem(p, allocator)

			for {
				if r, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && r.kind == .RParen {
					advance_cst(p)
					break
				}

				if _, eof := peek_cst(p).(lexer_types.EOFToken); eof do break
				advance_cst(p)
			}

			return inner
		}
	}

	advance_cst(p)

	return nil
}

@(private)
parse_lambda_form :: proc(
	p: ^CSTParserState,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	lambda := new(cst_types.TypedLambdaExpr, allocator)
	lambda.params = make([dynamic]cst_types.TypedLambdaParam, allocator)

	if ident, ok := peek_cst(p).(lexer_types.IdentifierToken); ok {
		advance_cst(p)
		append(&lambda.params, cst_types.TypedLambdaParam{name = ident.name})
	} else do advance_cst(p)


	if op, ok := peek_cst(p).(lexer_types.OperatorToken); ok && op.op == .Annotate {
		advance_cst(p)
		lambda.return_type = parse_type_elem(p, allocator)
	}

	lambda.body = parse_expr(p, allocator)

	return lambda
}

@(private)
parse_call_form :: proc(
	p: ^CSTParserState,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	call := new(cst_types.TypedCallExpr, allocator)
	call.func = parse_expr(p, allocator)
	call.args = make([dynamic]cst_types.TypedExpr, allocator)

	for {
		if p_token, ok := peek_cst(p).(lexer_types.PunctuationToken);
		   ok && p_token.kind == .RParen {
			break
		}
		if _, eof := peek_cst(p).(lexer_types.EOFToken); eof do break

		append(&call.args, parse_expr(p, allocator))
	}

	return call
}

@(private)
parse_declare_form :: proc(
	p: ^CSTParserState,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	dec := new(cst_types.TypedDecExpr, allocator)

	if ident, ok := peek_cst(p).(lexer_types.IdentifierToken); ok {
		dec.name = ident.name
		advance_cst(p)
	}

	if op, ok := peek_cst(p).(lexer_types.OperatorToken); ok && op.op == .Annotate {
		advance_cst(p)
	}

	dec.type = parse_type_elem(p, allocator)

	return dec
}

@(private)
parse_as_form :: proc(p: ^CSTParserState, allocator := context.allocator) -> cst_types.TypedExpr {
	as_expr := new(cst_types.TypedAsExpr, allocator)
	as_expr.type = parse_type_elem(p, allocator)
	as_expr.expr = parse_expr(p, allocator)

	return as_expr
}

@(private)
parse_list_form :: proc(
	p: ^CSTParserState,
	allocator := context.allocator,
) -> cst_types.TypedExpr {
	list_expr := new(cst_types.TypedListExpr, allocator)
	list_expr.elements = make([dynamic]cst_types.TypedExpr, allocator)

	for {
		if p_tok, ok := peek_cst(p).(lexer_types.PunctuationToken); ok && p_tok.kind == .RParen {
			break
		}

		if _, eof := peek_cst(p).(lexer_types.EOFToken); eof do break

		append(&list_expr.elements, parse_expr(p, allocator))
	}

	return list_expr
}

@(private)
parse_p_form :: proc(p: ^CSTParserState, allocator := context.allocator) -> cst_types.TypedExpr {
	p_expr := new(cst_types.TypedPExpr, allocator)
	p_expr.path = parse_expr(p, allocator)

	return p_expr
}

@(private)
parse_form :: proc(p: ^CSTParserState, allocator := context.allocator) -> cst_types.TypedExpr {
	tok := peek_cst(p)

	#partial switch t in tok {
	case lexer_types.KeywordToken:
		advance_cst(p)

		#partial switch t.keyword {
		case .Attrs:
			return parse_attrs_form(p, false, allocator)
		case .Attrs_Rec:
			return parse_attrs_form(p, true, allocator)
		case .Let:
			return parse_let_form(p, false, allocator)
		case .Let_Star:
			return parse_let_form(p, true, allocator)
		case .Lambda:
			return parse_lambda_form(p, allocator)
		case .Cond:
			return parse_cond_form(p, allocator)
		case .Deftype:
			return parse_deftype_form(p, allocator)
		case .Declare:
			return parse_declare_form(p, allocator)
		case .As:
			return parse_as_form(p, allocator)
		case .List:
			return parse_list_form(p, allocator)
		case .P:
			return parse_p_form(p, allocator)
		}
	}

	return parse_call_form(p, allocator)
}
