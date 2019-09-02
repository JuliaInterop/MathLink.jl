"""
    Link

A WSTP link object.

# External links
 - [WSLINK](https://reference.wolfram.com/language/ref/c/WSLINK.html)
"""
mutable struct Link
    ptr::Ptr{Cvoid}
end

const CLink = Ptr{Cvoid}
Base.cconvert(::Type{CLink}, link::Link) = link.ptr

# default link to use if none other is provided
# this will be initialized lazily
const defaultlink = Link(C_NULL)

# we define an in-place version to operate on defaultlink
function open!(link::Link, args::AbstractString)
    # MLOpenString
    # local link
    err = Ref{Cint}()
    ptr = ccall((:MLOpenString, mlib), CLink,
                 (Env, Cstring, Ptr{Cint}),
                 env, args, err)
    if err[] != 0
        error("Could not open MathLink link")
    end
    link.ptr = ptr
    
    refcount_inc()
    finalizer(close, link)
    return link
end

open(args::AbstractString) = open!(Link(C_NULL), args)

function Base.close(link::Link)
    if link.ptr != C_NULL
        ccall((:MLClose, mlib), Cvoid, (CLink,), link)
        link.ptr = C_NULL
        refcount_dec()
    end
end

function _defaultlink()
    if defaultlink.ptr == C_NULL
        args = "-linkname '\"$mker\" -mathlink' -linkmode launch"
        open!(defaultlink, args)
        
        # Ignore first input packet
        @assert nextpacket(defaultlink) == PKT_INPUTNAME
        NewPacket(defaultlink)
    end
    return defaultlink
end
