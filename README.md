Underscore
==========

julia didn't really need this, but i needed to make this.
---------------------------------------------------------

```julia
    julia> "hello" |> (@_ string(" world")) |> (@_ string("why, ", $1))
    "why, hello world"
```

Inspired by Elixir.
