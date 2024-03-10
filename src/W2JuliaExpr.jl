

export W2JuliaExpr

"""
Converts MathLink `WExpr`essions to Julia `Expr`essions
"""
function W2JuliaExpr(wexpr::WExpr)
    ####Check if the operator has an alias
    if haskey(funcDict, wexpr.head.name)
        Operator=funcDict[wexpr.head.name]
    else
        Operator=Symbol(wexpr.head.name)
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
              "Sin"=>:sin,
              "Cos"=>:cos,
              )
