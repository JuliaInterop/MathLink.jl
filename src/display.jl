import Base: show

show(io::IO, ::MIME"text/html", p::MExpr{:Graphics}) =
  print(io, ExportString(p, "SVG"))

show(io::IO, ::MIME"image/png", p::MExpr{:Graphics3D}) =
  print(io, @math ExportString($p, "PNG"))
