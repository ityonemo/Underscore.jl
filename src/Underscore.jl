module Underscore

"""
    Underscore.scan_ast(e, fv)

    is a utility function that scans an Expr e for a free variable fv, which
    must be a symbol.  Returns true if fv is a leaf anywhere in the ast.
"""
scan_ast(e::Any, fv::Symbol) = false
scan_ast(e::Symbol, fv::Symbol) = e == fv
scan_ast(e::Expr, fv::Symbol) = mapreduce((x) -> scan_ast(x, fv), |, false, e.args)

# package code goes here
"""
    \@_

gives a simple way of remapping multi-argument functions in pipelines.  Normally,
a julia pipeline requires a naked function with one argument to be the right
operand of the pipeline operator; this allows you to easily call multi-argument
functions in the pipeline operator by syntatically calling the remaining
parameters.  \@_ will create a lambda encapsulating the remaining parameters and
injecting the result as the first parameter.

#Examples

```jldocstring
julia> "hello" |> @_ println(" world")
hello world
```

you may also redirect in the case where you cannot intercept the first value.

```jldocstring
julia> [1, 2, 3] |> @_ reduce(+, 0, \$1)
6
```

finally, you can also pass multi-valued function results (aka tuples) into the
recieving function, as you might expect.

```jldocstring
julia> (1, 2) |> @_ sum(3, \$1, \$2)
6
```

"""
macro _(expr)
    #first, make sure that expr is a call.
    (expr.head == :call) || throw(ArgumentError("@_ must precede a function call."))
    #find out how many dollar sign arguments we're going to use.
    positionalparams = Set{Int64}()
    for param in expr.args
        if (param isa Expr) && (param.head == :$) && (length(param.args) == 1) && (param.args[1] isa Int64)
            push!(positionalparams, param.args[1])
        end
    end

    #find the tuple length.  This is the longest parameter in the tuple
    tuple_length = length(positionalparams) == 0 ? 1 : maximum(positionalparams)

    #select the correct variable to use as the free variable in the lambda.
    #this can get tricky since it's possible the lambda'd function call contains
    #other free variables that *look like* the one we want to use.  We'll have to
    #traverse the tree to make sure this isn't the case.  Allocate one extra
    #free variable to use as a splatting variable, if needed.
    test_index = 1
    free_variables = Symbol[]
    for idx = 1:(tuple_length + 1)
        while true
            free_var = Symbol(:x, test_index)
            scan_ast(expr, free_var) || break;    #break if we can find a safe value.
            test_index += 1
            (test_index > 100) && throw(ArgumentError("it seems like you have an awful lot of free x variables"))
        end
        push!(free_variables, Symbol(:x, test_index))
        test_index += 1
    end

    if (length(positionalparams) == 0)
        #prepend the free variable into the ast of the expression.
        insert!(expr.args, 2, free_variables[1])
    else
        #do a splicing operation to put in the correct free variables.
        for idx = 1:length(expr.args)
            param = expr.args[idx]
            if (param isa Expr) && (param.head == :$) && (length(param.args) == 1) && (param.args[1] isa Int64)
                substitution = param.args[1]
                splice!(expr.args, idx:idx, [free_variables[substitution]])
            end
        end
    end

    #create a shell, empty lambda into which we will put our free variables, except
    #the tailing one.
    generated_lambda = :(()-> $expr)
    append!(generated_lambda.args[1].args, free_variables[1:end-1])

    if tuple_length <= 1
        #return the function and escape.
        esc(generated_lambda)
    else
        #splat a passed tuple.
        t = free_variables[end]
        esc(:(($t)->($generated_lambda)($t...)))
    end
end

#this doesn't collide with anything in the Base namespace, so go ahead and
#export it for convenience.
export @_

end # module
