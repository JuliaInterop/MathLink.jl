

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
W2JuliaExpr(wexpr::WSymbol) = Symbol(wexpr.name)
W2JuliaExpr(wexpr::Number) = wexpr


###Dictionary with known funcitons and their translations
funcDict=Dict("Plus"=>:+,
              "Minus"=>:-,
              "Power"=>:^,
              "Times"=>:*,
              )
