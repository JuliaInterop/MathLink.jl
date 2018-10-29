module MathLink

# TODO:
#   Read and store native arrays / matrices
#   MRefs (https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)
#   Better error recovery
#   MathLink options
#   Connect to running session

export @mexpr, meval

include("low_level.jl")
include("types.jl")

#=
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
      Expr(:call, :meval, $call, $((t != nothing ? [t] : [])...))
    end)
end

macro math(expr)
  :(meval($(esc(Expr(:quote, expr)))))
end
=#

# ------------------
# Permalink and eval
# ------------------

const globallink = Ref(C_NULL)
function __init__()
    globallink[] = ML.Open()
end


meval(expr) = meval(expr::MExpr, Any)
meval(expr, T) = meval(globallink[], expr::MExpr, T)

function meval(link::ML.Link, expr::MExpr, T)
    put!(link, MFunc(MSymbol(:EvaluatePacket), Any[expr]))
    ML.EndPacket(link)
    handle_packets(link, T)
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
            warn(get!(link, Any).args[1])
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

get!(link::ML.Link, ::Type{BigInt}) = parse(BigInt, get!(link, String))

#get!(link::ML.Link, T) = convert(T, from_mma(get!(link)))

function get!(link::ML.Link, ::Type{Any})
    t = ML.GetType(link)

    if t == ML.TK.INT
        MInteger(get!(link, String))
    elseif t == ML.TK.FUNC
        f, nargs = ML.GetFunction(link)
        MFunc(MSymbol(f),
                  Any[get!(link, Any) for i=1:nargs])
    elseif t == ML.TK.STR
        MString(get!(link, String))
    elseif t == ML.TK.REAL
        MReal(get!(link, String))
    elseif t == ML.TK.SYM
        MSymbol(get!(link, Symbol))
    elseif t == ML.TK.ERROR
        error("Link has suffered error $(ML.Error(link)): $(ML.ErrorMessage(link))")
    else
        error("Unsupported data type $t ($(Int(t)))")
    end
end

# Writing

function put!(link::ML.Link, m::MFunc)
    ML.PutFunction(link, string(m.head), length(m.args))
    for arg in m.args
        put!(link, arg)
    end
end
put!(link::ML.Link, m::MSymbol) = 
    ML.PutSymbol(link, m.name)

put!(link::ML.Link, m::MString) = 
    ML.PutString(link, m.value)

function put!(link::ML.Link, m::MReal)
    ML.PutType(link, ML.TK.REAL)
    ML.PutString(link, m.value)
end

function put!(link::ML.Link, m::MInteger)
    ML.PutType(link, ML.TK.INT)
    ML.PutString(link, m.value)
end


for (T, f) in [(Int64,   :PutInteger64)
               (Int32,   :PutInteger32)
               (Float64, :PutReal64)
               (AbstractString,  :PutString)
               (Symbol,  :PutSymbol)]
  @eval put!(link::ML.Link, x::$T) = (ML.$f)(link, x)
end


#include("display.jl")

end
