using MathLink
using Test

import MathLink: WExpr, WSymbol



@testset "W2Mstr" begin
    ###Test of a naive MathLink to Mathematica converter function (the results can be copied into mathematica directly)

    @testset "Basic Algebra" begin
        @test W2Mstr(W"a") == "a"
        @test W2Mstr(W"x") == "x"
        @test W2Mstr(W"x"+W"y") == "(x + y)"
        @test W2Mstr(W`Sqrt[a + b]`) == "Sqrt[(a + b)]"
        @test W2Mstr(W`Pow[x,2]`) == "Pow[x,2]"
        @test W2Mstr(W`x^2`) == "(x^2)"
        @test W2Mstr(W`a+b`) == "(a + b)"
        @test W2Mstr(weval(W`a + c + v`)) == "(a + c + v)"
        @test W2Mstr(2) == "2"
        @test W2Mstr(W`x`) == "x"
        @test W2Mstr(W"Sin"(W"x")) == "Sin[x]"
        @test W2Mstr(W`Sin[x]`) == "Sin[x]"
        
    end    
    @testset "Nested functions" begin
        @test W2Mstr(weval(W`a + c*b + v`)) == "(a + (b*c) + v)"
        @test W2Mstr(weval(W`(a + c)*(b + v)`)) == "((a + c)*(b + v))"
        @test W2Mstr(weval(W`a^(b+c)`)) == "(a^(b + c))"
        @test W2Mstr(weval(W`a^2`)) == "(a^2)"
        @test W2Mstr(weval(W`e+a^(b+c)`)) == "((a^(b + c)) + e)"
        @test W2Mstr(weval(W`a + c + v + Sin[2 + x + Cos[q]]`)) == "(a + c + v + Sin[(2 + x + Cos[q])])"
        set_GreedyEval(true)
        @test W2Mstr(W"a"+W"c"+W"v"+W"Sin"(2 +W"x" + W"Cos"(W"q"))) == "(a + c + v + Sin[(2 + x + Cos[q])])"
        set_GreedyEval(false)
        @test W2Mstr(W"a"+W"c"+W"v"+W"Sin"(2 +W"x" + W"Cos"(W"q"))) == "(((a + c) + v) + Sin[((2 + x) + Cos[q])])"

        @test W2Mstr(W`Sqrt[x+Sin[y]+z^(3/2)]`) == "Sqrt[(x + Sin[y] + (z^(3*(2^-1))))]"

    end

    @testset "Complex values" begin
        @test W2Mstr(weval(W`2*I`)) == "(2*I)"
        @test W2Mstr(weval(W`2/I`)) == "(-2*I)"
        @test W2Mstr(W`2 + 0*I`) == "(2 + (0*I))"
        @test W2Mstr(W"Complex"(W"c",0)) == "c"
        @test W2Mstr(weval(W"Complex"(W"c",0))) == "c"
        @test W2Mstr(weval(W"Complex"(W"c",W"b"))) == "(c+b*I)"
        @test W2Mstr(im) == "(1*I)"
        @test W2Mstr(2*im) == "(2*I)"
    end

    @testset "Factions" begin
        @test W2Mstr(W`3/4`) == "(3*(4^-1))"
        @test W2Mstr(3//4) == "(3/4)"
        @test W2Mstr(W`b/c`) == "(b*(c^-1))"
        @test W2Mstr(W`b/(c^(a+c))`) == "(b*((c^(a + c))^-1))"
        @test W2Mstr(W`(b^2)/(c^3)`) == "((b^2)*((c^3)^-1))"
        @test W2Mstr(weval(W`(b^2)/(c^3)`)) == "((b^2)*(c^-3))"
    end

    @testset "Lists & Arrays" begin
        @test W2Mstr([W`x`,W`a`]) == "{x,a}"
        @test W2Mstr([W`x`]) == "{x}"
        @test W2Mstr([W`x` W`y`; W`z` W`x`]) == "{{x,y},{z,x}}"
    end
    
end




@testset "integers" begin
    w = W"Factorial"(30)
    @test_throws MathLink.MathLinkError weval(Int, w)
    @test weval(BigInt, w) == factorial(big(30))
    @test weval(W"Factorial"(20)) === factorial(20)
    @test weval(W`Factorial[x]`; x=20) === factorial(20)

    @test weval(Float64, W"N"(W"Log"(factorial(big(30))),100)) == log(Float64(factorial(big(30))))
    @test weval(BigFloat, W"N"(W"Log"(factorial(big(30))),100)) == log(factorial(big(30)))
end

@testset "Int128" begin
    ###
    A=Int128(294857324952348732)
    B=Int128(234424444352343456)
    @test typeof(weval(A)) == Int64
    @test typeof(weval(B)) == Int64
    @test typeof(weval(A*B)) == MathLink.WInteger
    @test weval(A*B).value == "$(A*B)"
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

@testset "comparisons" begin
    @test W"Sin"(1) == W"Sin"(1)
    @test W`Sin[1]` == W`Sin[1]`
    @test W`Sin[1]` == W"Sin"(1)

    @test W"Sin"(1) != W"Sin"(2)
    @test W`Sin[1]` != W`Sin[2]`
    @test W`Sin[1]` != W"Sin"(2)

    @test W"Sin"(1) != W"Sin"(1,1)
end

@testset "arrays" begin
    X = 1:10
    @test weval(W"Total"(X)) == sum(X)

    A = [1 2 3; 4 5 6]; x = [1,3,7];
    @test weval(W"Dot"(A,x)) == WExpr(W"List",A*x)
end

@testset "interpolation" begin
    x = exp(1)
    @test W`Sin[$x]` == W"Sin"(x)

    @test W`Cos[$(log(2))]` == W"Cos"(log(2))
end



@testset "README" begin
    
    ###The operations mentioned for MathLink the README
    sin1 = W"Sin"(1.0)
    @test sin1 == W"Sin"(1.0)
    
    sinx = W"Sin"(W"x")
    @test sinx == W"Sin"(W"x")
    @test W`Sin[1]` == W"Sin"(1)
    
    @test weval(sin1) == 0.8414709848078965

    @test weval(sinx) == W"Sin"(W"x")
    
    @test weval(W"Integrate"(sinx, (W"x", 0, 1))) == W"Plus"(1, W"Times"(-1, W"Cos"(1)))
end


@testset "GreedyEval" begin
    ###Testing turning on and turning of the greedy evaluation
    ###The default is "false"
    @test W"a"+W"b" == W"Plus"(W"a",W"b")
    @test W"a"+W"a" == W"Plus"(W"a",W"a")
    @test W"a"-W"a" == W"Plus"(W"a",W"Minus"(W"a"))
    set_GreedyEval(true)
    @test W"a"+W"b" == W"Plus"(W"a",W"b")
    @test W"a"+W"a" == W"Times"(2,W"a")
    @test W"a"-W"a" == 0
    set_GreedyEval(false)
    @test W"b"+W"b" == W"Plus"(W"b",W"b")
    set_GreedyEval(true)
end

@testset "Rationals" begin
    #### Test Rationals parts
    @test (4//5)*W"a" == weval(W`4 a/5`)
    @test W"a"*(4//5) == weval(W`4 a/5`)
    @test (4//5)/W"a" == weval(W`4/(a 5)`)
    @test W"a"/(4//5) == weval(W`5 a/4`)
    @test weval(1//2) == weval(W`1/2`)
    @test weval([1//2,W`a`]) == W"List"(weval(W`1/2`),W`a`)
end

@testset "Complex Numbers" begin
    #### Test imaginary parts
    @test im*W"a" == weval(W`I * a`)
    @test (2*im)*W"a" == weval(W`2 I a`)
    @test im/W"a" == weval(W`I / a`)
    @test W"a"/(2* im) == weval(W`- I a/2`)
    @test im*(im*W"c") == weval(W`-c`)
  
    
    #####Testing that complex numbers can be put in weval
    @test weval(im+2) == weval(W`I+2`)
    @test weval(im*2) == weval(W`I*2`)
    @test weval(im) == weval(W`I`)
    
    @test (3*im)*(2*im)*W"a" == weval(W`-6 a`)
    @test (3*im) + (2*im)*W"a" == weval(W`3 I + 2 I a`)
    @test (3*im) - (2*im)*W"a" == weval(W`3 I - 2 I a`)
end


@testset "Unary operators" begin
    @test +W"b" == W"b"
    @test +W`a+b` == W`a+b`
    @test -W"b" == W`-b`
    @test -W`a-b` == W`-a+b`
end




@testset "Matrix Multiplication" begin

    P12 = [ 0 1 ; 1 0 ]
    @test P12 * [W"a" W"b" ; W`a+b` 2] == [ W`a+b` 2 ; W"a" W"b"]
    @test [W"a" W"b" ; W`a+b` 2] * P12  == [ W"b" W"a" ; 2 W`a+b`]
    
    #### test larger matrix
    @test P12 * [W"a" W"b" ; W`a+b` W`v+2`] == [ W`a+b` W`2+v` ; W"a" W"b"]
    @test [W"a" W"b" ; W`a+b` W`v+2`] * P12  == [ W"b" W"a" ; W`2+v` W`a+b`]

    #### test larger matrix
    P13 = fill(0,(3,3))
    P13[1,3]=1
    P13[3,1]=1
    P13[2,2]=1
    Mat = fill(W`a+d`,3,3)
    Mat[:,:] = [W`a+d` W`a+d` W`f*g`; W`a+b` W`v+2` W`f*g` ;  W`d+b`  W`a+b`  W`a+b`]
    P13 * Mat * P13
    #HM2 = P13*Mat*P13

    ###A real live eample
    P14 = fill(0,(4,4))
    P14[1,4]=1
    P14[4,1]=1
    P14[2,2]=1
    P14[3,3]=1
    Mat = MathLink.WExpr[W"Plus"(W"J1245", W"J1346", W"J2356") W"Plus"(W"Times"(W"Complex"(0, 1), W"J1356"), W"Times"(W"Complex"(0, -1), W"J2346")) W"Plus"(W"Times"(W"Complex"(0, -1), W"J1256"), W"Times"(W"Complex"(0, 1), W"J2345")) W"Plus"(W"J1246", W"Times"(-1, W"J1345")); W"Plus"(W"Times"(W"Complex"(0, -1), W"J1356"), W"Times"(W"Complex"(0, 1), W"J2346")) W"Plus"(W"J1245", W"Times"(-1, W"J1346"), W"Times"(-1, W"J2356")) W"Plus"(W"J1246", W"J1345") W"Plus"(W"Times"(W"Complex"(0, -1), W"J1256"), W"Times"(W"Complex"(0, -1), W"J2345")); W"Plus"(W"Times"(W"Complex"(0, 1), W"J1256"), W"Times"(W"Complex"(0, -1), W"J2345")) W"Plus"(W"J1246", W"J1345") W"Plus"(W"Times"(-1, W"J1245"), W"J1346", W"Times"(-1, W"J2356")) W"Plus"(W"Times"(W"Complex"(0, -1), W"J1356"), W"Times"(W"Complex"(0, -1), W"J2346")); W"Plus"(W"J1246", W"Times"(-1, W"J1345")) W"Plus"(W"Times"(W"Complex"(0, 1), W"J1256"), W"Times"(W"Complex"(0, 1), W"J2345")) W"Plus"(W"Times"(W"Complex"(0, 1), W"J1356"), W"Times"(W"Complex"(0, 1), W"J2346")) W"Plus"(W"Times"(-1, W"J1245"), W"Times"(-1, W"J1346"), W"J2356")]
    ####WE just want to see that the numbers can be computed
    Mat * P14
    P14 * Mat
    P14 * Mat* P14
end




@testset  "Find Graphics" begin
    @test !HasGraphicsHead(W"a")
    @test HasGraphicsHead(W`Plot[x,{x,0,1}]`)
    @test HasGraphicsHead(W`ListPlot[x,{x,0,1}]`)
    @test HasGraphicsHead(W`ListLinePlot3D[x,{x,0,1}]`)
    @test HasGraphicsHead(W`Plot3D[x,{x,0,1}]`)
    @test !HasGraphicsHead(W"a"+W"b")
    @test HasGraphicsHead(weval(W`Plot[x,{x,0,1}]`))
    @test !HasGraphicsHead(W`{Plot[x,{x,0,1}],Plot[x^2,{x,0,1}]}`)
    @test !HasGraphicsHead(weval(W`{Plot[x,{x,0,1}],Plot[x^2,{x,0,1}]}`))

    @test !HasRecursiveGraphicsHead(W`{2,a+v,{4+d}}`)
    @test HasRecursiveGraphicsHead(W`Plot[x,{x,0,1}]`)
    @test HasRecursiveGraphicsHead(W`{2,Plot[x^2,{x,0,1}]}`)
    @test HasRecursiveGraphicsHead(W`{a+b,Plot[x^2,{x,0,1}]}`)
    @test HasRecursiveGraphicsHead(W`{Plot[x,{x,0,1}],Plot[x^2,{x,0,1}]}`)
    @test HasRecursiveGraphicsHead(W`{1,{Plot[x,{x,0,1}],Plot[x^2,{x,0,1}]}}`)
    @test HasRecursiveGraphicsHead(weval(W`{Plot[x,{x,0,1}],Plot[x^2,{x,0,1}]}`))
end



@testset "W2Tex - LaTex conversion" begin
    @test W2Tex(W`(a+b)^(b+x)`) == "(a+b)^{b+x}"
    @test W2Tex(W`a`) == "a"
    @test W2Tex(W`ab`) == "\\text{ab}"
    @test W2Tex(W`ab*cd`) == "\\text{ab} \\text{cd}"

   
    ###Testing that MIME form exists for the text/latex option of show.
    io = IOBuffer();
    context = IOContext(io, :limit => true, :displaysize => (10, 10)) 
    @test sprint(show,"text/plain",W"a"; context) == "W\"a\""
    @test sprint(show,"text/plain",W"a"+W"b"; context) == "W`Plus[a, b]`"

    set_texOutput(true)
    @test sprint(show,"text/latex",W"a"+W"b") == "\$a+b\$"
    @test showable("text/latex",W"a"+W"b")
    set_texOutput(false)
    @test !showable("text/latex",W"a"+W"b")
end

