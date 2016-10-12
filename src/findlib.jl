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
            info("Using Mathematica installation at $mpath.")
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
                info("Using Mathematica installation at $mpath.")
                vers = readdir(mpath)
                ver = vers[indmax(map(VersionNumber,vers))]

                lib = Libdl.find_library(
                          ["libML$(Sys.WORD_SIZE)i4"],
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
            info("Using Mathematica installation at $mpath.")
            vers = readdir(mpath)
            ver = vers[indmax(map(VersionNumber,vers))]
            lib = Libdl.find_library(
                          ["libML$(Sys.WORD_SIZE)i4"],
                          [joinpath(mpath,ver,"SystemFiles\\Links\\MathLink\\DeveloperKit",archdir,"SystemAdditions")])
            ker = joinpath(mpath,ver,"math.exe")
            return lib, ker
        end
    end

    error("Could not find Mathematica installation")
end

const mlib,mker = find_lib_ker()
