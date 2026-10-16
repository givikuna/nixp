package enums

NixOperator :: enum {
	Invalid,

	// Arithmetic
	Add, // +
	Sub, // -
	Mul, // *
	Div, // /

	// List
	Concat, // ++

	// Attrset
	Update, // //

	// Comparison
	Eq, // ==
	Neq, // !=
	Lt, // <
	Lte, // <=
	Gt, // >
	Gte, // >=

	// Logic
	And, // &&
	Or, // ||
	Not, // !
	Implies, // =>

	// Pipe
	Pipe, // |>

	TypeArrow, // ->
	Annotate, // ::     (type annotation)
}
