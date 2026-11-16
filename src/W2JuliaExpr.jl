

export W2JuliaExpr

"""
Converts MathLink `WExpr`essions to Julia `Expr`essions
"""
function W2JuliaExpr(wexpr::WExpr)
    head = wexpr.head
    if head isa WSymbol
        # Use the Julia function alias when available, otherwise lowercase the name.
        Operator = Base.get(funcDict, head.name, Symbol(lowercase(head.name)))
    elseif head isa WExpr
        # Convert the compound head into a nested Julia call.
        Operator = W2JuliaExpr(head)
    else
        throw(ArgumentError(
            "W2JuliaExpr expected a symbol or expression as the call head, got $(repr(head))"
        ))
    end
    return Expr(:call,Operator,[W2JuliaExpr(arg) for arg in wexpr.args]...)
end
W2JuliaExpr(wexpr::WSymbol) = Base.get(symbolDict, wexpr.name, Symbol(wexpr.name))
W2JuliaExpr(wexpr::Number) = wexpr
W2JuliaExpr(wexpr::AbstractString) = wexpr


# Julia names for Wolfram expression heads.
funcDict = Dict("Plus" => :+,
                "Minus" => :-,
                "Power" => :^,
                "Times" => :*,
                "Rational" => ://,
                )

# Julia names for Wolfram symbols used as values or arguments.
symbolDict = Dict{String,Union{Symbol,Expr}}("Pi" => :π,
                                             "E" => :ℯ,
                                             "I" => :im,
                                             )
