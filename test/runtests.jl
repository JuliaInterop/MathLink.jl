using MathLink
using Test

import MathLink: WExpr, WSymbol

w = WExpr(WSymbol("Sqrt"), Any[2])
MathLink.meval(w)

w = WExpr(WSymbol("Sqrt"), Any[2.0])
MathLink.meval(w)
