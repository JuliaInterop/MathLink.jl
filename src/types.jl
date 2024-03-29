abstract type WTypes end


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
struct WSymbol <: WTypes
    name::String
end 
WSymbol(sym::Symbol) = WSymbol(String(sym))
Base.print(io::IO, s::WSymbol) = print(io, s.name)
Base.show(io::IO, s::WSymbol) = print(io, 'W', '"', s.name, '"')
Base.:(==)(a::WSymbol, b::WSymbol) = a.name == b.name

macro W_str(str)
    :(WSymbol($str))
end

"""
    WReal(str::String)

A Wolfram arbitrary-precision real number.
"""
struct WReal <: WTypes
    value::String
end
Base.show(io::IO, x::WReal) = print(io, x.value)
Base.:(==)(a::WReal, b::WReal) = a.value == b.value

"""
    WInteger(str::String)

A Wolfram arbitrary-precision integer.
"""
struct WInteger <: WTypes
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
mutable struct WExpr <: WTypes
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

function Base.show(io::IO, wexpr::WExpr)
    print(io, "W`")
    print_wexpr(io, wexpr)
    print(io, "`")
end

function print_wexpr(io::IO, wexpr::WExpr)
    print_wexpr(io, wexpr.head)
    print(io, '[')
    if length(wexpr.args) > 0
        print_wexpr(io, wexpr.args[1])
        for arg in wexpr.args[2:end]
            print(io, ", ")
            print_wexpr(io, arg)
        end
    end
    print(io, ']')
end
print_wexpr(io::IO, wsym::WSymbol) = print(io, wsym.name)
print_wexpr(io::IO, wreal::WReal) = print(io, wreal.value)
print_wexpr(io::IO, wint::WInteger) = print(io, wint.value)
function print_wexpr(io::IO, x::Float64) 
    s = split(string(x),'e')
    if length(s) == 1
        print(io, x)
    else
        print(io, s[1], "*^", s[2])
    end
end
print_wexpr(io::IO, x::Int) = print(io, x)
print_wexpr(io::IO, x::String) = show(io, x)
print_wexpr(io::IO, x) = print(io, "\$(", x, ")")




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
