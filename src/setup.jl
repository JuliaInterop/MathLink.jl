using Libdl

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
    elseif Sys.isunix()
        archdir = Sys.ARCH == :arm ?    "Linux-ARM" :
                  Sys.ARCH == :x86_64 ? "Linux-x86-64" :
                                        "Linux"

        # alternatively, "math" or "wolfram" is often in PATH, so could use
        # echo \$InstallationDirectory | math | sed -n -e 's/Out\[1\]= //p'
        
        for mpath in ["/usr/local/Wolfram/Mathematica","/opt/Wolfram/WolframEngine"]
            if isdir(mpath)
                vers = readdir(mpath)
                ver = vers[argmax(map(VersionNumber,vers))]

                lib = Libdl.find_library(
                          ["libML$(Sys.WORD_SIZE)i4","libML$(Sys.WORD_SIZE)i3"],
                          [joinpath(mpath,ver,"SystemFiles/Links/MathLink/DeveloperKit",archdir,"CompilerAdditions")])
                ker = joinpath(mpath,ver,"Executables/MathKernel")
                return lib, ker
            end
        end
    elseif Sys.is_windows()
        archdir = Sys.ARCH == :x86_64 ? "Windows-x86-64" :
                                        "Windows"

        #TODO: query Windows Registry, see RCall.jl
        mpath = "C:\\Program Files\\Wolfram Research\\Mathematica"
        if isdir(mpath)
            vers = readdir(mpath)
            ver = vers[argmax(map(VersionNumber,vers))]
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
