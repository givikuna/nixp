package type_checker

import cst_types "../../parser/types/cst"

check_types :: proc(cst: cst_types.TypedExpr) -> bool {
	if cst == nil {
		return false
	}

	// this is a dummy

	return true
}
