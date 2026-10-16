package lexer_types

import constant_enums "../../constants/enums"

OperatorToken :: struct {
	op:     constant_enums.NixOperator,
	line:   int,
	column: int,
}
