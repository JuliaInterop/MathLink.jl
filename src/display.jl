import Base: writemime

writemime(io::IO, ::MIME"text/html", p::MExpr{:Graphics}) =
  print(io, ExportString(p, "SVG"))

writemime(io::IO, ::MIME"image/png", p::MExpr{:Graphics3D}) =
  print(io, @math ExportString($p, "PNG"))
