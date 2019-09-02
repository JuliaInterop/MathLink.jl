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

function weval(link::Link, T, expr)
    put(link, W"EvaluatePacket"(expr))
    endpacket(link)
    handle_packets(link, T)
end

"""
    weval([T,] expr)

Evaluate expression `expr`, returning a value of type `T` (default = `Any`).
"""
weval(T, expr) = weval(_defaultlink(), T, expr)
weval(expr) = weval(Any, expr)


function wevalstr(link, T, str::AbstractString)
    weval(link, W"ToExpression"(str), T)
end
wevalstr(T, expr) = wevalstr(_defaultlink(), T, expr)
wevalstr(expr) = wevalstr(Any, expr)

function parseexpr(str::AbstractString)
    r = weval(W"ToExpression"(str, W"InputForm", W"Hold"))
    r.args[1]
end
