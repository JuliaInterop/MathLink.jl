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

function parseexpr(str::AbstractString)
    r = weval(W"ToExpression"(str, W"StandardForm", W"Hold"))
    r.args[1]
end

macro W_cmd(str)
    parseexpr(str)
end
