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
    if env.ptr == C_NULL
        error("WSTP library not found, set WOLFRAM_APP_DIRECTORY environment variable")
    end
    # MLOpenString
    # local link
    err = Ref{Cint}()
    ptr = ccall((:WSOpenString, libwstp), CLink,
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

function open!(link::Link, args::Vector)
    if env.ptr == C_NULL
        error("WSTP library not found, set WOLFRAM_APP_DIRECTORY environment variable")
    end
    # MLOpenString
    # local link
    err = Ref{Cint}()
    ptr = ccall((:WSOpenArgcArgv, libwstp), CLink,
                 (Env, Cint, Ptr{Cstring}, Ptr{Cint}),
                 env, length(args), args, err)
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
        ccall((:WSClose, libwstp), Cvoid, (CLink,), link)
        link.ptr = C_NULL
        refcount_dec()
    end
end

function getname(link::Link)
    # WSLINK WSGetLinkName(WSLINK link)
    ptr = ccall((:WSUTF8LinkName, libwstp), Cstring, (CLink,), link)
    ptr == C_NULL && throw(MathLinkError(link))
    str = unsafe_string(ptr)
    ccall((:WSReleaseUTF8LinkName, libwstp), Cvoid, (CLink,Cstring), link, ptr)
    return str
end

function duplicate(link::Link, name::AbstractString)
    # WSLINK WSDuplicateLink(WSLINK link, int *errp)
    err = Ref{Cint}()
    ptr = ccall((:WSDuplicateLink, libwstp), CLink, (CLink, Cstring, Ptr{Cint}), link, name, err)
    if err[] != 0
        throw(MathLinkError(link))
    end
    newlink = Link(ptr)
    refcount_inc()
    finalizer(close, newlink)
    return newlink
end

"""
    local_kernel_path()

The path to the local kernel. This is used to launch a link to the kernel.
"""
function local_kernel_path()
    read(`$(wolfram_app_discovery()) default --raw-value kernel-executable-path`, String)
end



function _defaultlink()
    if defaultlink.ptr == C_NULL
        kernel = local_kernel_path()
        args = [
            "-linkname",
            "\"$(escape_string(kernel))\" -wstp",
            "-linkmode",
            "launch",
        ]
        open!(defaultlink, args)

        # Ignore first input packet
        @assert nextpacket(defaultlink) == PKT_INPUTNAME
        newpacket(defaultlink)
    end
    return defaultlink
end


mutable struct Mark
    link::Link
    ptr::Ptr{Cvoid}
end
const CMark = Ptr{Cvoid}
Base.cconvert(::Type{CMark}, mark::Mark) = mark.ptr

# we don't overload Base.mark as it has different behaviour
function Mark(link::Link)
    # WSMARK WSCreateMark(WSLINK link)
    ptr = ccall((:WSCreateMark, libwstp), Ptr{Cvoid}, (CLink,), link)
    ptr == C_NULL && throw(MathLinkError(link))
    mark = Mark(link, ptr)
    refcount_inc()
    finalizer(close, mark)
    mark
end

function Base.seek(link::Link, mark::Mark, offset::Integer=Cint(0))
    # WSMARK WSSeekToMark(WSLINK link,WSMARK mark,int n)
    ptr = ccall((:WSSeekToMark, libwstp), Ptr{Cvoid},
                (CLink, CMark, Cint), link, mark, offset)
    ptr == C_NULL && throw(MathLinkError(link))
    return nothing
end

function Base.close(mark::Mark)
    if mark.ptr != C_NULL
        # void WSDestroyMark(WSLINK link,WSMARK mark)
        ccall((:WSDestroyMark, libwstp), Cvoid,
              (CLink, CMark), mark.link, mark)
        mark.ptr = C_NULL
        refcount_dec()
    end
end
