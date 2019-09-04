using MathLink
using Test

import MathLink: WExpr, WSymbol

w = W"Factorial"(30)
@test_throws MathLink.MathLinkError weval(Int, w)
@test weval(BigInt, w) == factorial(big(30))

@test weval(W"Factorial"(20)) === factorial(20)

w = W"Sqrt"(2.0)
@test weval(w) == sqrt(2.0)

@test weval(W"Function"(W"x",W"Times"(W"x", 2))(100)) == 200

@test weval(W"Integrate"(W"Log"(W"x"), (W"x", 1, W"E"))) == 1

@test weval(W"Sin"(pi)) == 0
