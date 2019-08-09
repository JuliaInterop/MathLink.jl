
"""
    WSymbol

"""
struct WSymbol
    name::String
end
WSymbol(sym::Symbol) = WSymbol(String(sym))
Base.print(io::IO, s::WSymbol) = print(io, s.name)
Base.show(io::IO, s::WSymbol) = print(io, "w`", s, "`")



struct WReal
    value::String
end
Base.show(io::IO, x::WReal) = print(io, x.value)

struct WInteger
    value::String
end
Base.show(io::IO, x::WInteger) = print(io, x.value)

struct WFunc
    head::WSymbol
    nargs::Cint
end

struct WExpr
    head
    args::AbstractVector
end
WExpr(sym::Symbol, args...) = WExpr(WSymbol(String(sym)), collect(Any, args))

function Base.print(io::IO, w::WExpr)    
    print(io, w.head)
    print(io, '[')
    join(io, w.args, ", ")
    print(io, ']')
end
Base.show(io::IO, w::WExpr) = print(io, "w`", w, "`")
