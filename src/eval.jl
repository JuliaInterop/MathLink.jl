"""
    handle_packets(link::Link, T)

Handle incoming packets on `link`, returning a type `T`.
"""
function handle_packets(link::Link, T)
    while true
        pkt = nextpacket(link)
        if pkt == PKT_RETURN
            return get(link, T)
        elseif pkt == PKT_TEXT
            print(get(link, String))
        elseif pkt == PKT_MESSAGE
            newpacket(link)
            @assert nextpacket(link) == PKT_TEXT
            @warn get(link, String)
        else
            error("Unsupported packet type $pkt")
        end
    end
end

function weval(link::Link, T, expr; vars...)
    if !isempty(vars)
        expr = W"With"([W"Set"(WSymbol(k), v) for (k,v) in vars], expr)
    end
    put(link, W"EvaluatePacket"(expr))
    endpacket(link)
    handle_packets(link, T)
end

"""
    weval([T,] expr; vars...)

Evaluate expression `expr`, returning a value of type `T` (default = `Any`).

If keyword arguments `vars` are provided, then `expr` is wrapped by a
[`With`](https://reference.wolfram.com/language/ref/With.html) block with `vars` assigned
as local constants.

```
julia> weval(W`Sin[x+2]`)
W"Sin"(W"Plus"(2, W"x"))

julia> weval(W`Sin[x+2]`; x=3)
W"Sin"(5)

julia> weval(W`Sin[x+2]`; x=3.0)
-0.9589242746631385
```
"""
weval(T, expr; vars...) = weval(_defaultlink(), T, expr; vars...)
weval(expr; vars...) = weval(Any, expr; vars...)


function wevalstr(link, T, str::AbstractString)
    weval(link, W"ToExpression"(str), T)
end
wevalstr(T, expr) = wevalstr(_defaultlink(), T, expr)
wevalstr(expr) = wevalstr(Any, expr)

"""
    MathLink.parseexpr(str::AbstractString)

Parse a string `str` as a Wolfram Language expression.
"""
function parseexpr(str::AbstractString)
    #####The escaping of dollars was a bit messy. I'm letting these comment stay here for a while untill a better documentation is in place.


    #println("parseexpr: '",str,"'")
    #dump(str)
    UnescapedDollar=unescape_dollar(str)
    #println("UnescapedDollar: '",UnescapedDollar,"'")
    #dump(UnescapedDollar)
    r = weval(W"ToExpression"(UnescapedDollar, W"StandardForm", W"Hold"))
    #println("r: '",r,"'")
    r.args[1]
end

"""
    W`expr`

Parse a string `expr` as a Wolfram Language expression. 
"""
macro W_cmd(str)
    #This macro takes the expresion within ` ` and feeds it to we wolfram engine using
    # the function parseexpr(string). The result is then back-converted to a julia MathLink expression.
    #quote parseexpr($(esc(Meta.parse("\"$(escape_string(str))\"")))) end


    #####The escaping of dollars was a bit messy. I'm letting these comment stay here for a while untill a better documentation is in place.
    
    ###Adding a set of string escapes for correct parsing
    #println("------")
    #println("str: '",str,"'")
    EscapedString=escape_string(str)
    #println("EscapedString: '",EscapedString,"'")
    DollarString=escape_dollar(EscapedString)
    #println("DollarString: '",DollarString,"'")
    FullString="\"$(DollarString)\""
    #FullStringII="\"$(EscapedString)\""

    #println("FullString: '",FullString,"'")
    #println("FullStringII: '",FullStringII,"'")

    ##Doing the parsing!
    string_expr = Meta.parse(FullString)
#    string_exprII = Meta.parse(FullStringII)
    #println("string_expr: '",string_expr,"'")
#    println("string_exprII: '",string_exprII,"'")

    
    subst_dict = Dict{WSymbol,Any}()
    if string_expr isa String
        string = string_expr
    elseif string_expr isa Expr && string_expr.head == :string
        for i in eachindex(string_expr.args)
            arg = string_expr.args[i]
            if !(arg isa String)
                sym = weval(W"Unique"(W"JuliaWSTP"))
                subst_dict[sym] = arg
                string_expr.args[i] = "($(sym.name))"
            end
        end
        string = join(string_expr.args)
    else
        error("Invalid string expression: $string_expr")
    end
    #println("subst_dict:",subst_dict)
    #println("string:",string)
    
    wexpr = parseexpr(string)
    #println("wexpr: '",wexpr,"'")
    to_julia_expr(wexpr, subst_dict)
end

"""
    escape_dollar(str::AbstractString)

Escapes the '\$' character to create a correct string interpretation when these are present.
"""
function escape_dollar(str::AbstractString)
    ####This function explicitly escapes the $ character to create a correct string interpretation when dollars are present.
    return replace(str,"\\\$"=>"\\\\\$")
end
"""
    unescape_dollar(str::AbstractString)

Un-escapes the '\$' character to create a correct string command to send to weval.
"""
function unescape_dollar(str::AbstractString)
    ####This function explicitly escapes the $ character to create a correct string interpretation when dollars are present.
    return replace(str,"\\\$"=>'\$')
end



function to_julia_expr(wexpr::WExpr, subst_dict)
    head = to_julia_expr(wexpr.head, subst_dict)
    args = map(x->to_julia_expr(x, subst_dict), wexpr.args)
    :(WExpr($head, [$(args...)]))
end
function to_julia_expr(wsym::WSymbol, dict)
    if haskey(dict, wsym)
        return esc(dict[wsym])
    else
        return wsym
    end
end
to_julia_expr(val, dict) = val

