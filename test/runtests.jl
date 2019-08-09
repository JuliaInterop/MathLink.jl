using MathLink
using Test

import MathLink: WExpr, WSymbol

w = WExpr(WSymbol("Factorial"), Any[30])
@test_throws MathLink.MathLinkError MathLink.meval(w, Int)
@test MathLink.meval(w, BigInt) == factorial(big(30))

@test w`Factorial`(20) === factorial(20)
@test parse(BigInt, string(w`Factorial`(30))) == factorial(big(30))



w = WExpr(WSymbol("Sqrt"), Any[2.0])
@test MathLink.meval(w) == sqrt(2.0)

@test w`Function[x,x*2]`(100) == 200

@test w`Integrate`(w`Log`(w`x`), (w`x`,1,w`E`)) == 1


