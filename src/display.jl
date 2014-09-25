Base.writemime(io::IO, ::MIME"text/html", p::MExpr{:Graphics}) =
  print(io, ExportString(p, "SVG"))

# Base.writemime(io::IO, ::MIME"image/png", p::MExpr{:Graphics3D})
