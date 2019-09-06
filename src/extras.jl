function get(link::Link, ::Type{Any})
    # TODO: handle big integers/floats
    t = getnextraw(link)
    if t == TK_INT        
        get(link, WInteger)
    elseif t == TK_INT32_LE
        get(link, Int)
    elseif t == TK_INT64_LE
        get(link, Int64)
    elseif t == TK_FUNC || t == TK_ARRAY
        get(link, WExpr)
    elseif t == TK_STR
        get(link, String)
    elseif t == TK_REAL
        get(link, WReal)
    elseif t == TK_FLOAT64_LE
        get(link, Float64)
    elseif t == TK_SYM
        get(link, WSymbol)
    elseif t == TK_ERROR
        throw(MathLinkError(link))
    else
        error("Unsupported data type $t ($(Int(t)))")
    end
end


function get(link::Link, ::Type{WExpr})
    nargs = getargcount(link)
    head = get(link, Any)
    args = [get(link, Any) for i = 1:nargs]
    WExpr(head, args)
end
function put(link::Link, w::WExpr)
    puttype(link, TK_FUNC)
    putargcount(link, length(w.args))
    put(link, w.head)
    for arg in w.args
        put(link, arg)
    end
    nothing
end

function put(link::Link, list::Union{AbstractVector, Tuple})
    putfunction(link, WSymbol("List"), length(list))
    for x in list
        put(link, x)
    end    
end

function get(link::Link, ::Type{T}) where {T<:Tuple}
    F = fieldtypes(T)
    nargs = getargcount(link)
    _ = get(link, Any)
    @assert nargs == length(F)
    map(S -> get(link, S), F)
end
function get(link::Link, ::Type{Vector{T}}) where {T}
    nargs = getargcount(link)
    _ = get(link, Any)
    T[get(link, T) for i = 1:nargs]
end
function get(link::Link, ::Type{Vector})
    nargs = getargcount(link)
    _ = get(link, Any)
    [get(link, Any) for i = 1:nargs]
end

function put(link::Link, w::WInteger)
    puttype(link, TK_INT)
    put(link, w.value)
end
function put(link::Link, x::BigInt)
    put(link, WInteger(string(x)))
end
function get(link::Link, ::Type{BigInt})
    parse(BigInt, get(link, WInteger).value)
end


const log10_2 = log10(2)
function put(link::Link, x::BigFloat)
    str = Base.MPFR.string_mpfr(x,"%.Re")
    str = replace(str, "e" => "`$(log10_2*precision(x))*^")
    put(link, WReal(str))
end
function get(link::Link, ::Type{BigFloat})
    str = get(link, WReal).value
    BigFloat(replace(replace(str, r"`[0-9\.]*"=>""), "*^"=>"e"))
end

put(link::Link, ::typeof(pi)) = put(link, W"Pi")
put(link::Link, ::typeof(MathConstants.e)) = put(link, W"E")
put(link::Link, ::typeof(MathConstants.golden)) = put(link, W"GoldenRatio")
put(link::Link, ::typeof(MathConstants.eulergamma)) = put(link, W"EulerGamma ")
put(link::Link, ::typeof(MathConstants.catalan)) = put(link, W"Catalan ")
