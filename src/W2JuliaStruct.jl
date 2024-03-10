

export W2JuliaStruct

"""
W2JuliaStruct is designed primarily to convert wolfram structures to Julia structures. This includes conversions of Mathematica lists to Julia vectors and Mathematica associations to Julia dictionaries.

Some examples or tests that will evaluate to true:

        using Test
        @test W2JuliaStruct(W`{1,2,3}`) == [1,2,3]
        @test W2JuliaStruct([1,2,3]) == [1,2,3]
        @test W2JuliaStruct(W`{1,2,3}`) == [1,2,3]
        @test W2JuliaStruct(W`{1,a,{1,2}}`) == [1,W"a",[1,2]]
        @test W2JuliaStruct([.1,W`{1,a,3}`]) == [.1,[1,W"a",3]]

        @test W2JuliaStruct(Dict( 1 => "A" , "B" => 2)) ==Dict( 1 => "A" , "B" => 2)


        @test W2JuliaStruct(W`Association["A" -> "B", "C" -> "D"]`) == Dict( "A" => "B" , "C" => "D")

        @test W2JuliaStruct(W`Association["A" -> {1,a,3}, "B" -> "C"]`) == Dict( "A" => [1,W"a",3] , "B" => "C")


W2JuliaStruct does not convert expressions to Julia functions, as not all functions will be able to evaluate when WSymbols are present.
 
"""
W2JuliaStruct(X::Vector) = [ W2JuliaStruct(x) for x in X]
function W2JuliaStruct(X::Dict)
    NewDict = Dict()
    for key in keys(X)
        NewDict[key] = W2JuliaStruct(X[key])
    end
    return NewDict
end



W2JuliaStruct(X::Number) = X
W2JuliaStruct(X::String) = X
W2JuliaStruct(X::MathLink.WSymbol) = X
function W2JuliaStruct(X::MathLink.WExpr)
    if X.head == W"List"
        return W2JuliaStruct.(X.args)
    elseif X.head == W"Association"
        W2JuliaStructAccociation(X)
    else
        return X
    end
end


function W2JuliaStructAccociation(Asso::MathLink.WExpr)
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
        D[Rule.args[1]]=W2JuliaStruct(Rule.args[2])
    end
    return D
end
