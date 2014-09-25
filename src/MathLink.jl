module MathLink

# TODO:
#   Read and store native arrays / matrices
#   MRefs (https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)
#   Better error recovery
#   MathLink options
#   Connect to running session

export @math, @mmimport, @mmacro, meval, MExpr, to_mma, from_mma, to_expr

include("low_level.jl")

# -------------------
# Higher level macros
# -------------------

function proc_argtypes(types)
  args = map(x->gensym(), types)
  typed_args = map((a, t) -> :($a::$(esc(t))), args, types)
  args, typed_args
end

macro mmimport(expr)
  if typeof(expr) == Symbol
    f = esc(expr)
    :($f(xs...) = meval(Expr(:call, $(Expr(:quote, expr)), xs...)))

  elseif expr.head == :tuple
    Expr(:block, [:(@mmimport $(esc(x))) for x in expr.args]...)

  elseif expr.head == :(::)

    if typeof(expr.args[1]) == Symbol
      fsym = expr.args[1]
      f = esc(fsym)
      T = esc(expr.args[2])
      :($f(xs...) = meval(Expr(:call, $(Expr(:quote, fsym)), xs...), $T))

    elseif expr.args[1].head == :call
      fsym = expr.args[1].args[1]
      f = esc(fsym)
      args, typed_args = proc_argtypes(expr.args[1].args[2:end])
      rettype = esc(expr.args[2])
      :($f($(typed_args...)) =
          meval(Expr(:call, $(Expr(:quote, fsym)), $(args...)), $rettype))
    end
  else
    error("Unsupported mmimport expression $expr")
  end
end

macro mmacro(expr)
  if typeof(expr) == Symbol
    sym = expr
    t = nothing
  elseif typeof(expr) == Expr && expr.head == :(::)
    sym = expr.args[1]
    t = expr.args[2]
  elseif expr.head == :tuple
    return Expr(:block, [:(@mmacro $(esc(x))) for x in expr.args]...)
  else
    error("Unsupported expression $expr in @mmacro.")
  end

  f = esc(sym)
  fsym = Expr(:quote, sym)
  call = :(esc(Expr(:quote,
                Expr(:call, $fsym, args...))))

  :(macro $f(args...)
      Expr(:call, :meval, $call, $((t!=nothing?[t]:[])...))
    end)
end

macro math(expr)
  :(meval($(esc(Expr(:quote, expr)))))
end

# ------------------
# Permalink and eval
# ------------------

@windows_only const wintestpaths =
  ["C:\\Program Files\\Wolfram Research\\Mathematica\\9.0\\math.exe"
   "C:\\Program Files\\Wolfram Research\\Mathematica\\8.0\\math.exe"]

@osx_only const osxtestpaths =
 ["/Applications/Mathematica.app/Contents/MacOS/MathKernel"]

function math_path()
  @windows_only for path in wintestpaths
    isfile(path) && return path
  end
  @osx_only for path in osxtestpaths
    isfile(path) && return path
  end
  "math"
end

const link = ML.Open(math_path())
meval(expr) = meval(expr, Any)
meval(expr, T) = meval(link, expr, T)

function meval(link::ML.Link, expr, T)
  try
    put!(link, MExpr(:EvaluatePacket, to_mma(expr)))
    ML.EndPacket(link)
    T == Expr ?
      handle_packets(link, Any) |> from_mma |> to_expr :
      handle_packets(link, T)
  catch
    warn("Error occured in meval: you may need to restart Julia/MathLink")
    rethrow()
  end
end

function handle_packets(link::ML.Link, T)
  packet = :start
  msg = false
  while packet != :ReturnPacket
    if packet == :start
    elseif packet == :TextPacket
      print(get!(link, String))
    elseif packet == :MessagePacket
      ML.NewPacket(link)
      warn(get!(link).args[1])
      msg = true
    else
      error("Unsupported packet type $packet")
    end
    packet, n = ML.GetFunction(link)
  end
  msg && T != Any &&
    error("Output suppressed due to warning: " * string(get!(link)))
  return get!(link, T)
end

# ---------------------------
# Display of Mathematica data
# ---------------------------

immutable MExpr{Head}
  args::Vector
end
MExpr(head, args...) = MExpr{head}([args...])

import Base.show

function show{T}(io::IO, e::MExpr{T})
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

# ------------------------------------
# Conversion to/from Mathematica data.
# ------------------------------------

const aliases =
  [:*   => :Times,
   :/   => :Divide,
   :^   => :Power,
   :+   => :Plus,
   :-   => :Subtract,
   :%   => :Mod,
   :log => :Log,
   :exp => :Exp]

from_mma(x) = x
const symbols = [:True => true, :False => false, :Null => nothing]
from_mma(s::Symbol) = haskey(symbols, s) ? symbols[s] : s

to_mma{T<:Union(Int64,Int32,Float64,Float32,Symbol,String)}(x::T) = x

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

to_mma{T}(x::MExpr{T}) = MExpr{T}(map(to_mma, x.args))
from_mma{T}(x::MExpr{T}) = MExpr{T}(map(from_mma, x.args))

to_mma(x::Rational) = MExpr(:Rational, x.num, x.den)
from_mma(f::MExpr{:Rational}) = f.args[1]//f.args[2]

to_mma(x::Complex) = MExpr(:Complex, to_mma(real(x)), to_mma(imag(x)))
from_mma(x::MExpr{:Complex}) = Complex(x.args[1], x.args[2])

to_mma(xs::Vector) = MExpr{:List}(map(to_mma, xs))
from_mma(l::MExpr{:List}) = map(from_mma, l.args)

# Julia Expression Conversion

to_expr(x) = x
to_expr{T}(x::MExpr{T}) = Expr(:call, T, map(to_expr, x.args)...)

for (j, m) in aliases
  j = Expr(:quote, j)
  m = Expr(:quote, m)
  @eval to_expr(x::MExpr{$m}) = Expr(:call, $j, map(to_expr,x.args)...)
end

import Base.convert
convert(::Type{Expr}, x::MExpr) = to_expr(from_mma(x))
convert(::Type{MExpr}, x::Expr) = to_mma(x)

# --------------
# Low level data
# --------------

# Reading

# Perhaps add a type check here, depending on perf hit
for (T, f) in [(Int64,   :GetInteger64)
               (Int32,   :GetInteger32)
               (Float64, :GetReal64)
               (String,  :GetString)
               (Symbol,  :GetSymbol)]
  @eval get!(link::ML.Link, ::Type{$T}) = (ML.$f)(link)
end

get!(link::ML.Link, ::Type{BigInt}) = BigInt(get!(link, String))

get!(link::ML.Link, T) = convert(T, from_mma(get!(link)))

function get!(link::ML.Link)
  t = ML.GetType(link)

  if t == ML.TK.INT
    i = get!(link, BigInt)
    typemin(Int) <= i <= typemax(Int) ? int(i) : i

  elseif t == ML.TK.FUNC
    f, nargs = ML.GetFunction(link)
    MExpr{f}({get!(link) for i=1:nargs})

  elseif t == ML.TK.STR
    get!(link, String)
  elseif t == ML.TK.REAL
    get!(link, Float64)
  elseif t == ML.TK.SYM
    get!(link, Symbol)

  elseif t == ML.TK.ERROR
    error("Link has suffered error $(ML.Error(link)): $(ML.ErrorMessage(link))")

  else
    error("Unsupported data type $t ($(int(t)))")
  end
end

# Writing

put!(link::ML.Link, head::Symbol, nargs::Integer) = ML.PutFunction(link, string(head), nargs)

for (T, f) in [(Int64,   :PutInteger64)
               (Int32,   :PutInteger32)
               (Float64, :PutReal64)
               (String,  :PutString)
               (Symbol,  :PutSymbol)]
  @eval put!(link::ML.Link, x::$T) = (ML.$f)(link, x)
end

function put!{T}(link::ML.Link, expr::MExpr{T})
  put!(link, T, length(expr.args))
  for x in expr.args put!(link, x) end
end

end
