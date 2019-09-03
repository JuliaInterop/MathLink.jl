mexpr(x::WExpr) = x

mexpr(x::Float32) = x
mexpr(x::Float64) = x
mexpr(x::Int32) = x
mexpr(x::Int64) = x

mexpr(x::Rational) = WExpr(:Rational, mexpr(x.num), mexpr(x.den))
mexpr(x::Complex) = WExpr(:Complex, mexpr(real(x)), mexpr(imag(x)))

mexpr(x::String) = x

mexpr(x::Bool) = x ? WSymbol(:True) : WSymbol(:False)
mexpr(x::Nothing) = WSymbol(:Nothing)


macro mdef(jfun, mfun)
    quote
        MathLink.mexpr(::typeof($(esc(jfun)))) = MSymbol($(QuoteNode(mfun)))
    end    
end
    
@mdef(+, Plus)
@mdef(-, Subtract)
@mdef(*, Times)
@mdef(/, Divide)
@mdef(^, Power)

@mdef log Log
@mdef exp Exp
@mdef sin Sin
@mdef cos Cos
@mdef tan Tan
@mdef mod Mod

@mdef pi Pi
@mdef MathConstants.e E

macro mexpr(ex)
    :(mexpr($ex))
end

macro mexpr(ex::Symbol)
    :($(Expr(:isdefined, esc(ex))) ? mexpr($(esc(ex))) : MSymbol($(QuoteNode(ex))))
end


macro mexpr(ex::Expr)
    if ex.head == :call
        :(MFunc(@mexpr($(ex.args[1])),
                Any[$([:(@mexpr($arg)) for arg in ex.args[2:end]]...)]))
    elseif ex.head == :block
        :(MFunc(MSymbol(:CompoundExpression),
                Any[$([:(@mexpr($arg)) for arg in ex.args if !isa(arg, LineNumberNode)]...)]))
    elseif ex.head == :ref
        :(MFunc(MSymbol(:Part),
                Any[$([:(@mexpr($arg)) for arg in ex.args]...)]))
    else
        ex
    end
end


#=

# Conversion

from_mma(x) = x
const symbols = Dict(:True => true, :False => false, :Null => nothing)
from_mma(s::Symbol) = haskey(symbols, s) ? symbols[s] : s

to_mma(x::T) where {T<:Union{Int64,Int32,Float64,Float32,Symbol,AbstractString}}= x

function to_mma(x::Expr)
  if x.head == :call
    head = haskey(aliases, x.args[1]) ? aliases[x.args[1]] : x.args[1]
    MExpr{head}(map(to_mma, x.args[2:end]))
  elseif x.head == :block
    MExpr{:CompoundExpression}(map(to_mma, x.args))
  elseif x.head == :ref
    MExpr{:Part}(map(to_mma, x.args))
  elseif x.head == :cell1d
    MExpr{:List}(x.args)
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
=#
