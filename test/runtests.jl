using MathLink
using Test

import MathLink: WExpr, WSymbol

@testset "integers" begin
    w = W"Factorial"(30)
    @test_throws MathLink.MathLinkError weval(Int, w)
    @test weval(BigInt, w) == factorial(big(30))
    @test weval(W"Factorial"(20)) === factorial(20)
    @test weval(W`Factorial[x]`; x=20) === factorial(20)

    @test weval(Float64, W"N"(W"Log"(factorial(big(30))),100)) == log(Float64(factorial(big(30))))
    @test weval(BigFloat, W"N"(W"Log"(factorial(big(30))),100)) == log(factorial(big(30)))
end

@testset "floats" begin
    w = W"Sqrt"(2.0)
    @test weval(w) == sqrt(2.0)
    w = W"Sqrt"(2f0)
    @test weval(Float32, w) == sqrt(2f0)
end

@testset "BigFloats" begin
    @test weval(BigFloat, W"N"(W"Pi",200)) == big(pi)
    @test abs(weval(Float64, W"Sin"(big(pi)))) < sin(big(pi))
end

@testset "Irrationals" begin
    @test weval(W"Sin"(pi)) == 0
end

@testset "expressions" begin
    @test weval(W"Function"(W"x",W"Times"(W"x", 2))(100)) == 200

    @test weval(W"Integrate"(W"Log"(W"x"), (W"x", 1, W"E"))) == 1

    @test weval(W`Integrate[Log[x], {x,1,E}]`) == 1
end

@testset "warray" begin
    w = Array{Any,3}(undef, 2,1,3)
    w[1,:,:] .= [1 2.0 W"Sin"(W"a")]
    w[2,:,:] .= [W"Factorial"(20) W"Cos"(-1.0) -3]
    r = W"Equal"(warray(w),W`{{{1,2.0,Sin[a]}},{{Factorial[20],Cos[-1.0],-3}}}`)
    @test weval(r).name == "True"
end
