const graphics = (W"Graphics",W"GeoGraphics", W"Graphics3D", W"Legended")

Base.Multimedia.showable(::MIME"image/svg+xml", w::MathLink.WExpr) = in(w.head, graphics)
Base.show(io::IO, ::MIME"image/svg+xml", w::MathLink.WExpr) = print(io, weval(W"ExportString"(w, "SVG")))

Base.Multimedia.showable(::MIME"image/png", w::MathLink.WExpr) = in(w.head, graphics)
function Base.show(io::IO, ::MIME"image/png", w::MathLink.WExpr)
    x = weval(W"ExportByteArray"(w, "PNG"))
    write(io, x.args[1].args)
end


####If the flag for tex-output evaluation does not exist
## create it and set it to true.
if !@isdefined(MLtexOutput)
    MLtexOutput=true
end

export set_texOutput
function set_texOutput(x::Bool)
    global MLtexOutput
    MLtexOutput=x
end

export HasGraphicsHead, HasRecursiveGraphicsHead, W2Tex


#### Code to produce LaTex strings
W2Tex(x::WTypes) = weval(W`ToString@TeXForm[#]&`(x))

#### Allow latex string to be shown when supported. Relevant for the jupyter notebook.

HasRecursiveGraphicsHead(w::MathLink.WSymbol) = false
function HasRecursiveGraphicsHead(w::MathLink.WExpr)
    if HasGraphicsHead(w)
        return true
    end
    for arg in w.args
        if typeof(arg) == MathLink.WExpr
            ##Only check for MathLink Expressions
            if HasRecursiveGraphicsHead(arg)
                return true
            end
        end
    end
    return false
end

function HeadsEndsWith(HeadString,Target)
    ###Check if name ends with $Target
    if length(HeadString) >= length(Target)  
        return  HeadString[end-(length(Target)-1):end] == Target
    end
    return false
end


const graphics_heads = (W"Graphics", W"Graphics3D", W"Legended")

###Check if an expression has a grapics head
HasGraphicsHead(w::MathLink.WSymbol) = false
function HasGraphicsHead(w::MathLink.WExpr)
    HeadString = w.head.name
    ###Check for graphics related names not based on ending on Plot* or Chart*
    if in(w.head, graphics)
        return  true
    end

    HeadsEndsWith(HeadString,"Plot") && return true
    HeadsEndsWith(HeadString,"Chart") && return true
    HeadsEndsWith(HeadString,"Plot3D") && return true
    HeadsEndsWith(HeadString,"Chart3D") && return true
    return false
end

import Base.show
Base.Multimedia.showable(::MIME"text/latex", w::MathLink.WSymbol) = MLtexOutput
Base.show(io,::MIME"text/latex",x::MathLink.WSymbol) = print(io,"\$"*W2Tex(x)*"\$")

import Base.Multimedia.showable
function Base.Multimedia.showable(::MIME"text/latex", w::MathLink.WExpr)
    if !MLtexOutput
        return false
    end
    if HasRecursiveGraphicsHead(w)
        return false
    else
        return true
    end
end
function Base.show(io,::MIME"text/latex",x::MathLink.WExpr)
    print(io,"\$"*W2Tex(x)*"\$")
end



