Base.Multimedia.showable(::MIME"image/svg+xml", w::MathLink.WExpr) = w.head == W"Graphics"
Base.show(io::IO, ::MIME"image/svg+xml", w::MathLink.WExpr) = print(io, weval(W"ExportString"(w, "SVG")))

Base.Multimedia.showable(::MIME"image/png", w::MathLink.WExpr) = w.head == W"Graphics"
function Base.show(io::IO, ::MIME"image/png", w::MathLink.WExpr)
    x = weval(W"ExportByteArray"(w, "PNG"))
    write(io, x.args[1].args)
end
