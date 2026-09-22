

export W2JuliaExpr

"""
Converts MathLink `WExpr`essions to Julia `Expr`essions
"""
function W2JuliaExpr(wexpr::WExpr)
    ####Check if the operator has an alias
    if haskey(funcDict, wexpr.head.name)
        ####Use the alias
        Operator=funcDict[wexpr.head.name]
    else
        ####Use the name directly as a symbol (but in lowercase)
        Operator=Symbol(lowercase(wexpr.head.name))
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
