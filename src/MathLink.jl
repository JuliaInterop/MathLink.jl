module MathLink

# TODO:
#   Read and store native arrays / matrices
#   MRefs (https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)
#   Better error recovery
#   MathLink options
#   Connect to running session

export @mexpr, meval

include("findlib.jl")
include("types.jl")
include("consts.jl")
include("wstp.jl")
include("init.jl")

# ------------------
# Permalink and eval
# ------------------


function get(link::Link, ::Type{WExpr})
    wsym, nargs = getfunction(link)
    WExpr(wsym, [get(link, Any) for i = 1:nargs])
end
function put(link::Link, w::WExpr)
    putfunction(link, w.head, length(w.args))
    for arg in w.args
        put(link, arg)
    end
    nothing
end

function get(link::Link, ::Type{Any})
    t = GetType(link)

    if t == TK.INT
        get(link, Int)
    elseif t == TK.FUNC
        get(link, WExpr)
    elseif t == TK.STR
        get(link, String)
    elseif t == TK.REAL
        get(link, Float64)
    elseif t == TK.SYM
        get(link, WSymbol)
    elseif t == TK.ERROR
        error("Link has suffered error $(Error(link)): $(ErrorMessage(link))")
    else
        error("Unsupported data type $t ($(Int(t)))")
    end
end

function handle_packets(link::Link, T)
    msg = false
    while true
        packet, _ = getfunction(link)
        if packet.name == "ReturnPacket"
            return get(link, T)
        elseif packet.name == "TextPacket"
            print(get(link, String))
        elseif packet.name == "MessagePacket"
            NewPacket(link)
            @warn get(link, Any)
            msg = true
            # msg && T != Any &&
            #     error("Output suppressed due to warning: " * string(get(link)))
        else
            error("Unsupported packet type $packet")
        end
    end
end


meval(expr) = meval(expr, Any)
meval(expr, T) = meval(_defaultlink(), expr, T)

function meval(link::Link, expr::WExpr, T)
    put(link, WExpr(WSymbol("EvaluatePacket"), Any[expr]))
    EndPacket(link)
    handle_packets(link, T)
end


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



#=
# --------------
# Low level data
# --------------

# Reading


get!(link::Link, ::Type{BigInt}) = parse(BigInt, get!(link, String))

#get!(link::Link, T) = convert(T, from_mma(get!(link)))


# Writing

function put!(link::Link, m::MFunc)
    PutFunction(link, string(m.head), length(m.args))
    for arg in m.args
        put!(link, arg)
    end
end
put!(link::Link, m::MSymbol) = 
    PutSymbol(link, m.name)

put!(link::Link, m::MString) = 
    PutString(link, m.value)

function put!(link::Link, m::MReal)
    PutType(link, TK.REAL)
    PutString(link, m.value)
end

function put!(link::Link, m::MInteger)
    PutType(link, TK.INT)
    PutString(link, m.value)
end


for (T, f) in [(Int64,   :PutInteger64)
               (Int32,   :PutInteger32)
               (Float64, :PutReal64)
               (AbstractString,  :PutString)
               (Symbol,  :PutSymbol)]
  @eval put!(link::Link, x::$T) = ($f)(link, x)
end

=# 
#include("display.jl")

end
