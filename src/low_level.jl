module ML

function ptr(T)
  @assert isbits(T)
  Array(T, 1)
end

typealias Cstr Ptr{Cchar}

include("consts.jl")

typealias Env Ptr{Void}
typealias Link Ptr{Void}

verout = open("/tmp/checkversion.m","w")
write(verout,"Print[\$VersionNumber]")
close(verout)
version=float(chomp(readall((`math -script /tmp/checkversion.m`)))

mlib = "ml64i3"
mlib = @osx ? "/Applications/Mathematica.app/Contents/Frameworks/mathlink.framework/mathlink" : mlib
mlib = @unix ? (version>10 ? string("/usr/local/Wolfram/Mathematica/",version,"/SystemFiles/Links/MathLink/DeveloperKit/Linux-x86-64/CompilerAdditions/libML64i4") : mlib) : mlib 
macro mlib(); mlib; end

function Open(path = "math")
  # MLInitialize
  mlenv = ccall((:MLInitialize, @mlib), Env, (Cstr,), C_NULL)
  mlenv == C_NULL && error("Could not MLInitialize")

  # MLOpenString
  # local link
  err = ptr(Cint)
  args = "-linkname '\"$path\" -mathlink' -linkmode launch"
  link = ccall((:MLOpenString, @mlib), Link,
                (Env, Cstr, Ptr{Cint}),
                mlenv, args, err)
  err[1]==0 || mlerror(link, "MLOpenString")

  # Ignore first input packet
  @assert NextPacket(link) == Pkt.INPUTNAME
  NewPacket(link)

  return link
end

Close(link::Link) = ccall((:MLClose, @mlib), Void, (Link,), link)

ErrorMessage(link::Link) =
  ccall((:MLErrorMessage, @mlib), Cstr, (Link,), link) |> bytestring

for f in [:Error :ClearError :EndPacket :NextPacket :NewPacket]
  fstr = string("ML", f)
  @eval $f(link::Link) = ccall(($fstr, @mlib), Cint, (Link,), link)
end

mlerror(link, name) = error("MathLink Error $(Error(link)) in $name: " * ErrorMessage(link))

# Put fns

PutFunction(link::Link, name::AbstractString, nargs::Int) =
  ccall((:MLPutFunction, @mlib), Cint, (Link, Cstr, Cint),
    link, name, nargs) != 0 || mlerror(link, "MLPutFunction")

for (f, Tj, Tc) in [(:PutInteger64, Int64, Int64)
                    (:PutInteger32, Int32, Int32)
                    (:PutString, AbstractString, Cstr)
                    (:PutSymbol, Symbol, Cstr)
                    (:PutReal32, Float32, Float32)
                    (:PutReal64, Float64, Float64)]
  fstr = string("ML", f)
  @eval $f(link::Link, x::$Tj) =
          ccall(($fstr, @mlib), Cint, (Link, $Tc), link, x) != 0 ||
            mlerror(link, $fstr)
end

# Get fns

GetType(link::Link) =
  ccall((:MLGetType, @mlib), Cint, (Link,), link) |> Char

for (f, T) in [(:GetInteger64, Int64)
               (:GetInteger32, Int32)
               (:GetReal32, Float32)
               (:GetReal64, Float64)]
  fstr = string("ML", f)
  @eval function $f(link::Link)
    i = ptr($T)
    ccall(($fstr, @mlib), Cint, (Link, Ptr{$T}), link, i) != 0 ||
      mlerror(link, $fstr)
    i[1]
  end
end

function GetString(link::Link)
  s = ptr(Cstr)
  ccall((:MLGetString, @mlib), Cint, (Link, Ptr{Cstr}), link, s) != 0 ||
    mlerror(link, "GetString")
  r = s[1] |> bytestring |> unescape_string
  ReleaseString(link, s)
  return r
end

function GetSymbol(link::Link)
  s = ptr(Cstr)
  ccall((:MLGetSymbol, @mlib), Cint, (Link, Ptr{Cstr}), link, s) != 0 ||
    mlerror(link, "GetSymbol")
  r = s[1] |> bytestring |> unescape_string |> symbol
  ReleaseSymbol(link, s)
  return r
end

function GetFunction(link::Link)
  name = ptr(Cstr)
  nargs = ptr(Cint)
  ccall((:MLGetFunction, @mlib), Cint, (Link, Ptr{Cstr}, Ptr{Cint}),
    link, name, nargs) != 0 || mlerror(link, "MLGetFunction")
  r = name[1] |> bytestring |> symbol, nargs[1]
  ReleaseString(link, name)
  return r
end

ReleaseString(link::Link, s) = ccall((:MLReleaseString, @mlib), Void, (Link, Cstr), link, s[1])
ReleaseSymbol(link::Link, s) = ccall((:MLReleaseSymbol, @mlib), Void, (Link, Cstr), link, s[1])

end
