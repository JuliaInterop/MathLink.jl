const graphics = (W"Graphics", W"Graphics3D", W"Legended")

Base.Multimedia.showable(::MIME"image/svg+xml", w::MathLink.WExpr) = in(w.head, graphics)
Base.show(io::IO, ::MIME"image/svg+xml", w::MathLink.WExpr) = print(io, weval(W"ExportString"(w, "SVG")))

Base.Multimedia.showable(::MIME"image/png", w::MathLink.WExpr) = in(w.head, graphics)
function Base.show(io::IO, ::MIME"image/png", w::MathLink.WExpr)
    x = weval(W"ExportByteArray"(w, "PNG"))
    write(io, x.args[1].args)
end
