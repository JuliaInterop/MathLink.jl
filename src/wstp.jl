struct MathLinkError <: Exception
    err::Error
    msg::String
end
function MathLinkError(link::Link)
    err = ccall((:WSError, libwstp), Error, (CLink,), link)
    msg = unsafe_string(ccall((:WSErrorMessage, libwstp), Cstring, (CLink,), link))
    clearerror(link)
    newpacket(link)
    MathLinkError(err, msg)
end

clearerror(link::Link) =
    ccall((:WSClearError, libwstp), Cint, (CLink,), link)
endpacket(link::Link) =
    ccall((:WSEndPacket, libwstp), Cint, (CLink,), link)
newpacket(link::Link) =
    ccall((:WSNewPacket, libwstp), Cint, (CLink,), link)

nextpacket(link::Link) =
    ccall((:WSNextPacket, libwstp), Packet, (CLink,), link)

macro wschk(expr)
    link = expr.args[5] # first argument
    quote
        if $(esc(expr)) == 0
            throw(MathLinkError($(esc(link))))
        end
    end
end

function getargcount(link::Link)
    r = Ref{Cint}()
    # int WSGetArgCount(WSLINK link,int *n)
    @wschk ccall((:WSGetArgCount, libwstp), Cint,
                 (CLink, Ptr{Cint}),
                 link, r)
    r[]
end

function putargcount(link::Link, n::Integer)
    # int WSPutArgCount(WSLINK link,int n)
    @wschk ccall((:WSPutArgCount, libwstp), Cint,
                 (CLink, Cint),
                 link, n)
    nothing
end
function putfunction(link::Link, w::WSymbol, nargs::Integer)
    # int MLPutUTF8Function(( MLLINK l , const unsigned char * s , int v , int n ) 
    @wschk ccall((:WSPutUTF8Function, libwstp), Cint,
                 (CLink, Ptr{UInt8}, Cint, Cint),
                 link, w.name, sizeof(w.name), nargs)
    nothing
end
function getfunction(link::Link)
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_nargs = Ref{Cint}()
    # int MLGetUTF8Function( MLLINK l , const unsigned char ** s , int * v , int * n )
    @wschk ccall((:WSGetUTF8Function, libwstp), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_nargs)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8Symbol(MLLINK link,const unsigned char *s,int len)
    ccall((:WSReleaseUTF8Symbol, libwstp), Cvoid,
          (CLink, Ptr{UInt8}, Cint),
          link, r_str[], r_bytes[])
    return WSymbol(str), r_nargs[]
end

# WSymbol
function put(link::Link, w::WSymbol)
    # int MLPutUTF8Symbol(MLLINK link,const unsigned char *s,int len)
    @wschk ccall((:WSPutUTF8Symbol, libwstp), Cint,
                 (CLink, Ptr{UInt8}, Cint),
                 link, w.name, sizeof(w.name))    
    nothing
end
function get(link::Link, ::Type{WSymbol})
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_chars = Ref{Cint}()
    # int MLGetUTF8Symbol(MLLINK link,const unsigned char **s,int *b,int *c)
    @wschk ccall((:WSGetUTF8Symbol, libwstp), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_chars)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8Symbol(MLLINK link,const unsigned char *s,int len)
    ccall((:WSReleaseUTF8Symbol, libwstp), Cvoid,
          (CLink, Ptr{UInt8}, Cint),
          link, r_str[], r_bytes[])
    return WSymbol(str)
end

# WReal/WInteger
function put(link::Link, w::WReal)
    # int MLPutRealNumberAsUTF8String(MLLINK l, const unsigned char *s, int n)
    @wschk ccall((:WSPutRealNumberAsUTF8String, libwstp), Cint,
                 (CLink, Ptr{UInt8}, Cint),
                 link, w.value, sizeof(w.value))    
    nothing
end
function get(link::Link, ::Type{W}) where W <: Union{WReal,WInteger}
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_chars = Ref{Cint}()
    # int MLGetNumberAsUTF8String(MLLINK l, const unsigned char **s, int *v, int *c)
    @wschk ccall((:WSGetNumberAsUTF8String, libwstp), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_chars)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8String(MLLINK link,const unsigned char *s,int len)
    ccall((:WSReleaseUTF8String, libwstp), Cvoid,
          (CLink, Ptr{UInt8}, Cint),
          link, r_str[], r_bytes[])
    return W(str)
end


# String
function put(link::Link, str::Union{String,SubString})
    # int MLPutUTF8String(MLLINK link,const unsigned char *s,int len)
    @wschk ccall((:WSPutUTF8String, libwstp), Cint,
                 (CLink, Ptr{UInt8}, Cint),
                 link, str, sizeof(str))
    nothing
end
function get(link::Link, ::Type{String})
    r_str = Ref{Ptr{UInt8}}()
    r_bytes = Ref{Cint}()
    r_chars = Ref{Cint}()
    # int MLGetUTF8String(MLLINK link,const unsigned char **s,int *b,int *c)
    @wschk ccall((:WSGetUTF8String, libwstp), Cint,
                 (CLink, Ptr{Ptr{UInt8}}, Ptr{Cint}, Ptr{Cint}),
                 link, r_str, r_bytes, r_chars)
    str = unsafe_string(r_str[], r_bytes[])
    # void MLReleaseUTF8String(MLLINK link,const unsigned char *s,int len)
    ccall((:WSReleaseUTF8String, libwstp), Cvoid,
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
            @wschk ccall(($(QuoteNode(Symbol(:WSPut, f))), libwstp), Cint, (CLink, $(f == :Real32 ? Float64 : T)), link, x)
            nothing
        end
        function get(link::Link, ::Type{$T})
            r = Ref{$T}()
            @wschk ccall(($(QuoteNode(Symbol(:WSGet, f))), libwstp), Cint, (CLink, Ptr{$T}), link, r)
            r[]
        end
    end
end



# Get fns
gettype(link::Link) =
    ccall((:WSGetType, libwstp), Token, (CLink,), link)

getrawtype(link::Link) =
    ccall((:WSGetRawType, libwstp), Token, (CLink,), link)

puttype(link::Link, t::Token) =
    @wschk ccall((:WSPutType, libwstp), Cint, (CLink, Token), link, t)

getnext(link::Link) =
    ccall((:WSGetNext, libwstp), Token, (CLink,), link)

getnextraw(link::Link) =
    ccall((:WSGetNextRaw, libwstp), Token, (CLink,), link)

