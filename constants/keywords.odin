package constants

import enums "./enums"

NIX_KEYWORDS :: [?]string{"if", "then", "else", "in", "let", "with", "assert", "or", "rec"}

NIXP_KEYWORDS :: [enums.NixpKeyword]string {
	.Invalid       = "",

	// core
	.List          = "list",
	.Attrs         = "attrs",
	.Attrs_Rec     = "attrs-rec",
	.Elem          = "elem",
	.Inherit       = "inherit",
	.Inherit_Attrs = "inherit-attrs",
	.Lambda        = "lambda",
	.Cond          = "cond",
	.Not           = "not",
	.True          = "true",
	.False         = "false",
	.Assert        = "assert",
	.With          = "with",
	.Let           = "let",
	.Let_Star      = "let*",
	.Import        = "import",
	.Or            = "or",

	// paths
	.P             = "p",

	// types
	.Deftype       = "deftype",
	.Struct        = "struct",
	.Union         = "Union",
	.Intersect     = "Intersect",
	.As            = "as",
	.Declare       = "declare",
}

lookup_nixp_keyword :: proc(ident: string) -> enums.NixpKeyword {
	for kw_str, kw_enum in NIXP_KEYWORDS {
		if kw_enum != .Invalid && kw_str == ident {
			return kw_enum
		}
	}
	return .Invalid
}
