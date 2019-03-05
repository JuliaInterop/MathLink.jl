struct MExpr{Head}
  args::Vector
end
MExpr(head, args...) = MExpr{head}([args...])

import Base.show

function show(io::IO, e::MExpr{T}) where {T}
  print(io, T)
  if length(e.args) >= 1
    print(io, "["); show(io, e.args[1])
    for x in e.args[2:end] print(io, ", "); show(io, x) end
    print(io, "]")
  else
    print(io, "[]")
  end
end

show(io::IO, r::MExpr{:Rule}) =
  (show(io, r.args[1]); print(io, "→"); show(io, r.args[2]))

# Conversion

const aliases =
  Dict(:*   => :Times,
       :/   => :Divide,
       :^   => :Power,
       :+   => :Plus,
       :-   => :Subtract,
       :%   => :Mod,
       :log => :Log,
       :exp => :Exp,
       :sin => :Sin,
       :cos => :Cos,
       :tan => :Tan,
       :(<)  => :Less,
       :(<=) => :LessEqual,
       :(>)  => :Greater,
       :(>=) => :GreaterEqual,
       :(==) => :Equal,
       :(!=) => :Unequal,
       :(=>) => :Rule)

from_mma(x) = x
const symbols = Dict(:True => true, :False => false, :Null => nothing)
from_mma(s::Symbol) = haskey(symbols, s) ? symbols[s] : s

to_mma(x::T) where {T<:Union{Int64,Int32,Float64,Float32,Symbol,AbstractString}} = x

function to_mma(x::Expr)
  if x.head == :call
    head = haskey(aliases, x.args[1]) ? aliases[x.args[1]] : x.args[1]
    MExpr{head}(map(to_mma, x.args[2:end]))
  elseif x.head == :block
    MExpr{:CompoundExpression}(map(to_mma, x.args))
  elseif x.head == :ref
    MExpr{:Part}(map(to_mma, x.args))
  elseif x.head == :braces
    MExpr{:List}(map(to_mma, x.args))
  elseif haskey(aliases, x.head)
    head = aliases[x.head]
    MExpr{head}(map(to_mma, x.args))
  else
    error("Unsupported $(x.head) expression.")
  end
end

function to_mma(x::QuoteNode)
  typeof(x.value) == Symbol && return x.value
  error("Cannot call to_mma on QuoteNode($(x.value))")
end

# Other types

to_mma(x::Bool) = x ? :True : :False

to_mma(x::MExpr{T}) where {T} = MExpr{T}(map(to_mma, x.args))
from_mma(x::MExpr{T}) where {T} = MExpr{T}(map(from_mma, x.args))

to_mma(x::Rational) = MExpr(:Rational, x.num, x.den)
from_mma(f::MExpr{:Rational}) = f.args[1]//f.args[2]

to_mma(x::Complex) = MExpr(:Complex, to_mma(real(x)), to_mma(imag(x)))
from_mma(x::MExpr{:Complex}) = Complex(x.args[1], x.args[2])

to_mma(xs::Vector) = MExpr{:List}(map(to_mma, xs))
from_mma(l::MExpr{:List}) = map(from_mma, l.args)

# Julia Expression Conversion

to_expr(x) = x
to_expr(x::MExpr{T}) where {T} = Expr(:call, T, map(to_expr, x.args)...)

for (j, m) in aliases
  j = Expr(:quote, j)
  m = Expr(:quote, m)
  @eval to_expr(x::MExpr{$m}) = Expr(:call, $j, map(to_expr,x.args)...)
end

import Base.convert
convert(::Type{Expr}, x::MExpr) = to_expr(from_mma(x))
convert(::Type{MExpr}, x::Expr) = to_mma(x)
