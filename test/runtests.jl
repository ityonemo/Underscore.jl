using Underscore
using Base.Test

@test "hello" |> (@_ string(" world")) == "hello world"

@test "world" |> (@_ string("hello ", $1)) == "hello world"

@test [1, 2, 3] |> (@_ reduce(+, 0, $1)) == 6

@test (1, 2) |> (@_ +(3, $1, $2)) == 6

andnext(x) = (x, x + 1)
sqr(x) = x^2

@test 1 |> andnext |> (@_ $1 + $2) |> sqr == 9

@test 1 |> (@_ $1 + $1) == 2

@test (1, 2) |> (@_ sqr($2)) == 4
