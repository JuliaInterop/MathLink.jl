module ML

import MathLink: mlib, mker

include("ml_enums.jl")

typealias Env Ptr{Void}
typealias Link Ptr{Void}


immutable MathLinkError <: Exception
    err::Err
    msg::String
end

function MathLinkError(link::Link)
    e = MathLinkError(Error(link),ErrorMessage(link))
    ClearError(link)
    e
end

macro chkerr(excall)
    quote
        if $excall == 0
            throw(MathLinkError(link))
        end
    end
end


function Initialize()
    mlenv = ccall((:MLInitialize, mlib), Env, (Cstring,), C_NULL)
    mlenv == C_NULL && error("Could not Initialize MathLink connection.")
    mlenv
end

"""
    link = Open([path])

Initializes and Opens the connection to the library, using kernel at `path`.

See [`MLInitialize`](https://reference.wolfram.com/language/ref/c/MLInitialize.html) and [`MLOpenString`](https://reference.wolfram.com/language/ref/c/MLOpenString.html).
"""
function Open(env::Env, path = mker)
    # MLOpenString
    # local link
    err = Ref{Cint}()
    args = "-linkname '\"$path\" -mathlink' -linkmode launch"
    link = ccall((:MLOpenString, mlib), Link,
                 (Env, Cstring, Ref{Cint}),
                 mlenv, args, err)
    err[]==0 || error("Could not open MathLink link")

    # Ignore first input packet
    p = NextPacket(link)
    @assert p == PKT_INPUTNAME
    NewPacket(link)
    
    return link
end

"""
    Close(link)

Closes a MathLink connection.

See [`MLClose`](https://reference.wolfram.com/language/ref/c/MLClose.html)
"""
Close(link::Link) = ccall((:MLClose, mlib), Void, (Link,), link)

"""
    ErrorMessage(link)

Returns a string describing the last error to occur on `link`.

See [`MLUTF8ErrorMessage`](https://reference.wolfram.com/language/ref/c/MLUTF8ErrorMessage.html)
"""
function ErrorMessage(link::Link)
    b = Ref{Cint}()
    p = ccall((:MLUTF8ErrorMessage, mlib), Ptr{Cuchar}, (Link, Ref{Cint}), link, b)
    if p != C_NULL
        r = unsafe_string(p, b[])
        ccall((:MLReleaseUTF8ErrorMessage, mlib), Void, (Ptr{Cuchar}, Cint), p, b[])
        return r
    else
        return nothing
    end
end
    
"""
    Error(link)

Returns an `Err` value indicating the last error to occur on `link` since `ClearError` was last called.

See [`MLError`](https://reference.wolfram.com/language/ref/c/MLError.html)
"""
Error(link::Link) =
    ccall((:MLError, mlib), Err, (Link,), link)

"""
    ClearError(link)

Attempts to clear the error off `link`. Returns nonzero value if successful.

See [`MLClearError`](https://reference.wolfram.com/language/ref/c/MLClearError.html)
"""
function ClearError(link::Link)
    if ccall((:MLClearError, mlib), Cint, (Link,), link) == 0
        error("Critical MathLink error: could not clear link")
    end
end

"""
    EndPacket(link)

Inserts an indicator in the expression stream that says the current expression is complete and is ready to be sent.

See [`MLEndPacket`](https://reference.wolfram.com/language/ref/c/MLEndPacket.html)
"""
function EndPacket(link::Link)
    @chkerr ccall((:MLEndPacket, mlib), Cint, (Link,), link)
    nothing
end

"""
    NextPacket(link)

Goes to the next packet on link. Returns a `Pkt` value to indicate its head.

See [`MLNextPacket`](https://reference.wolfram.com/language/ref/c/MLNextPacket.html)
"""
function NextPacket(link::Link)
    ccall((:MLNextPacket, mlib), Pkt, (Link,), link)
end


"""
    NewPacket(link)

Skips to the end of the current packet on `link`. Does nothing if you are already at the end of a packet.

See [`MLNewPacket`](https://reference.wolfram.com/language/ref/c/MLNewPacket.html)
"""
function NewPacket(link::Link)
    @chkerr ccall((:MLNewPacket, mlib), Cint, (Link,), link)
    nothing
end



"""
    GetNext(link)

Goes to the next object on `link`. Returns a `Tkn` value indicating the objects type.

See [`MLGetNext`](https://reference.wolfram.com/language/ref/c/MLGetNext.html)
"""
function GetNext(link::Link)
    ccall((:MLGetNext, mlib), Tkn, (Link,), link)
end


"""
    GetType(link)

Gets the type of the current object on `link` as a `Tkn` value.

See [MLGetType](http://reference.wolfram.com/language/ref/c/MLGetType.html)
"""
GetType(link::Link) =
    ccall((:MLGetType, mlib), Tkn, (Link,), link)


"""
    PutNext(link, tkn)

Prepares to put an object of type `tkn` on `link`.

See [`MLPutNext`](https://reference.wolfram.com/language/ref/c/MLPutNext.html)
"""
function PutNext(link::Link, tkn::Tkn)
    @chkerr ccall((:MLPutNext, mlib), Cint, (Link,Tkn), link, tkn)
    nothing
end


"""
    GetArgCount(link)

Finds the number of arguments to a function on `link`.

See [MLGetArgCount](http://reference.wolfram.com/language/ref/c/MLGetArgCount.html).
"""
function GetArgCount(link::Link)
    n = Ref{Cint}()
    @chkerr ccall((:MLGetArgCount, mlib), Cint,
          (Link, Ref{Cint}), link, n)
    return n[]
end
    
    
"""
    PutArgCount(link, n)

Specifies the number of arguments `n` to be put on `link`

See [MLPutArgCount](http://reference.wolfram.com/language/ref/c/MLPutArgCount.html).
"""
function PutArgCount(link::Link, n::Integer)
    @chkerr ccall((:MLPutArgCount, mlib), Cint,
          (Link, Cint), link, n)
    nothing
end


"""
    Flush(link)

Flushes out any buffers containing data waiting to be sent on `link`.

See [`MLFlush`](https://reference.wolfram.com/language/ref/c/MLFlush.html)
"""
function Flush(link::Link)
    @chkerr ccall((:MLFlush, mlib), Cint, (Link,), link)
    nothing
end


"""
    Ready(link)

Tests whether there is data ready to be read from `link`.

* Will always return immediately, and will not block.
* You must call `Flush` before calling `Ready`.

See [`MLReady`](https://reference.wolfram.com/language/ref/c/MLReady.html)
"""
function Ready(link::Link)
    ccall((:MLReady, mlib), Cint, (Link,), link) != 0
end


function SetYieldFunction(link::Link, fptr::Ptr{Void})
    @chkerr ccall((:MLSetYieldFunction, mlib), Cint, (Link, Ptr{Void}), link, fptr)
    nothing
end

# Put fns
for (M, T) in [(:Integer64, Int64)
               (:Integer32, Int32)
               (:Real32, Float32)
               (:Real64, Float64)]
    @eval begin
        function Put(link::Link, x::$T)
            @chkerr ccall(($(string("MLPut",$M)), mlib), Cint, (Link, $T), link, x)
            nothing
        end
        function Put{N}(link::Link, X::Array{$T,N})
            s = Cint[i for i in size(X)]
            @chkerr ccall(($(string("MLPut",$M,"Array")), mlib), Cint,
                          (Link, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Cuchar}}, Cint),
                          link, X, s, C_NULL, N)
            nothing
        end            
        function Get(link::Link, ::Type{$T})
            i = Ref{$T}()
            @chkerr ccall(($(string("MLGet",$M)), mlib), Cint, (Link, Ref{$T}), link, i)
            i[]
        end
        function Get(link::Link, ::Type{Array{$T}})
            rX = Ref{Ptr{$T}}()
            rd = Ref{Ptr{Cint}}()
            rh = Ref{Ptr{Ptr{Cchar}}()
            rn = Ref{Cint}()
            @chkerr ccall(($(string("MLGet",$M,"Array")), mlib), Cint,
                          (Link, Ref{Ptr{$T}}, Ref{Ptr{Cint}}, Ref{Ptr{Ptr{Cchar}}}, Ref{Cint}),
                          link, rX, rd, rh, rn)
            dims = ((Int(unsafe_load(rd[],i)) for i = 1:rn[])...)
            Xw = unsafe_wrap(Array, rX[], dims)
            X = copy(Xw)
            ccall(($(string("MLRelease",$M,"Array")), mlib), Void,
                  (Link, Ptr{$T}, Ptr{Cint}, Ptr{Ptr{Cchar}}, Cint),
                  link, rX[], rd[], rh[], rn[])
            X
        end
    end
end

function Put(link::Link, x::AbstractString)
    s = String(x)
    @chkerr ccall((:MLPutUTF8String, mlib), Cint, (Link, Ptr{Cuchar}, Cint), link, s, length(s.data))
end
function Put(link::Link, x::Symbol)
    s = string(x)
    @chkerr ccall((:MLPutUTF8Symbol, mlib), Cint, (Link, Ptr{Cuchar}, Cint), link, s, length(s.data))
end

# Get fns
function Get(link::Link, ::Type{String})
    s = Ref{Ptr{Cuchar}}()
    b = Ref{Cint}()
    c = Ref{Cint}()
    @chkerr ccall((:MLGetUTF8String, mlib), Cint, (Link, Ref{Ptr{Cuchar}}, Ref{Cint}, Ref{Cint}), link, s, b, c)
    r = unsafe_string(s[], b[])
    ccall((:MLReleaseUTF8String, mlib), Void, (Link, Ptr{Cuchar}, Cint), link, s[], b[])
    return r
end

function Get(link::Link, ::Type{Symbol})
    s = Ref{Ptr{Cuchar}}()
    b = Ref{Cint}()
    c = Ref{Cint}()
    @chkerr ccall((:MLGetUTF8Symbol, mlib), Cint, (Link, Ref{Ptr{Cuchar}}, Ref{Cint}, Ref{Cint}), link, s, b, c)
    r = unsafe_string(s[], b[]) |> Symbol
    ccall((:MLReleaseUTF8Symbol, mlib), Void, (Link, Ptr{Cuchar}, Cint), link, s[], b[])
    return r
end

function PutFunction(link::Link, name::AbstractString, nargs)
    s = String(name)
    @chkerr ccall((:MLPutUTF8Function, mlib), Cint, (Link, Ptr{Cuchar}, Cint, Cint), link, s, length(s.data), nargs)
end

function GetFunction(link::Link)
    s = Ref{Ptr{Cuchar}}()
    b = Ref{Cint}()
    n = Ref{Cint}()
    @chkerr ccall((:MLGetUTF8Function, mlib), Cint,
          (Link, Ref{Ptr{Cuchar}}, Ref{Cint}, Ref{Cint}),
          link, s, b, n)
    r = unsafe_string(s[], b[]) |> unescape_string |> Symbol, n[]
    ccall((:MLReleaseUTF8Symbol, mlib), Void, (Link, Ptr{Cuchar}, Cint), link, s[], b[])
    return r
end


    

        
        
        
        



end
