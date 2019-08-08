
"""
    WSymbol

"""
struct WSymbol
    name::String
end
WSymbol(sym::Symbol) = WSymbol(String(sym))
Base.show(io::IO, s::WSymbol) = print(io, s.name)

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
    head::WSymbol
    args::Vector{Any}
end
WExpr(sym::Symbol, args...) = WExpr(WSymbol(String(sym)), collect(Any, args))

function Base.show(io::IO, w::WFunc)
    print(io, w.head)
    print(io, '[')
    join(io, w.args, ", ")
    print(io, ']')
end

