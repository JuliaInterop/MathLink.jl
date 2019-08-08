mutable struct Env
    ptr::Ptr{Cvoid}
end
mutable struct Link
    ptr::Ptr{Cvoid}
end

const CEnv = Ptr{Cvoid}
const CLink = Ptr{Cvoid}

Base.cconvert(::Type{CEnv}, env::Env) = env.ptr
Base.cconvert(::Type{CLink}, link::Link) = link.ptr

function initialize!(env::Env)
    # MLInitialize
    ptr = ccall((:MLInitialize, mlib), CEnv, (Cstring,), C_NULL)
    if ptr == C_NULL
        error("Could not initialize MathLink library")
    end
    env.ptr = ptr
    return env
end
function deinitialize!(env::Env)
    # void WSDeinitialize(WSENV env)
    ccall((:MLDeinitialize, mlib), Cvoid, (CEnv,), env)
    env.ptr = C_NULL
end

function open!(link::Link, env::Env, args::AbstractString)
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
    finalizer(close, defaultlink)
    return link
end

function Base.close(link::Link)
    if link.ptr != C_NULL
        ccall((:MLClose, mlib), Cvoid, (CLink,), link)
        link.ptr = C_NULL
        refcount_dec()
    end    
end

struct MathLinkError <: Exception
    msg::String
end
function MathLinkError(link::Link)
    msg = unsafe_string(ccall((:MLErrorMessage, mlib), Cstring, (CLink,), link))
    ClearError(link)
    NewPacket(link)
    MathLinkError(msg)
end

for f in [:Error :ClearError :EndPacket :NextPacket :NewPacket]
  fstr = string("ML", f)
  @eval $f(link::Link) = ccall(($fstr, mlib), Cint, (CLink,), link)
end

mlerror(link, name) = error("MathLink Error $(Error(link)) in $name: " * ErrorMessage(link))

macro wschk(expr)
    link = expr.args[5] # first argument
    quote
        if $(esc(expr)) == 0
            throw(MathLinkError($(esc(link))))
        end
    end
end

function putfunction(link::Link, w::WSymbol, nargs::Integer)
    # int MLPutUTF8Function(( MLLINK l , const unsigned char * s , int v , int n ) 
    @wschk ccall((:MLPutUTF8Function, mlib), Cint,
                 (CLink, Ptr{UInt8}, Cint, Cint),
                 link, w.name, sizeof(w.name), nargs)
    nothing
end
function getfunction(link::Link)
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_nargs = Ref{Cint}()
    # int MLGetUTF8Function( MLLINK l , const unsigned char ** s , int * v , int * n )
    @wschk ccall((:MLGetUTF8Function, mlib), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_nargs)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8Symbol(MLLINK link,const unsigned char *s,int len)
    ccall((:MLReleaseUTF8Symbol, mlib), Cvoid,
          (CLink, Ptr{UInt8}, Cint),
          link, r_str[], r_bytes[])
    return WSymbol(str), r_nargs[]
end

# WSymbol
function put(link::Link, w::WSymbol)
    # int MLPutUTF8Symbol(MLLINK link,const unsigned char *s,int len)
    @wschk ccall((:MLPutUTF8Symbol, mlib), Cint,
                 (CLink, Ptr{UInt8}, Cint),
                 link, w.name, sizeof(w.name))    
    nothing
end
function get(link::Link, ::Type{WSymbol})
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_chars = Ref{Cint}()
    # int MLGetUTF8Symbol(MLLINK link,const unsigned char **s,int *b,int *c)
    @wschk ccall((:MLGetUTF8Symbol, mlib), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_chars)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8Symbol(MLLINK link,const unsigned char *s,int len)
    ccall((:MLReleaseUTF8Symbol, mlib), Cvoid,
          (CLink, Ptr{UInt8}, Cint),
          link, r_str[], r_bytes[])
    return WSymbol(str)
end

# WReal/WInteger
function put(link::Link, w::WReal)
    # int MLPutRealNumberAsUTF8String(MLLINK l, const unsigned char *s, int n)
    @wschk ccall((:MLPutRealNumberAsUTF8String, mlib), Cint,
                 (CLink, Ptr{UInt8}, Cint),
                 link, w.value, sizeof(w.value))    
    nothing
end
function get(link::Link, ::Type{W}) where W <: Union{WReal,WInteger}
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_chars = Ref{Cint}()
    # int MLGetNumberAsUTF8String(MLLINK l, const unsigned char **s, int *v, int *c)
    @wschk ccall((:MLGetNumberAsUTF8String, mlib), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_chars)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8String(MLLINK link,const unsigned char *s,int len)
    ccall((:MLReleaseUTF8String, mlib), Cvoid,
          (CLink, Ptr{UInt8}, Cint),
          link, r_str[], r_bytes[])
    return W(str)
end


# String
function put(link::Link, str::Union{String,SubString})
    # int MLPutUTF8String(MLLINK link,const unsigned char *s,int len)
    @wschk ccall((:MLPutUTF8String, mlib), Cint,
                 (CLink, Ptr{UInt8}, Cint),
                 link, str, sizeof(str))
    nothing
end
function get(link::Link, ::Type{String})
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_chars = Ref{Cint}()
    # int MLGetUTF8String(MLLINK link,const unsigned char **s,int *b,int *c)
    @wschk ccall((:MLGetUTF8String, mlib), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_chars)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8String(MLLINK link,const unsigned char *s,int len)
    ccall((:MLReleaseUTF8String, mlib), Cvoid,
          (CLink, Ptr{UInt8}, Cint),
          link, r_str[], r_bytes[])
    return str
end

for (f, T) in [
    (:Integer8, Int8)
    (:Integer16, Int16)
    (:Integer32, Int32)
    (:Integer64, Int64)
    (:Real32, Float32)
    (:Real64, Float64)
]
    @eval begin
        function put(link::Link, x::$T)
            # note slightly bizarre handling of Float32
            @wschk ccall(($(QuoteNode(Symbol(:MLPut, f))), mlib), Cint, (CLink, $(f == :Real32 ? Float64 : T)), link, x)
            nothing
        end
        function get(link::Link, ::Type{$T})
            r = Ref{$T}()
            @wschk ccall(($(QuoteNode(Symbol(:MLGet, f))), mlib), Cint, (CLink, Ptr{$T}), link, r)
            r[]
        end
    end
end

# Get fns
GetType(link::Link) =
  ccall((:MLGetType, mlib), Cint, (CLink,), link) |> Char

GetRawType(link::Link) =
  ccall((:MLGetRawType, mlib), Cint, (CLink,), link) |> Char

PutType(link::Link, c::Char) =
    ccall((:MLPutType, mlib), Cint, (CLink,Cint), link, c) != 0 ||
        throw(MathLinkError(link))
