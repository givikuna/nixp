package lexer_types

import constant_enums "../../constants/enums"

KeywordToken :: struct {
	keyword: constant_enums.NixpKeyword,
	line:    int,
}
