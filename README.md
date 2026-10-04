# nixp

Alternative Nix frontend inspired by Lisp/Scheme.

Nixp serves as a separate programming language `.nixp` files that then compile down to pure `Nix`.

`Nixp` does provide a minimal type system as well, to make working with `nix` easier.

A large chunk of this document is a re-write of [The Nix Language Manual](https://nix.dev/manual/nix/2.25/language/types) for Nixp.

## Type System

`Nixp` has optional typing, and it relies entirely upon the standard `nix` type system.

### Integer

An _integer_ in the `nixp` language is the same as in `nix`.
It is a signed 64-bit integer.

None-negative integers can be expressed as integer literals.
Negative integers are created with the arithmetic negation operator.

The function `builtins.isInt` can be used to determine if a value is an integer.

### Float

This is a 64-bit IEEE-754 floating-point number.

The function `builtins.isFloat` can be used to determine if a value is a float.

### Boolean

A boolean in the `nixp` language is either `true` or `false`. Just as in `nix`.

These values are also available as attributes of `builtins` as `builtins.true` and `builtins.false`.
The function `builtins.isBool` can be used to determine if a value is a boolean.

### String

A `string` in the `nixp` language is an immutable, finite-length, sequence of bytes, along with a string context.
Again, just like in `nix` (this will not be stated from here on out because the whole point of `nixp` is to be a nice frontend, it provides nothing new to the functionality itself).

Nixp does not assume or support working natively with character encodings.
String values without string context can be expressed as string literals.

The function `builtins.isString` can be used to determine if a value is a string.

### Path

A `path` in the Nixp language is an immutable, finite-length sequence of bytes, starting with `/`, representing a POSIX-style, canonical file system path.

In Nixp they are usually passed in as strings to the `p` function for `paths`, which then returns the actual path type, in order to avoid conflicts with the nix language:

```Scheme
(p "/path/to/something")
```

Path values are distinct from string values, even if they contain the same sequence of bytes.
Operations that produce paths will simplify the result as the standard `C` function `realpath` would, except there is no symbolic link resolution.

Paths are suitable for referring to local files, and are often preferable over strings.

- Path values do not contain or duplicate slashes, `.`, or `..`.
- Relative path literals are automatically resolved relative to their base directory.

A file is not required to exist at a given path in order for that path value ot be valid, but a path that is converted to a string with string interpolation or string-and-path concatenation must resolve to a readable file or directory which can be copied into the Nix store.
FOr instance, evaluating `"${./foo.txt}"` will cause `foot.txt` from the same directory to be copied into the Nix store and result in the string `"/nix/store/<hash>-foo.txt`.
Operations such as `import` can also expect a path to resolve to a readable file or directory.

Path values can be expressed as path literals.
The function `builtins.isPath` can be used to determine if a value is a path.

### Null

There is a single value of type `null` in the Nix language.

This value is available as an attribute on the `builtins` attribute set as `builtins.null`.

### Compound Values

#### Attribute Set

An attribute set can be constructed with the `attrs` function (to be explained later).

The function `builtins.isAttrs` can be used to determine if a value is an attribute set.

#### List

A list can be constructed with the `list` function.

The function `builtins.isList` can be used to determine if a value is a list.

### Function

A function can be constructed with a function expression.

The function `builtins.isFunction` can be used to determine if a value is a function.

### External

An `external` value is an opaque value created by a Nix plugin.
Such a value can be substituted in Nix expressions but only created and used by plugin code.

## Language Constructs

### Basic Literals

#### String

There are multi multiple ways strings can be written in Nix. As well as in Nixp.

The double quote `"something"` is as simple as in any other language.

For multiline strings nix does:

```Nix
''
    Multi-line string
    Wow!
''
```

Nixp does the same:

```Clojure
''
    Multi-line string
    Wow!
''
```

#### Number

Numbers, which can be integers (like `123` or `67`) or floating points (like `67.69` or `.6e9`).

Integers in the NIx language are 64-bit two's complement signed integers, with a range of `-9223372036854775808` to `9223372036854775807`, inclusive.

Note that negative numeric literals are actually parsed as an unary negation of positive numeric literals.
This means that the minimum integer `-9223372036854775808` cannot be written as-is as a literal, since the positive number `9223372036854775808` is one past the maximum range.

#### Path

Paths can be expressed by strings passed into the `p` function such as:

```Scheme
(p "./builder.sh")
```

This `p` function will be transpiled to nix as a simple path literal: `./builder.sh`.

A path-string must contain at least one slash to be recognized as such.
For instance, `builder.sh` is not a path: it's parsed as an expression that selects the attribute `sh` from the variable `builder`.

Paths are resolved relative to their base directory.
Paths may also refer to the absolute paths by starting with a slash.

> Note
> Absolute paths make expressions less portable. In the case where a function translates a path literal into an absolute path string for a configuration file, it is recommended to write a string literal instead. This avoids some confusion about whether files at that location will be used during evaluation. It also avoids unintentional situations where some function might try to copy everything at the location into the store.

If the first component of a path is a `~` it is interpreted such that the rest of the path were relative to the user's home directory.

For example, `(p "~/foo")` would be equivalent to `(p "/home/edolstra/foo")` for a user whose home directory is `/home/edolstra`.

Path literals that start with `~` are not allowed in pure evaluation.

Paths can also include \[string interpolation\], besides being interpolated into other expressions.

At least one slash (`/`) must appear before any interpolated expression for the result to be recognized as a path.

Here we can highlight a very important aspect of a benefit of `nixp` over `nix`.

Consider:

```Scheme
(p "a.${foo}/b.${bar}")
```

In `nix`, this path would be written as follows:

```Nix
a.${foo}/b.${bar}
```

This would, however, be evaluated as a division of numbers instead of being seen as a path.
Instead you'd have to write:

```Nix
./a.${foo}/b.${bar}
```

For it to be seen as a path.

This is fine and makes sense.
However, in `nixp` since you define a path with the `p` function `(p "a.${foo}/b.${bar}")` is the same as `(p "./a.${foo}/b.${bar}")`.

Nixp will attach the `./` to the beginning if it isn't already there.
Making code feel more deliberate. In my eyes, deliberateness of code is very important to a programming language.

##### Lookup Paths

In nix a lookup path is something like `<nixpkgs>` which translates to an actual path.

This in my eyes is overloading symbols `<` `>` too much for a syntax.

In Nixp you create lookup paths by: `(p "<nixpkgs>")`.
Which also feels more deliberate, as explained above.

The only reason Nixp supports this feature is for compatibility.

Generally, `<nixpkgs>` is something that should be avoided in terms of syntax, as it is highly stateful.
Statefulness is counterproductive for full reproducibility.

#### List

In `Nixp` lists are formed by the `list` function.

Consider:

```Scheme
(list 67 (p "foo.nix") "abc")
```

This compiles to:

```Nix
[ 67 ./foo.nix "abc" ]
```

### Attribute Sets

An attribute set is a collection of name-value-pairs called attributes.

Consider:

```Clojure
(attrs ( [x    67]
         [txt "Hai"]))
```

This compiles to the following nix expression:

```Nix
{
    x = 67;
    text = "Hai";
}
```

#### Attribute Paths

In the `nix` language you can do the following:

```Nix
{ a.b.c = 1; a.b.d = 2; }
```

Which is equivalent to:

```Nix
{
    a = {
        b = {
            c = 1;
            d = 2;
        };
    };
}
```

This can also be done in `nixp`:

```Clojure
(attrs ( [a.b.c 1]
         [a.b.d 2] ))
```

This compiles to:

```Nix
{
    a.b.c = 1;
    a.b.d = 1;
}
```

You can also do nested attribute sets in `nixp` in a far cleaner manner:

```Clojure
(attrs ( [a.b (attrs ( [c 1]
                       [d 2] ))] ))
```

Which compiles to:

```Nix
{
    a.b = {
        c = 1;
        d = 2;
    }
}
```

#### Accessing Attribute Elements

In `nix` you can access attribute elements in many ways.

You can also do it in line.

Consider the following Nix code:

```Nix
{ a = "Foo"; b = "Bar"; }.a
```

This evaluates to `"Foo"`.

In `nixp` you can do a similar thing, but you must use the `elem` function:

```Clojure
(elem "a" (attrs ([a "Foo"] [b "Bar"])))
```

This'll compile to the following nix code:

```Nix
{ a = "Foo"; b = "Bar"; }."a"
```

Keep in mind, in any other scenario of needing to access an element of the attribute set, the standard `.` operator works.

#### Double-Quoted Strings as Attribute Names

In nix the `.` operator for attribute sets allows you to use arbitrary double-quoted strings as attribute names.

In nixp you can do the same, but you no longer require the `.` operator.

For accessing elements, since the `elem` function itself already takes a string, the accessing with strings is built-into nixp.

But nixp also allows you to use a string instead of a typical identifier for attribute names.

Consider:

```Clojure
(attrs (
    [a "Foo"]
    ["b" "Bar"]
))
```

This compiles to:

```Nix
{
    a = "Foo";
    "b" = "Bar";
}
```

This also allows for the string indicating the attribute name to be an expression that evaluates to a string, just as in nix.

Consider:

```Clojure
(attrs (
    [(cond true ("bar") ("foo")) true]
))
```

This compiles to:

```Nix
{
    ${if true then "bar" else "foo"} = true;
}
```

### Let Expressions

A `let`-expressions allows you to define local variables for an expression.

In `nix` it works as follows:

```Nix
let
    x = "foo";
    y = "bar";
in x + y
```

Nixp works in a similar way.

```Clojure
(let ([x "foo"] [y "bar"])
     (x + y))
```

However, nix always allows for `x` and `y` to use each other in definition.
For example:

```Nix
let
    x = "foo";
    y = x;
in x + y
```

Is valid nix code.

However:

```Clojure
(let ([x "foo"] [y x])
     (x + y))
```

Is invalid in nixp.

For this to be valid one must use the `let*` function instead.

```Clojure
(let* ([x "foo"] [y x])
      (x + y))
```

A this allows for elements being declared in one let to know of each others existence.

This gives a cleaner format to do computation.

#### Inheriting Attributes

When defining an attribute set in a let expression, it is convenient to copy variables from surrounding lexical scope (e.g., when you want to propagate attributes).
This can be shortened using the `inherit`.

For example, in nix the following is valid code:

```Nix
let x = 123; in
{
    inherit x;
    y = 456;
}
```

And it is equivalent to:

```Nix
let x = 123; in
{
    x = x;
    y = 456;
}
```

This can be done similarly in Nixp.

Consider:

```Clojure
(let ([x 123])
     (attrs (inherit x)
            ([y 456])))
```

Which compiles to:

```Nix
let x = 123; in
{
    inherit x;
    y = 456;
}
```

You can inherit multiple values in fact.

```Clojure
(let ([x 123] [z 67])
     (attrs (inherit x z)
            ([y 456])))
```

And this would compile to:

```Nix
let
    x = 123;
    z = 67;
in
{
    inherit x y;
    y = 456;
}
```

##### Inheriting Attributes from Attribute Sets

You can inherit attributes from other attribute sets as well.

Let the attribute set `src-set` exist as an attribute set containing attributes `a`, `b`, and `c`.

Then the following nixp expression stands true:

```Clojure
(let ([x 67] [y 69] [z 41])
     (attrs (inherit x y z)
            (inherit-attrs src-set a b c )))
```

This would then compile to the following Nix expression:

```Nix
let
    x = 67;
    y = 69;
    z = 41;
in
{
    inherit x y z;
    inherit (src-set) a b c;
}
```

### Functions

In the Nixp programming language, borrowing from Nix, functions can only take in one argument.
To achieve more, one must use currying.

Single parameter functions are defined in Nixp as follows:

(`not` is a function in nixp for negation, instead of using the standard `!` operator)

```Clojure
(let ([negate (lambda x (not x))])
     (cond (negate true)
           (+ "foo" "bar")
           ("not so foo-bar")))
```

This translates to:

```Nix
let negate = x: !x;
in if negate true then "foo" + "bar" else ""
```

#### Multi-Parameter Functions

You can also declare functions with multiple variables.
But this is done through currying.
Where a function takes in a variable and returns a function taking in another variable.

This can be done in two ways:

Firstly:

```Clojure
(lambda x (lambda y (+ x y)))
```

Which compiles to:

```Nix
x: y: x + y
```

Secondly:

```Clojure
(lambda ([x y]) (+ x y))
```

This also compiles to:

```Nix
x: y: x + y
```

This way, you can define multi-variable functions easily in Nixp.

##### Attribute Sets as Parameters

If you want more complex multi-variable functions you can use attribute sets.

For example in nix one can do:

```Nix
{x, y, z}: x + y + z
```

In Nixp you can do the following:

```Clojure
(lambda ({x y z}) (+ x y z))
```

Which compiles to a function identical to the one above in nix.

But you can do more.

###### Optional Arguments

In Nix one achieves optional arguments as follows:

```Nix
{
    x,
    y ? "foo",
    z ? "bar",
}: z + y + x
```

In Nixp one can achieve a similar system through a similar system:

```Clojure
(lambda ({x y z} ([y "foo"] [z "bar"]))
        (+ z y x))
```

Which compiles to the expression above.

###### Ellipsis Operator

To understand the next concepts, one must also understand the ellipsis operator.

I'll give an example in nix to explain this.

Consider:

```Nix
let
    fn = { name, age }: "Hello ${name} of ${age} years";
in fn { name = "Bobby Boy"; age = 41; city = "New York"; }
```

This will error, as Nix expects the attribute set to have only `name` and `age` attributes.

However, the `...` ellipsis in nix makes the attribute set permissive:

```Nix
let
    fn = { name, age, ... }: "Hello ${name} of ${age} years";
in fn { name = "Bobby Boy"; age = 41; city = "New York"; }
```

Now there will be no error and the code will execute as it must.

The same thing can be achieved in Nixp.

Consider:

```Clojure
(lambda ({x y z ...}) (+ z y x))
```

This will simply compile to:

```Nix
{x, y, z, ...}: x + y + z
```

###### Referencing Attribute Set Parameters

In Nix one can reference the attribute set passed in as a parameter and even give it an identifier of its own.

Consider the following nix code:

```Nix
args@{ x, y, z, ... }: z + y + x + args.a
```

This is the same exact thing as:

```Nix
{ x, y, z, ... } @ args: z + y + x + args.a
```

Here, `args` is bound to the argument as passed, which is further matched against the pattern `{ x, y, z, ... }`.
The `@`-pattern makes mainly sense with an ellipsis (`...`) as you can access attribute names without needing to define them directly.

> Note:
> `a` is an attribute on the `args` attribute set that isn't declared as a taken in parameter (or even required) by nix.

In Nixp one can get the same functionality as follows:

```Clojure
(lambda (@args) ({x y z ...}) (+ z y x args.a))
```

And with defaults:

```Clojure
(lambda (@args) ({x y z ...} ([y 67] [z 69]))
        (+ z y x args.a))
```

### Recursive Attribute Sets

In Nix one can achieve Recursive Attribute Sets with the `rec` keyword.

Recursive sets are like normal attribute sets, but the attributes can refer to each other.

An example of this in nix:

```Nix
rec {
    x = y;
    y = 123;
}.x
```

This evaluates to `123`.

Note that without `rec` the binding `x = y;` would refer to the variable `y` in the surrounding scope, if one exists, and would be invalid if no such variable exists.
That is, in a normal (non-recursive) set, attributes are nota added to the lexical scope; in a recursive set, they are.

These do introduce the danger of infinite recursion.

Thus, use them carefully.

In Nixp one can create recursive attribute sets the same way as typical attribute sets, but one uses the `attrs-rec` keyword instead.

```Clojure
(attrs-rec ( [x y]
         [y 67]))
```

This compiles to:

```Nix
rec {
    x = y;
    y = 67;
}
```

### Conditionals

This doc so far has used conditionals a couple of times.

In nix they look as follows:

```Nix
if e1 then e2 else e3
```

In Nixp they look as follows:

```Clojure
(cond e1 (e2) (e3))
```

### Assertions

Assertions are generally used to check that certain requirements on or between features and dependencies hold.
They look like this:

```Nix
assert e1; e2
```

Where `e1` is an expression that should evaluate to a Boolean value.
If it evaluates to `true`, `e2` is return; otherwise the expression evaluation is aborted and a backtrace is printed.

In Nixp, these are done just as simply:

```Clojure
(assert e1 e2)
```

### With Expressions

A with-expression resolves the namespace of an attribute set into the expression.

Consider:

```Nix
let as = { x = "foo"; y = "bar"; };
in with as; x + y
```

In Nixp, a similar syntax applies:

```Clojure
(let ([as (attrs ([x "foo"] [y "bar"]))])
     (with as (+ x y)))
```

This should compile to a an identical version of the Nix code above.

The with expression can also be done with an import statement:

Consider:

```Clojure
(with (import (p ./definitions.nix)) ())
```

### Comments

Single-line comments in Nixp are done with the `;` symbol.
Multi-line comments are done by: `#| ... |#`.

Comments are not compiles to the final nix output.

### Identifiers

In Nixp, identifiers have the same exact rules as Nix.

The only difference is, neither Nix or Nixp keywords can be used as identifiers instead of just Nix keywords.

### String Interpolation

In Nix one does string interpolation as:

```Nix
"something${1 + 2}"
```

Which becomes `"something3"`.

In Nixp the same exact syntax applies:

```Clojure
"something${+ 1 2}"
```

### Operators

Nixp shares most of its operators with Nix.

#### Attribute Selection

The attribute selection is the same as in Nix.

Let the attribute set `a` exist.
Then an attribute element `b` can be accessed in two ways:

```Clojure
(a.b)
```

Or

```Clojure
(elem "b" a)
```

#### The Or Keyword

In Nix one can use the `or` keyword to show that if a variable doesn't exist to evaluate to something else.
Consider:

```Nix
pkgs.openssl or null
```

IN Nixp one can do:

```Clojure
(or pkgs.openssl null)
```

#### Function Application

`func expr`

Simple.

#### Has Attribute

In nix the `?` gives an attribute a value of the attribute set doesn't give it one when an attribute set is passed into a function.
This is unnecessary in Nixp, as the lambda function automatically takes care of this.

#### Arithmetic

The `+`, `-`, `/`, `*` are standard.

`+` is overloaded for numbers, strings, and paths.

#### List Concatenation

The `++` operator can concatenate two lists together.

#### Logical Negation

In Nix one uses the `!` operator for negation.
In Nxp one uses the `not` function.

#### Update Attribute Set

In Nix one uses the `//` to update attribute sets.

Consider:

```Nix
a1 // a2
```

Here, we update the attribute set `a1` with names and values from `a2`

In Nixp one simply does:

```Clojure
(// a1 a2)
```

#### Comparison

The operators for comparisons are identical to Nix.

- Less than: `<`
- Less than or equal to: `<=`
- Greater than: `>`
- Greater than or equal to: `>=`
- Equality: `==`
- Inequality: `!=`

Consider:

```Clojure
(== 1 1)
```

Very simple.

#### Logical AND and OR

In Nix and in Nixp the operators for these are `&&` and `||` respectively.

#### Logical Implication

This is done in Nix via the `->` operator.

In Nixp this is done via the `=>` operator, as the `->` is reserved for the type system.

#### Operator Piping:

In nix one can do function piping as follows:

```Nix
1 |> builtins.add 2 |> builtins.mul 3
```

Or

```Nix
builtins.add 1 <| builtins.mul 2 <| 3
```

In Nixp the only way to do piping is via the `|>` operator.

Consider:

```Clojure
(|> 1
    (builtins.add 2)
    (builtins.mul 3))
```

### Derivations

The Nix programming language uses the `derivation` keyword.
This is vital for using `Nix` as a package manager.

It is used to describe a single derivation: a specification for running an executable on precisely defined input files to repeatably produce output files at uniquely determined file system paths.

It takes an attribute set as an input, the attributes of which specify the inputs to the process.

It outputs an attribute set, and produces a store derivation as a side effect of evaluation.

In terms of nixp syntax, this is a standard function called `derivation` that takes in an attribute set.

## Type System

Nixp provides a new programming language frontend to Nix.

Nixp optionally provides a type system as well.

The Nixp type system will only actually work in regards to other Nixp code, and will fail to work with other Nix code comfortably (besides the builtin functions).

However, Nixp allows one to describe an FFI-like syntax for types for Nix code imports.

### Functions

#### Single Parameter Functions

Consider the Nixp function:

```Clojure
(lambda x (lambda y (+ x y)))
```

This function can be typed as follows:

```Clojure
(lambda [x :: Int] (lambda [y :: Int] (+ x y)))
```

#### Multi Parameter Functions

Consider:

```Clojure
(lambda ([x y]) (+ x y))
```

This can also be typed as follows:

```Clojure
(lambda ([[x :: Int]
          [y :: Int]])
        (+ x y))
```
