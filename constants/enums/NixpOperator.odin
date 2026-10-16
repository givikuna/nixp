package enums

NixOperator :: enum {
	Invalid,

	// arithmetic
	Add, // +
	Sub, // -
	Mul, // *
	Div, // /

	// list
	Concat, // ++

	// attrset
	Update, // //

	// comparison
	Eq, // ==
	Neq, // !=
	Lt, // <
	Lte, // <=
	Gt, // >
	Gte, // >=

	// logic
	And, // &&
	Or, // ||
	Implies, // =>

	// pipe
	Pipe, // |>

	// types
	TypeArrow, // ->
	Annotate, // ::
}
