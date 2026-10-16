package constants

is_nix_keyword :: proc(name: string) -> bool {
	for kw in NIX_KEYWORDS {
		if kw == name do return true
	}
	return false
}

is_nixp_keyword :: proc(name: string) -> bool {
	return lookup_nixp_keyword(name) != .Invalid
}

is_builtin :: proc(name: string) -> bool {
	for b in BUILTINS {
		if b == name do return true
	}
	return false
}

is_nix_constant :: proc(name: string) -> bool {
	for c in NIX_CONSTANTS {
		if c == name do return true
	}
	return false
}

is_taken_name :: proc(name: string) -> bool {
	return(
		is_nixp_keyword(name) ||
		is_nix_keyword(name) ||
		is_nix_constant(name) ||
		is_builtin(name) \
	)
}
