Underscore
==========

julia didn't really need this, but i needed to make this.
---------------------------------------------------------

```julia
    julia> using Underscore
    julia> "hello" |> (@_ string(" world")) |> (@_ string("why, ", $1))
    "why, hello world"
```

Q:
--
can't you just use normal lambdas?

A:
--
using this syntax you save five characters!
```julia
    julia> using Underscore
    julia> "hello" |> (@_ string(" world"))       #versus
    julia> "hello" |> (x) -> string(x, " world")
```

Inspired by Elixir.
