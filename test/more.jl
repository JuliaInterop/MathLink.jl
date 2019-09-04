using MathLink
import MathLink: put, get, endpacket, nextpacket, getnextraw

link = MathLink._defaultlink()

X = rand(80,120)

put(link, X)
endpacket(link)
pkt = nextpacket(link)
t = getnextraw(link)

import MathLink: loopbackopen, CLink, mlib, getfunction

rmeterp = Ref(C_NULL)
rleaftoken = Ref(C_NULL)
rdepth = Ref{Clong}(0)

loopback = loopbackopen()

ccall((:MLGetArrayTypeWithDepthAndLeafType, mlib), Cint,
      (CLink, CLink, Ptr{Ptr{Cvoid}}, Ptr{Clong}, Ptr{Ptr{Cvoid}}),
      link, loopback, rmeterp, rdepth, rleaftoken)

sz = ntuple(i -> getfunction(loopback)[2], rdepth[])

tk = MathLink.getrawtype(link)
Y = Array{Float64}(undef, sz)

ccall((:MLGetBinaryNumberArrayData, mlib), Cint,
      (CLink, Ptr{Cvoid}, Ptr{Cvoid}, Clong, Clong),
      link, rmeterp[], Y, sizeof(Y), tk)

@test X == Y







w = WExpr(WSymbol("Sqrt"), Any[2])
MathLink.meval(w)


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



using MathLink
import MathLink: WExpr, WSymbol

link = MathLink._defaultlink()

MathLink.put(link, WExpr(WSymbol("EvaluatePacket"), Any[WExpr(WSymbol("ToExpression"), Any["Function[x,x*2][3]", WSymbol("InputForm"), WSymbol("Hold")])]))
MathLink.EndPacket(link)
packet, _ = MathLink.getfunction(link)

t = MathLink.GetNextRaw(link)
MathLink.getargcount(link)
t = MathLink.GetNextRaw(link)
MathLink.get(link, WSymbol)

t = MathLink.GetNext(link)
MathLink.getargcount(link)
MathLink.get(link, WSymbol)


MathLink.getfunction(link)

t = MathLink.GetRawType(link)
MathLink.getargcount(link)
