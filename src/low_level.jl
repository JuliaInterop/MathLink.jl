module ML

include("consts.jl")

typealias Env Ptr{Void}
typealias Link Ptr{Void}



"""
    link = Open([path])

Initializes and Opens the connection to the library, using kernel at `path`.

See [`MLInitialize`](https://reference.wolfram.com/language/ref/c/MLInitialize.html) and [`MLOpenString`](https://reference.wolfram.com/language/ref/c/MLOpenString.html).
"""
function Open(path = mker)
    # MLInitialize
    mlenv = ccall((:MLInitialize, mlib), Env, (Cstring,), C_NULL)
    mlenv == C_NULL && error("Could not MLInitialize")

    # MLOpenString
    # local link
    err = Ref{Cint}()
    args = "-linkname '\"$path\" -mathlink' -linkmode launch"
    link = ccall((:MLOpenString, mlib), Link,
                 (Env, Cstring, Ref{Cint}),
                 mlenv, args, err)
    err[]==0 || mlerror(link, "MLOpenString")

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
    p = ccall((:MLUTF8ErrorMessage, mlib), Cstring, (Link,Ref{Cint}), link, b)
    if p != C_NULL
        r = unsafe_string(p, b[])
        ccall((:MLReleaseUTF8ErrorMessage, mlib), Void, (CString, Cint), p, b[])
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
    ccall((:MLClearError, mlib), Cint, (Link,), link)
end

"""
    EndPacket(link)

Inserts an indicator in the expression stream that says the current expression is complete and is ready to be sent. Returns nonzero value if successful.

See [`MLEndPacket`](https://reference.wolfram.com/language/ref/c/MLEndPacket.html)
"""
function EndPacket(link::Link)
    ccall((:MLEndPacket, mlib), Cint, (Link,), link)
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

Skips to the end of the current packet on `link`. Returns a nonzero value if successful.

Does nothing if you are already at the end of a packet.

See [`MLNewPacket`](https://reference.wolfram.com/language/ref/c/MLNewPacket.html)
"""
function NewPacket(link::Link)
    ccall((:MLNewPacket, mlib), Cint, (Link,), link)
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
    Flush(link)

Flushes out any buffers containing data waiting to be sent on `link`.

See [`MLFlush`](https://reference.wolfram.com/language/ref/c/MLFlush.html)
"""
function Flush(link::Link)
    ccall((:MLFlush, mlib), Cint, (Link,), link) != 0 ||
        mlerror(link, "MLFlush")
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






mlerror(link, name) = error("MathLink Error $(Error(link)) in $name: $(ErrorMessage(link))")

# Put fns
for (f, T) in [(:PutInteger64, Int64)
               (:PutInteger32, Int32)
               (:PutReal32, Float32)
               (:PutReal64, Float64)]
    fstr = string("ML", f)
    @eval $f(link::Link, x::$T) =
        ccall(($fstr, mlib), Cint, (Link, $T), link, x) != 0 ||
            mlerror(link, $fstr)
end

function PutString(link::Link, x::AbstractString)
    s = String(x)
    ccall((:MLPutUTF8String, mlib), Cint, (Link, Ptr{Cuchar}, Cint), link, s, length(s.data)) != 0 ||
        mlerror(link, "MLPutUTF8String")
end
function PutSymbol(link::Link, x::Symbol)
    s = string(x)
    ccall((:MLPutUTF8Symbol, mlib), Cint, (Link, Ptr{Cuchar}, Cint), link, s, length(s.data)) != 0 ||
        mlerror(link, "MLPutUTF8Symbol")
end

function PutFunction(link::Link, name::AbstractString, nargs)
    s = String(name)
    ccall((:MLPutUTF8Function, mlib), Cint, (Link, Ptr{Cuchar}, Cint, Cint), link, s, length(s.data), nargs) != 0 ||
        mlerror(link, "MLPutUTF8Function")
end

# Get fns

"""
    GetType(link)

Gets the type of the current object on `link` as a `Tkn` value.

See [MLGetType](http://reference.wolfram.com/language/ref/c/MLGetType.html)
"""
GetType(link::Link) =
    ccall((:MLGetType, mlib), Tkn, (Link,), link)

for (f, T) in [(:GetInteger64, Int64)
               (:GetInteger32, Int32)
               (:GetReal32, Float32)
               (:GetReal64, Float64)]
    fstr = string("ML", f)
    @eval function $f(link::Link)
        i = Ref{$T}()
        ccall(($fstr, mlib), Cint, (Link, Ref{$T}), link, i) != 0 ||
        mlerror(link, $fstr)
        i[]
    end
end

# http://reference.wolfram.com/language/ref/c/MLGetUTF8String.html
# http://reference.wolfram.com/language/ref/c/MLReleaseUTF8String.html
function GetString(link::Link)
    s = Ref{Ptr{Cuchar}}()
    b = Ref{Cint}()
    c = Ref{Cint}()
    ccall((:MLGetUTF8String, mlib), Cint, (Link, Ref{Ptr{Cuchar}}, Ref{Cint}, Ref{Cint}), link, s, b, c) != 0 ||
        mlerror(link, "MLGetUTF8String")
    r = unsafe_string(s[], b[]) |> unescape_string
    ccall((:MLReleaseUTF8String, mlib), Void, (Link, Ptr{Cuchar}, Cint), link, s[], b[])
    return r
end

function GetSymbol(link::Link)
    s = Ref{Ptr{Cuchar}}()
    b = Ref{Cint}()
    c = Ref{Cint}()
    ccall((:MLGetUTF8Symbol, mlib), Cint, (Link, Ref{Ptr{Cuchar}}, Ref{Cint}, Ref{Cint}), link, s, b, c) != 0 ||
        mlerror(link, "MLGetUTF8Symbol")
    r = unsafe_string(s[], b[]) |> unescape_string |> Symbol
    ccall((:MLReleaseUTF8Symbol, mlib), Void, (Link, Ptr{Cuchar}, Cint), link, s[], b[])
    return r
end

function GetFunction(link::Link)
    s = Ref{Ptr{Cuchar}}()
    b = Ref{Cint}()
    n = Ref{Cint}()
    ccall((:MLGetUTF8Function, mlib), Cint,
          (Link, Ref{Ptr{Cuchar}}, Ref{Cint}, Ref{Cint}),
          link, s, b, n) != 0 ||
        mlerror(link, "MLGetUTF8Function")
    r = unsafe_string(s[], b[]) |> unescape_string |> Symbol, n[]
    ccall((:MLReleaseUTF8Symbol, mlib), Void, (Link, Ptr{Cuchar}, Cint), link, s[], b[])
    return r
end

end
