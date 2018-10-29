module ML

include("setup.jl")
include("consts.jl")

const Env = Ptr{Cvoid}
const Link = Ptr{Cvoid}

function Open(path = mker)
  # MLInitialize
  mlenv = ccall((:MLInitialize, mlib), Env, (Cstring,), C_NULL)
  mlenv == C_NULL && error("Could not MLInitialize")

  # MLOpenString
  # local link
  err = Ref{Cint}()
  args = "-linkname '\"$path\" -mathlink' -linkmode launch"
  link = ccall((:MLOpenString, mlib), Link,
                (Env, Cstring, Ptr{Cint}),
                mlenv, args, err)
  err[] == 0 || throw(MathLinkError(link))

  # Ignore first input packet
  @assert NextPacket(link) == Pkt.INPUTNAME
  NewPacket(link)

  return link
end

Close(link::Link) = ccall((:MLClose, mlib), Cvoid, (Link,), link)

struct MathLinkError <: Exception
    msg::String
end
function MathLinkError(link::Link)
    MathLinkError(unsafe_string(ccall((:MLErrorMessage, mlib), Cstring, (Link,), link)))
end

for f in [:Error :ClearError :EndPacket :NextPacket :NewPacket]
  fstr = string("ML", f)
  @eval $f(link::Link) = ccall(($fstr, mlib), Cint, (Link,), link)
end

mlerror(link, name) = error("MathLink Error $(Error(link)) in $name: " * ErrorMessage(link))

# Put fns

PutFunction(link::Link, name::AbstractString, nargs::Int) =
    ccall((:MLPutFunction, mlib), Cint,
          (Link, Cstring, Cint),
          link, name, nargs) != 0 || throw(MathLinkError(link))

for (f, Tj, Tc) in [(:PutInteger64, Int64, Int64)
                    (:PutInteger32, Int32, Int32)
                    (:PutString, AbstractString, Cstring)
                    (:PutSymbol, Symbol, Cstring)
                    (:PutReal32, Float32, Float32)
                    (:PutReal64, Float64, Float64)]
  fstr = string("ML", f)
  @eval $f(link::Link, x::$Tj) =
          ccall(($fstr, mlib), Cint, (Link, $Tc), link, x) != 0 ||
              throw(MathLinkError(link))
end

# Get fns

GetType(link::Link) =
  ccall((:MLGetType, mlib), Cint, (Link,), link) |> Char

PutType(link::Link, c::Char) =
    ccall((:MLPutType, mlib), Cint, (Link,Cint), link, c) != 0 ||
        throw(MathLinkError(link))


for (f, T) in [(:GetInteger64, Int64)
               (:GetInteger32, Int32)
               (:GetReal32, Float32)
               (:GetReal64, Float64)]
  fstr = string("ML", f)
  @eval function $f(link::Link)
      ref = Ref{$T}()
      ccall(($fstr, mlib), Cint, (Link, Ptr{$T}), link, ref) != 0 ||
          throw(MathLinkError(link))
      ref[]
  end
end

function GetString(link::Link)
    ref = Ref{Cstring}()
    ccall((:MLGetString, mlib), Cint, (Link, Ptr{Cstring}), link, ref) != 0 ||
        throw(MathLinkError(link))
    str = ref[] |> unsafe_string |> unescape_string
    ReleaseString(link, ref[])
    return str
end

function GetSymbol(link::Link)
    ref = Ref{Cstring}()
    ccall((:MLGetSymbol, mlib), Cint, (Link, Ptr{Cstring}), link, ref) != 0 ||
        throw(MathLinkError(link))
    sym = ref[] |> unsafe_string |> unescape_string |> Symbol
    ReleaseSymbol(link, ref[])
    return sym
end

function GetFunction(link::Link)
    name = Ref{Cstring}()
    nargs = Ref{Cint}()
    ccall((:MLGetFunction, mlib), Cint, (Link, Ptr{Cstring}, Ptr{Cint}),
          link, name, nargs) != 0 || throw(MathLinkError(link))
    r = name[] |> unsafe_string |> Symbol, nargs[]
    ReleaseString(link, name[])
    return r
end

ReleaseString(link::Link, s::Cstring) = ccall((:MLReleaseString, mlib), Cvoid, (Link, Cstring), link, s)
ReleaseSymbol(link::Link, s::Cstring) = ccall((:MLReleaseSymbol, mlib), Cvoid, (Link, Cstring), link, s)

end
