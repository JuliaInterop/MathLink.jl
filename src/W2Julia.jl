

export W2Julia

W2Julia(X::Number) = X
W2Julia(X::String) = X
W2Julia(X::MathLink.WSymbol) = X
function W2Julia(X::MathLink.WExpr)
    if X.head == W"List"
        return W2Julia.(X.args)
    elseif X.head == W"Association"
        W2JuliaAccociation(X)
    else
        return X
    end
end


function W2JuliaAccociation(Asso::MathLink.WExpr)
    if Asso.head != W"Association"
        error("Not an Association")
    end
    ##Wprint(Asso)
    if Asso.head != W"Association"
        error("Not an association")
    end
    D=Dict()
    for Rule in Asso.args
        if Rule.head != W"Rule"
            error("not a rule")
        end
        if length(Rule.args) != 2
            error("Bad rule")
        end
        D[Rule.args[1]]=W2Julia(Rule.args[2])
    end
    return D
end
