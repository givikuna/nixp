package ast_parser

import lexer_types "../../../lexer/types"
import ast_types "../../types/ast"
import cst_types "../../types/cst"

parse_to_ast :: proc(cst: cst_types.TypedExpr, allocator := context.allocator) -> ast_types.Expr {
	if cst == nil {
		return nil
	}

	#partial switch node in cst {
	case ^cst_types.TypedLiteralExpr:
		ast_node := new(ast_types.LiteralExpr, allocator)
		ast_node.token = node.token

		return ast_node

	case ^cst_types.TypedIdentifierExpr:
		ast_node := new(ast_types.IdentifierExpr, allocator)
		ast_node.token = node.token

		return ast_node

	case ^cst_types.TypedListExpr:
		ast_node := new(ast_types.ListExpr, allocator)
		ast_node.elements = make([dynamic]ast_types.Expr, 0, len(node.elements), allocator)

		for el in node.elements {
			if parsed := parse_to_ast(el, allocator); parsed != nil {
				append(&ast_node.elements, parsed)
			}
		}

		return ast_node

	case ^cst_types.TypedAttrsExpr:
		ast_node := new(ast_types.AttrsExpr, allocator)
		ast_node.is_rec = node.is_rec
		ast_node.bindings = make([dynamic]ast_types.AttrBinding, 0, len(node.bindings), allocator)

		for b in node.bindings {
			keys_ast := make([dynamic]ast_types.Expr, 0, len(b.keys), allocator)

			for k in b.keys do append(&keys_ast, parse_to_ast(k, allocator))

			append(
				&ast_node.bindings,
				ast_types.AttrBinding{keys = keys_ast, value = parse_to_ast(b.value, allocator)},
			)
		}

		return ast_node

	case ^cst_types.TypedLambdaExpr:
		ast_node := new(ast_types.LambdaExpr, allocator)
		ast_node.params = make([dynamic]ast_types.LambdaParam, 0, len(node.params), allocator)

		for p in node.params {
			param := ast_types.LambdaParam {
				name        = p.name,
				has_default = p.has_default,
			}

			if p.has_default {
				param.default_value = parse_to_ast(p.default_value, allocator)
			}

			append(&ast_node.params, param)
		}

		ast_node.name_binding = node.args_bindings
		ast_node.body = parse_to_ast(node.body, allocator)

		return ast_node

	case ^cst_types.TypedCallExpr:
		if len(node.args) == 0 do return parse_to_ast(node.func, allocator)

		cur_expr := parse_to_ast(node.func, allocator)

		for arg in node.args {
			next_call := new(ast_types.CallExpr, allocator)
			next_call.func = cur_expr
			next_call.arg = parse_to_ast(arg, allocator)
			cur_expr = next_call
		}

		return cur_expr

	case ^cst_types.TypedLetExpr:
		ast_node := new(ast_types.LetExpr, allocator)
		ast_node.is_star = node.is_star
		ast_node.bindings = make([dynamic]ast_types.LetBinding, 0, len(node.bindings), allocator)

		for b in node.bindings {
			keys_ast := make([dynamic]ast_types.Expr, 0, len(b.keys), allocator)

			for k in b.keys do append(&keys_ast, parse_to_ast(k, allocator))

			append(
				&ast_node.bindings,
				ast_types.LetBinding{keys = keys_ast, expr = parse_to_ast(b.value, allocator)},
			)
		}

		ast_node.body = parse_to_ast(node.body, allocator)

		return ast_node

	case ^cst_types.TypedCondExpr:
		ast_node := new(ast_types.CondExpr, allocator)
		ast_node.cond = parse_to_ast(node.cond, allocator)
		ast_node.then_branch = parse_to_ast(node.then_branch, allocator)
		ast_node.else_branch = parse_to_ast(node.else_branch, allocator)

		return ast_node

	case ^cst_types.TypedPExpr:
		ast_node := new(ast_types.PExpr, allocator)
		ast_node.path = parse_to_ast(node.path, allocator)

		return ast_node

	case ^cst_types.TypedAsExpr:
		return parse_to_ast(node.expr, allocator)

	case ^cst_types.DeftypeExpr, ^cst_types.TypedDecExpr:
		return nil
	}

	return nil
}
