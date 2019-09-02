"""
    WSymbol

A Wolfram language symbol. The `W""` string macro can be used as a short form.
"""
struct WSymbol
    name::String
end
WSymbol(sym::Symbol) = WSymbol(String(sym))
Base.print(io::IO, s::WSymbol) = print(io, s.name)
Base.show(io::IO, s::WSymbol) = print(io, 'w', '"', s.name, '"')

macro W_str(str)
    WSymbol(str)
end

struct WReal
    value::String
end
Base.show(io::IO, x::WReal) = print(io, x.value)

struct WInteger
    value::String
end
Base.show(io::IO, x::WInteger) = print(io, x.value)

"""
    WExpr

A Wolfram language expression.
"""
struct WExpr
    head
    args
end

function Base.print(io::IO, w::WExpr)    
    print(io, w.head)
    print(io, '[')
    join(io, w.args, ", ")
    print(io, ']')
end
#Base.show(io::IO, w::WExpr) = print(io, "w`", w, "`")


(w::WSymbol)(args...) = WExpr(w, args)
(w::WExpr)(args...) = WExpr(w, args)
