module ML

include("consts.jl")

typealias Env Ptr{Void}
typealias Link Ptr{Void}


"""
    lib,ker = find_lib_ker()

Finds the MathLink library (`lib`) and kernel executable (`ker`).
"""
function find_lib_ker()
    @static if is_apple()
        # TODO: query OS X metadata for non-default installations
        # https://github.com/JuliaLang/julia/issues/8733#issuecomment-167981954
        mpath = "/Applications/Mathematica.app"
        if isdir(mpath)
            lib = joinpath(mpath,"Contents/Frameworks/mathlink.framework/mathlink")
            ker = joinpath(mpath,"Contents/MacOS/MathKernel")
            return lib, ker
        end
    end

    @static if is_linux()
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

    @static if is_windows()
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

"""
    link = Open([path])

Opens the connection to the library, using kernel at `path`.

See [`MLOpenString`](https://reference.wolfram.com/language/ref/c/MLOpenString.html).
"""
function Open(path = mker)
  # MLInitialize
  mlenv = ccall((:MLInitialize, mlib), Env, (Cstr,), C_NULL)
  mlenv == C_NULL && error("Could not MLInitialize")

  # MLOpenString
  # local link
  err = Ref{Cint}()
  args = "-linkname '\"$path\" -mathlink' -linkmode launch"
  link = ccall((:MLOpenString, mlib), Link,
                (Env, Cstr, Ref{Cint}),
                mlenv, args, err)
  err[]==0 || mlerror(link, "MLOpenString")

  # Ignore first input packet
  @assert NextPacket(link) == Pkt.INPUTNAME
  NewPacket(link)

  return link
end

"""
    Close(link)

Closes a MathLink connection.

See [`MLClose`](https://reference.wolfram.com/language/ref/c/MLClose.html)
"""
Close(link::Link) = ccall((:MLClose, mlib), Void, (Link,), link)

ErrorMessage(link::Link) =
    ccall((:MLErrorMessage, mlib), Cstr, (Link,), link) |> unsafe_string

for f in [:Error :ClearError :EndPacket :NextPacket :NewPacket]
    fstr = string("ML", f)
    @eval $f(link::Link) = ccall(($fstr, mlib), Cint, (Link,), link)
end

mlerror(link, name) = error("MathLink Error $(Error(link)) in $name: $(ErrorMessage(link))")

# Put fns
for (f, T) in [(:PutInteger64, Int64)
               (:PutInteger32, Int32)
               (:PutReal32, Float32)
               (:PutReal64, Float64)]
    fstr = string("ML", f)
    @eval $f(link::Link, x::$Tj) =
        ccall(($fstr, mlib), Cint, (Link, $Tc), link, x) != 0 ||
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

Gets the type of the current object on `link`.

See [MLGetType](http://reference.wolfram.com/language/ref/c/MLGetType.html)
"""
GetType(link::Link) =
    ccall((:MLGetType, mlib), Cint, (Link,), link) |> Char

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
    ccall((:MLGetUTF8Function, mlib), Cint, Cint, (Link, Ref{Ptr{Cuchar}}, Ref{Cint}, Ref{Cint}), link, s, b, c) != 0 ||
        mlerror(link, "MLGetUTF8Function")
    r = unsafe_string(s[], b[]) |> unescape_string |> Symbol, n[]
    ccall((:MLReleaseUTF8Symbol, mlib), Void, (Link, Ptr{Cuchar}, Cint), link, s[], b[])
    return r
end

end
