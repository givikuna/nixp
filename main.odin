package main

import "core:fmt"
import "core:os"
import lexer "lexer/src"

main :: proc() {
	data, err := os.read_entire_file("examples/flake/flake.nixp", context.allocator)
	if err != nil {
		fmt.eprintln("i failed:", err)
		return
	}
	defer delete(data)

	tokens := lexer.tokenize_all(string(data))
	defer delete(tokens)

	for t in tokens {
		fmt.println(t)
	}
}
