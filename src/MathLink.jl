__precompile__()

module MathLink

# TODO:
#   Read and store native arrays / matrices
#   MRefs (https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)
#   Better error recovery
#   MathLink options
#   Connect to running session

export @math, @mmimport, @mmacro, meval, MExpr, to_mma, from_mma, to_expr

include("findlib.jl")
include("ml.jl")
include("types.jl")

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

function __init__()
    global const env  = ML.Initialize()
    global const link = ML.Open(env)
end

meval(expr) = meval(expr, Any)
meval(expr, T) = meval(link, expr, T)

meval(link::ML.Link, expr) = meval(link, expr, Any)
function meval(link::ML.Link, expr, T)
    try
        put!(link, MExpr{:EvaluatePacket}(to_mma(expr)))
        ML.EndPacket(link)
        if T == Expr
            handle_response(link, Any) |> from_mma |> to_expr
        else
            handle_response(link, T)
        end
    catch
        warn("Error occured in meval: you may need to restart Julia/MathLink")
        rethrow()
    end
end

"""
    handle_response(link, T)

Handle the return packets from `link`, returning value of type `T`.
"""
function handle_response(link::ML.Link, T)
    # consume non-ReturnPackets on link
    while (ML.Flush(link); ML.Ready(link))
        pkt = ML.NextPacket(link)
        if pkt == PKT_TEXT
            info(get!(link, String))
        elseif pkt == PKT_MESSAGE
            # Message packets are followed by a text packet
            ML.NewPacket(link)
            ML.NextPacket(link)
            warn(get!(link, String))
        elseif pkt == PKT_RETURN
            return get!(link, T)
        else
            warn("Unhandled packet $pkt")
        end
        ML.NewPacket(link)        
    end
end

# --------------
# Low level data
# --------------

# Reading

# Perhaps add a type check here, depending on perf hit
get!{T<:Union{Int32,Int64,Float32,Float64,String,Symbol}}(link::ML.Link, ::Type{T}) = ML.Get(link, T)


get!(link::ML.Link, ::Type{BigInt}) = parse(BigInt, get!(link, String))
function get!(link::ML.Link, ::Type{Integer})
    get!(link, BigInt)
    typemin(Int) <= i <= typemax(Int) ? Int(i) : i
end

function get!(link::Link, ::Type{AbstractFloat})
    tsig = get!(link, String)
    texp = ""
    tprc = ""
    i,j = search(str,"*^")
    if i != 0
        texp = tsig[nextind(tsig,j):end]
        tsig = tsig[1:prevind(tsig,i)]
    end
    i,j = search(str,'`')
    if i != 0
        tprc = tsig[nextind(tsig,j):end]
        tsig = tsig[1:prevind(tsig,i)]
    end
    tnum = texp == "" ? tsig : tsig*'e'*texp
    if tprc != ""
        p = round(Int,parse(Float64,tprc)*3.321928094887362) # log2(10)
        return setprecision(BigFloat, p) do
            parse(BigFloat, tnum)
        end
    else
        return parse(Float64, tnum)
    end
end
function get!(link::Link, ::Type{BigFloat})
    x = get!(link::Link, ::Type{AbstractFloat})
    if isa(x,Float64)
        x = setprecision(BigFloat, 53) do
            BigFloat(x)
        end
    end
    return x
end

function get!(link::Link, ::Type{MExpr})
    # NOTE: we don't use ML.GetFunction as it doesn't handle the case when the
    # function head isn't a symbol, e.g. Derivative[1][f][x]
    n = ML.GetArgCount(link)
    head = get!(link)
    args = [get!(link) for i=1:n]            
    MExpr{head}(args)
end


get!(link::ML.Link, T) = convert(T, from_mma(get!(link)))

"""
    get!(link)

Gets the next object on the link.
"""
function get!(link::ML.Link,::Type{Any}=Any)
    t = ML.GetNext(link)
    if t == ML.TKN_FUNC # function
        get!(link, MExpr)

    elseif t == ML.TKN_INT # integer
        get!(link, Integer)

    elseif t == ML.TKN_STR # string
        get!(link, String)
        
    elseif t == ML.TKN_REAL
        get!(link, AbstractFloat)
        
    elseif t == ML.TKN_SYM
        get!(link, Symbol)

    elseif t == ML.TKN_ERROR
        throw(ML.MathLinkError(link))

    else
        error("Unsupported data type $t ($(Int(t)))")
    end
end

# Writing
put!{T<:Union{Int32,Int64,Float32,Float64,String,Symbol}}(link::ML.Link, x::T) = ML.Put(link, x)
function put!(link::ML.Link, x::BigInt)
    ML.PutNext(link, ML.TKN_INT)
    ML.Put(link, string(x))
    nothing
end
function put!(link::ML.Link, x::BigFloat)
    if !isfinite(x)
        ML.Put(Float64(x))
        return nothing
    end
    tsig = string(x)
    texp = "0"
    tprc = string(precision(x)*0.3010299956639812)
    i,j = search(str,"e")
    if i != 0
        texp = tsig[nextind(tsig,j):end]
        tsig = tsig[1:prevind(tsig,i)]
    end
    ML.PutNext(link, ML.TKN_REAL)
    ML.Put(link, tsig*"`"*tprc*"*^"*texp)
end

function put!{T}(link::ML.Link, expr::MExpr{T})
    ML.PutNext(link, ML.TKN_FUNC)
    ML.PutArgCount(length(expr.args))
    put!(link, T)
    for x in expr.args
        put!(link, x)
    end
    nothing
end



include("display.jl")

end
