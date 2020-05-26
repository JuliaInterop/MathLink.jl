"""
    WSymbol(name::Union{String, Symbol})
    W"..."

A Wolfram language symbol. The `W""` string macro can be used as a short form.

A `WSymbol` object is callable, which can be used to construct [`WExpr`](@ref)s (but doesn't evaluate it):
```julia
julia> W"Sin"
W"Sin"

julia> W"Sin"(1.0)
W"Sin"(1.0)

julia> weval(W"Sin"(1.0))
0.8414709848078965
```

Keyword arguments are passed as options:
```julia
julia> ex = W`Sqrt[x^2]`
W"Sqrt"(W"Power"(W"x", 2))

julia> assume = W`x<0`
W"Less"(W"x", 0)

julia> weval(W"Simplify"(ex, Assumptions=assume))
W"Times"(-1, W"x")
```
"""
struct WSymbol
    name::String
end
WSymbol(sym::Symbol) = WSymbol(String(sym))
Base.print(io::IO, s::WSymbol) = print(io, s.name)
Base.show(io::IO, s::WSymbol) = print(io, 'W', '"', s.name, '"')
Base.:(==)(a::WSymbol, b::WSymbol) = a.name == b.name

macro W_str(str)
    WSymbol(str)
end

"""
    WReal(str::String)

A Wolfram arbitrary-precision real number.
"""
struct WReal
    value::String
end
Base.show(io::IO, x::WReal) = print(io, x.value)
Base.:(==)(a::WReal, b::WReal) = a.value == b.value

"""
    WInteger(str::String)

A Wolfram arbitrary-precision integer.
"""
struct WInteger
    value::String
end
Base.show(io::IO, x::WInteger) = print(io, x.value)
Base.:(==)(a::WInteger, b::WInteger) = a.value == b.value

"""
    WExpr(head, args)

A Wolfram language expression. Like [`WSymbol`](@ref) it is callable to construct more complicated expressions.

```julia
julia> W`Function[x,x+1]`
W"Function"(W"x", W"Plus"(W"x", 1))

julia> W`Function[x,x+1]`(2)
W"Function"(W"x", W"Plus"(W"x", 1))(2)

julia> weval(W`Function[x,x+1]`(2))
3
```
"""
struct WExpr
    head
    args
end
function Base.:(==)(a::WExpr, b::WExpr)
    a.head == b.head || return false
    length(a.args) == length(b.args) || return false
    for (aa,bb) in zip(a.args, b.args)
        aa == bb || return false
    end
    return true
end

function Base.show(io::IO, w::WExpr)
    show(io, w.head)
    print(io, '(')
    isfirst = true
    for arg in w.args
        if !isfirst
            print(io, ", ")
        else
            isfirst = false
        end
        show(io, arg)
    end
    print(io, ')')
end


function (w::WSymbol)(args...; kwargs...)
    if !isempty(kwargs)
        args = [args..., [W"Rule"(WSymbol(k), v) for (k,v) in kwargs]...]
    end
    WExpr(w, args)
end
function (w::WExpr)(args...; kwargs...)
    if !isempty(kwargs)
        args = [args..., [W"Rule"(WSymbol(k), v) for (k,v) in kwargs]...]
    end
    WExpr(w, args)
end
