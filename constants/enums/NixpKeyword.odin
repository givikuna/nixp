package enums

NixpKeyword :: enum {
	Invalid,

	// core
	List,
	Attrs,
	Attrs_Rec,
	Elem,
	Inherit,
	Inherit_Attrs,
	Lambda,
	Cond,
	Not,
	True,
	False,
	Assert,
	With,
	Let,
	Let_Star,
	Import,
	Or,

	// paths
	P,

	// types
	Deftype,
	Struct,
	Union,
	Intersect,
	As,
	Declare,
}
