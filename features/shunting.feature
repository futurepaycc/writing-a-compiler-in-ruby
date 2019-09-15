
Feature: Shunting Yard
	In order to parse expressions, the compiler uses a parser component that uses the shunting yard 
	algorithm to parse expressions based on a table.

    @basic
	Scenario Outline: Basic expressions
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
      | expr                 | tree                                  |
      | "__FILE__"           | :__FILE__                             |
      | "0.5"                | 0.5                                   |
      | "$0"                 | :"$0"                                 |
      | "$foo"               | :"$foo"                               |
      | "1 + 2"              | [:+,1,2]                              |
      | "1 - 2"              | [:-,1,2]                              |
      | "1 + 2 * 3"          | [:+,1,[:*,2,3]]                       |
      | "1 * 2 + 3"          | [:+,[:*,1,2],3]                       |
      | "(1+2)*3"            | [:*,[:+,1,2],3]                       |
      | "1 , 2"              | [:comma,1,2]                          |
      | "a << b"             | [:<<,:a,:b]                           |
      | "1 .. 2"             | [:range,1,2]                          |
      | "a == b"             | [:"==",:a,:b]                         |
      | "a = 1 or foo + bar" | [:or,[:assign,:a,1],[:+,:foo,:bar]]   |
      | "!c \|\| d"            | [:or, [:"!", :c], :d]                 |
      | "foo and !bar"       | [:and,:foo,[:"!",:bar]]               |
      | "return 1"           | [:return,1]                           |
      | "return"             | [:return]                             |
      | "5"                  | 5                                     |
      | "?A"                 | 65                                    |
      | "foo +"+10.chr+"bar" | [:+,:foo,:bar]                        |
      | "return"+10.chr+"foo" | [:return]                            |
      | ":sym"               | :":sym"                               |
      | ":foo_bar"           | :":foo_bar"                           |
      | ":[]"                | :":[]"                                |
      | "self.class"         | [:callm,:self,:class]                 |
      | 'return :":[]"'      | [:return, :"::[]"]                    |
      | "a = b && c"         | [:assign, :a, [:and, :b, :c]]         |
      | "a = b && c ? d : e" | [:assign, :a, [:ternif, [:and, :b, :c], [:ternalt, :d, :e]]] |
      | "b && c ? d : e"     | [:ternif, [:and, :b, :c], [:ternalt, :d, :e]]                |
      | "a && b ? c : d"     | [:ternif, [:and, :a, :b], [:ternalt, :c, :d]] |
      | "foo(a) && bar(b) ? baz(c) : 'test'" | [:ternif, [:and, [:call, :foo, [:a]], [:call, :bar, [:b]]], [:ternalt, [:call, :baz, [:c]], "test"]] |

    @callm
	Scenario Outline: Method calls
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
      | expr                    | tree                                                               |
      | "foo(1)"                | [:call,:foo,[1]]                                                   |
      | "foo(1,2)"              | [:call,:foo,[1,2]]                                                 |
      | "foo 1"                 | [:call,:foo,[1]]                                                   |
      | "foo 1,2"               | [:call,:foo,[1,2]]                                                 |
      | "self.foo"              | [:callm,:self,:foo]                                                |
      | "self.foo(1)"           | [:callm,:self,:foo,[1]]                                            |
      | "self.foo(1,2)"         | [:callm,:self,:foo,[1,2]]                                          |
      | "self.foo bar"          | [:callm,:self,:foo,:bar]                                           |
      | "foo(*arg)"             | [:call,:foo,[[:splat, :arg]]]                                      |
      | "foo(*arg,bar)"         | [:call,:foo,[[:splat, :arg],:bar]]                                 |
      | "foo.bar(*arg)"         | [:callm, :foo, :bar, [[:splat, :arg]]]                             |
      | "foo.bar(!arg)"         | [:callm, :foo, :bar, [[:"!", :arg]]]                               |
      | "foo(1 + arg)"          | [:call,:foo,[[:+, 1, :arg]]]                                       |
      | "foo(1 * arg,bar)"      | [:call,:foo,[[:*, 1, :arg],:bar]]                                  |
      | "(ret.flatten).uniq"    | [:callm,[:callm,:ret,:flatten],:uniq]                              |
      | "ret.flatten.uniq"      | [:callm,[:callm,:ret,:flatten],:uniq]                              |
      | "foo.bar = 123"         | [:callm,:foo,:bar=, [123]]                                         |
      | "flatten(r[2])"         | [:call, :flatten, [[:callm, :r, :[], [2]]]]                        |
      | "foo.bar(ret[123])"     | [:callm, :foo, :bar, [[:callm, :ret, :[], [123]]]]                 |
      | "Foo::bar(baz)"         | [:call, [:deref, :Foo, :bar], [:baz]]                              |
      | "foo.bar sym do end"    | [:callm, :foo, :bar, :sym, [:block]]                               |
      | "foo.bar"               | [:callm, :foo, :bar]                                               |
      | "foo().bar"             | [:callm, [:call, :foo], :bar]                                      |
      | "foo.bar.baz"           | [:callm, [:callm, :foo, :bar], :baz]                               |
      | "foo.bar().baz"         | [:callm, [:callm, :foo, :bar], :baz]                               |
      | "x = foo.bar"           | [:assign, :x, [:callm, :foo, :bar]]                                |
      | "x = foo.bar()"         | [:assign, :x, [:callm, :foo, :bar]]                                |
      | "x = foo.bar.baz"       | [:assign, :x, [:callm, [:callm, :foo, :bar], :baz]]                |
      | "x = foo.bar().baz"     | [:assign, :x, [:callm, [:callm, :foo, :bar], :baz]]                |
      | "return foo.bar().baz"  | [:return, [:callm, [:callm, :foo, :bar], :baz]]                    |
      | "foo.bar(*[a].flatten)" | [:callm, :foo, :bar, [[:splat, [:callm, [:array, :a], :flatten]]]] |
      | "name.gsub(foo.bar) { } "   | [:callm, :name, :gsub, [[:callm, :foo, :bar]], [:block]]       |
      | "name.gsub(1) { }"      | [:callm, :name, :gsub, [1], [:block]]                              |

    @arrays @arrays1
	Scenario Outline: Array syntax
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
	  | expr        | tree                                     |
      | "[]"        | [:array]                                 |
      | "[1,2]"     | [:array,1,2]                             |
      | "[1,2] + [3]"| [:+,[:array,1,2],[:array,3]]            |
      | "[1,[2,3]]" | [:array,1,[:array,2,3]]                  |
      | "a = [1,2]" | [:assign,:a,[:array,1,2]]                |
      | "a = []"    | [:assign,:a,[:array]]                    |
	  | "[o.sym]"   | [:array,[:callm,:o,:sym]]                | 
	  | "[o.sym(1)]"   | [:array,[:callm,:o,:sym,[1]]]         | 
	  | "[o.sym,foo]"| [:array,[:callm,:o,:sym],:foo]          | 
	  | "[1].compact"| [:callm,[:array,1],:compact]            | 
	  | "return []"  | [:return,[:array]]                      |
	  | "return [foo]" | [:return,[:array, :foo]]                |
	  | "return [foo.bar]" | [:return,[:array, [:callm, :foo, :bar]]] |
      | "!foo[1].bar" | [:!,[:callm, [:callm, :foo, :[], [1]], :bar]]   |

    @arrays
	Scenario Outline: Array operators
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
	  | expr         | tree                                  | notes |
	  | "a[1]"       | [:callm,:a,:[],[1]]                   |       |
      | "Set[1,2,3]" | [:callm,:Set,:[],[1,2,3]]             |       |
      | "r[2][0]"    | [:callm, [:callm,:r,:[],[2]],:[],[0]] |       |
      | "s.foo[0]"   | [:callm, [:callm,:s,:foo],:[],[0]]    |       |
      | "foo[1] = 2" | [:callm, :foo, :[]=, [1,2]]           | Tree rewrite |
      | "puts([42])" | [:call, :puts, [[:array, 42]]]          | |
      | "puts [42]"  | [:call, :puts, [42]]            | |

    @func
    Scenario Outline: Function calls
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
      | expr                      | tree                                        |   |
      | "attr_reader :args,:body" | [:call, :attr_reader, [:":args", :":body"]] |   |
      | "puts 42 == 42"           | [:call, :puts, [[:==,42,42]]]               |   |
      | "foo.bar() + 'x'"         | [:+, [:callm, :foo, :bar], "x"]             |   | 
      | "foo.bar + 'x'"           | [:+, [:callm, :foo, :bar], "x"]             |   | 
      | "!(x).y"                  | [:!, [:callm, :x, :y]]                      |   |
  
	Scenario Outline: Terminating expressions with keywords
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>
		And the remainder of the scanner stream should be <remainder>

	Examples:
	  | expr        | tree                     | remainder                   |
      | "1 + 2 end" | [:+,1,2]                 | "end"                       |
      | "1 + 2 if"  | [:+,1,2]                 | "if"                        |


	Scenario Outline: Handling variable arity expressions
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
	  | expr            | tree                                      |
	  | "return 1"      | [:return,1]                               |
	  | "return"        | [:return]                                 |
	  | "5 or return 1" | [:or,5,[:return,1]]                       |
	  | "5 or return"   | [:or,5,[:return]]                         |
	  | "return if 5"   | [:return]                                 |

	Scenario Outline: Complex expressions
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
	  | expr              | tree                                    |
      | "foo ? 1 : 0"     | [:ternif, :foo, [:ternalt, 1, 0]]       |
      | "(rest? ? 1 : 0)" | [:ternif, :rest?, [:ternalt, 1, 0]]     |
      | "@locals[a] + (rest? ? 1 : 0)" | [:+, [:callm, :@locals,:[], [:a]], [:ternif, :rest?, [:ternalt, 1, 0]]]   |

    @blocks
	Scenario Outline: Blocks
		Given the expression <expr>
		When I parse it with the shunting yard parser
		Then the parse tree should become <tree>

	Examples:
	  | expr                | tree                                       |
	  | "foo do end"        | [:call, :foo, [], [:block]]                |
      | "foo.bar do end"    | [:callm, :foo, :bar, [], [:block]]         |
	  | "foo {}"            | [:call, :foo, [],[:block]]                 |
      | "foo() {}"          | [:call, :foo, [],[:block]]                 |
      | "foo(1) {}"         | [:call, :foo, 1,[:block]]                  |
      | "e.foo(vars) { }"   | [:callm, :e, :foo, [:vars], [:block]]      |
      | "e.foo(vars)"       | [:callm, :e, :foo, [:vars]]                |
	  | "foo 1 {}"	        | [:call, :foo, 1,[:block]]                  |
      | "foo(1,2) {}"       | [:call, :foo, [1,2],[:block]]              |
      | "@s.expect(Quoted) { }" | [:callm, :@s, :expect, [:Quoted], [:block]]       |
	  | "foo = bar {}"	        | [:assign, :foo, [:call, :bar, [],[:block]]]|
      | "&foo"                  | [:to_block, :foo]                          |
