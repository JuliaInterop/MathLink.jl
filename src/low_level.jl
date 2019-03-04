module ML

function ptr(T)
  @assert isbitstype(T)
  Vector{T}([1])
end

const Cstr = Ptr{Cchar}

include("consts.jl")

const Env = Ptr{Nothing}
const Link = Ptr{Nothing}


function find_lib_ker()    
    @static if Sys.isapple()
        # TODO: query OS X metadata for non-default installations
        # https://github.com/JuliaLang/julia/issues/8733#issuecomment-167981954
        mpath = "/Applications/Mathematica.app"        
        if isdir(mpath)
            lib = joinpath(mpath,"Contents/Frameworks/mathlink.framework/mathlink")
            ker = joinpath(mpath,"Contents/MacOS/MathKernel")
            return lib, ker
        end        
    end

    @static if Sys.islinux()
        archdir = Sys.ARCH == :arm ?    "Linux-ARM" :
                  Sys.ARCH == :x86_64 ? "Linux-x86-64" :
                                        "Linux"

        # alternatively, "math" or "wolfram" is often in PATH, so could use
        # echo \$InstallationDirectory | math | sed -n -e 's/Out\[1\]= //p'
        
        for mpath in ["/usr/local/Wolfram/Mathematica","/opt/Wolfram/WolframEngine"]
            if isdir(mpath)
                vers = readdir(mpath)
                ver = vers[indmax(map(VersionNumber,vers))]

                lib = Libdl.find_library(
                          ["libML$(Sys.WORD_SIZE)i4","libML$(Sys.WORD_SIZE)i3"],
                          [joinpath(mpath,ver,"SystemFiles/Links/MathLink/DeveloperKit",archdir,"CompilerAdditions")])
                ker = joinpath(mpath,ver,"Executables/MathKernel")
                return lib, ker
            end
        end
    end

    @static if Sys.iswindows()
        archdir = Sys.ARCH == :x86_64 ? "Windows-x86-64" :
                                        "Windows"

        #TODO: query Windows Registry, see RCall.jl
        mpath = "C:\\Program Files\\Wolfram Research\\Mathematica"
        if isdir(mpath)
            vers = readdir(mpath)
            ver = vers[indmax(map(VersionNumber,vers))]
            lib = Libdl.find_library(
                          ["libML$(Sys.WORD_SIZE)i4","libML$(Sys.WORD_SIZE)i3"],
                          [joinpath(mpath,ver,"SystemFiles\\Links\\MathLink\\DeveloperKit",archdir,"SystemAdditions")])
            ker = joinpath(mpath,ver,"math.exe")
            return lib, ker
        end
    end

    error("Could not find Mathematica installation")        
end

const mlib,mker = find_lib_ker()

function Open(path = mker)
  # MLInitialize
  mlenv = ccall((:MLInitialize, mlib), Env, (Cstr,), C_NULL)
  mlenv == C_NULL && error("Could not MLInitialize")

  # MLOpenString
  # local link
  err = ptr(Cint)
  args = "-linkname '\"$path\" -mathlink' -linkmode launch"
  link = ccall((:MLOpenString, mlib), Link,
                (Env, Cstr, Ptr{Cint}),
                mlenv, args, err)
  err[1]==0 || mlerror(link, "MLOpenString")

  # Ignore first input packet
  @assert NextPacket(link) == Pkt.INPUTNAME
  NewPacket(link)

  return link
end

Close(link::Link) = ccall((:MLClose, mlib), Nothing, (Link,), link)

ErrorMessage(link::Link) =
  ccall((:MLErrorMessage, mlib), Cstr, (Link,), link) |> unsafe_string

for f in [:Error :ClearError :EndPacket :NextPacket :NewPacket]
  fstr = string("ML", f)
  @eval $f(link::Link) = ccall(($fstr, mlib), Cint, (Link,), link)
end

mlerror(link, name) = error("MathLink Error $(Error(link)) in $name: " * ErrorMessage(link))

# Put fns

PutFunction(link::Link, name::AbstractString, nargs::Int) =
  ccall((:MLPutFunction, mlib), Cint, (Link, Cstr, Cint),
    link, name, nargs) != 0 || mlerror(link, "MLPutFunction")

for (f, Tj, Tc) in [(:PutInteger64, Int64, Int64)
                    (:PutInteger32, Int32, Int32)
                    (:PutString, AbstractString, Cstr)
                    (:PutSymbol, Symbol, Cstr)
                    (:PutReal32, Float32, Float32)
                    (:PutReal64, Float64, Float64)]
  fstr = string("ML", f)
  @eval $f(link::Link, x::$Tj) =
          ccall(($fstr, mlib), Cint, (Link, $Tc), link, x) != 0 ||
            mlerror(link, $fstr)
end

# Get fns

GetType(link::Link) =
  ccall((:MLGetType, mlib), Cint, (Link,), link) |> Char

for (f, T) in [(:GetInteger64, Int64)
               (:GetInteger32, Int32)
               (:GetReal32, Float32)
               (:GetReal64, Float64)]
  fstr = string("ML", f)
  @eval function $f(link::Link)
    i = ptr($T)
    ccall(($fstr, mlib), Cint, (Link, Ptr{$T}), link, i) != 0 ||
      mlerror(link, $fstr)
    i[1]
  end
end

function GetString(link::Link)
  s = ptr(Cstr)
  ccall((:MLGetString, mlib), Cint, (Link, Ptr{Cstr}), link, s) != 0 ||
    mlerror(link, "GetString")
  r = s[1] |> unsafe_string
  ReleaseString(link, s)
  return r
end

function GetSymbol(link::Link)
  s = ptr(Cstr)
  ccall((:MLGetSymbol, mlib), Cint, (Link, Ptr{Cstr}), link, s) != 0 ||
    mlerror(link, "GetSymbol")
  r = s[1] |> unsafe_string |> unescape_string |> Symbol
  ReleaseSymbol(link, s)
  return r
end

function GetFunction(link::Link)
  name = ptr(Cstr)
  nargs = ptr(Cint)
  ccall((:MLGetFunction, mlib), Cint, (Link, Ptr{Cstr}, Ptr{Cint}),
    link, name, nargs) != 0 || mlerror(link, "MLGetFunction")
  r = name[1] |> unsafe_string |> Symbol, nargs[1]
  ReleaseString(link, name)
  return r
end

ReleaseString(link::Link, s) = ccall((:MLReleaseString, mlib), Nothing, (Link, Cstr), link, s[1])
ReleaseSymbol(link::Link, s) = ccall((:MLReleaseSymbol, mlib), Nothing, (Link, Cstr), link, s[1])

end
