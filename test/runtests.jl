using MathLink
using Test

import MathLink: WExpr, WSymbol

w = WExpr(WSymbol("Factorial"), Any[30])
@test_throws MathLink.MathLinkError MathLink.meval(w, Int)

w = WExpr(WSymbol("Sqrt"), Any[2.0])
@test MathLink.meval(w) == sqrt(2.0)


w = WExpr(WSymbol("Sqrt"), Any[2])
MathLink.meval(w)

link = MathLink._defaultlink()

u = MathLink.WReal("2.000000000000000000")
w = WExpr(WSymbol("Sqrt"), Any[u])
MathLink.put(link, WExpr(WSymbol("EvaluatePacket"), Any[w]))
MathLink.EndPacket(link)
packet, _ = MathLink.getfunction(link)
t = MathLink.GetRawType(link)
MathLink.get(link, Float64)

# Integers 228 (Int32) / 230 (Int64)
# Real 246 (Float64)
MathLink.meval(w)
