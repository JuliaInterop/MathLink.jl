module MathLink

# TODO:
#   Read and store native arrays / matrices
#   MRefs (https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)

export @w_cmd, meval

include("findlib.jl")
include("types.jl")
include("consts.jl")
include("wstp.jl")
include("extras.jl")
include("init.jl")

# ------------------
# Permalink and eval
# ------------------
function handle_packets(link::Link, T)
    while true
        # TODO: use WSNextPacket?
        packet, _ = getfunction(link)
        if packet.name == "ReturnPacket"
            return get(link, T)
        elseif packet.name == "TextPacket"
            print(get(link, String))
        elseif packet.name == "MessagePacket"
            NewPacket(link)
            packet, _ = getfunction(link) # TextPacket
            @warn get(link, String)
        else
            error("Unsupported packet type $packet")
        end
    end
end


function meval(link::Link, expr, T)
    put(link, WExpr(WSymbol("EvaluatePacket"), Any[expr]))
    EndPacket(link)
    handle_packets(link, T)
end
meval(expr) = meval(expr, Any)
meval(expr, T) = meval(_defaultlink(), expr, T)

function mevalstr(link, str::AbstractString, T)
    meval(link, WExpr(WSymbol("ToExpression"), Any[str]), T)
end
mevalstr(expr) = mevalstr(expr, Any)
mevalstr(expr, T) = mevalstr(_defaultlink(), expr, T)

function parseexpr(str::AbstractString)
    r = meval(WExpr(WSymbol("ToExpression"), Any[str, WSymbol("InputForm"), WSymbol("Hold")]))
    r.args[1]    
end

macro w_cmd(str)
    parseexpr(str)
end

(w::WSymbol)(args...) = meval(WExpr(w, collect(Any, args)))
(w::WExpr)(args...) = meval(WExpr(w, collect(Any, args)))

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

#include("display.jl")

end
