using Libdl

function find_lib_ker()
    if haskey(ENV,"JULIA_MATHLINK") && haskey(ENV,"JULIA_MATHKERNEL")
        return ENV["JULIA_MATHLINK"], ENV["JULIA_MATHKERNEL"]
    elseif Sys.isapple()
        # we query OS X metadata for possible non-default installations
        # TODO: can use `mdls -raw -name kMDItemVersion $path` to get the versio
                
        # Mathematica
        for path in readlines(`mdfind "kMDItemCFBundleIdentifier == 'com.wolfram.Mathematica'"`)
            lib = joinpath(path,"Contents/Frameworks/mathlink.framework/mathlink")
            ker = joinpath(path,"Contents/MacOS/MathKernel")
            if isfile(lib) && isfile(ker)
                return lib, ker
            end
        end

        # Wolfram Engine
        for path in readlines(`mdfind "kMDItemCFBundleIdentifier == 'com.wolfram.*'"`)
            # kernels are located in sub-application
            subpath = joinpath(path, "Contents/Resources/Wolfram Player.app")
            lib = joinpath(subpath,"Contents/Frameworks/mathlink.framework/mathlink")
            ker = joinpath(subpath,"Contents/MacOS/MathKernel")
            if isfile(lib) && isfile(ker)
                return lib, ker
            end
        end

        # Wolfram Mathematica
        for path in readlines(`mdfind "kMDItemCFBundleIdentifier == 'com.wolfram.*'"`)
            lib = joinpath(path,"Contents/Frameworks/mathlink.framework/mathlink")
            ker = joinpath(path,"Contents/MacOS/MathKernel")
            if isfile(lib) && isfile(ker)
                return lib, ker
            end
        end

    elseif Sys.isunix()
        archdir = Sys.ARCH == :arm ?    "Linux-ARM" :
                  Sys.ARCH == :x86_64 ? "Linux-x86-64" :
                                        "Linux"

        ker = get(ENV,"JULIA_MATHKERNEL") do
            for kername in ["WolframKernel", "MathKernel", "wolfram", "math"]
                if Sys.isexecutable(Sys.which(kername))
                    return kername
                end
            end

            for mpath in ["/usr/local/Wolfram/Mathematica","/opt/Wolfram/WolframEngine"]
                if isdir(mpath)
                    vers = readdir(mpath)
                    ver = vers[argmax(map(VersionNumber,vers))]
                    for kername in ["WolframKernel", "MathKernel", "wolfram", "math"]
                        fullkername = joinpath(mpath,ver,"Executables",kername)
                        if Sys.isexecutable(fullkername)
                            return fullkername
                        end
                    end
                end
            end
            error("Could not find Wolfram engine kernel")
        end

        @show basepath = String(read(`$ker -noprompt -run "WriteString[\$Output,\$InstallationDirectory];Exit[]"`))
        
        lib = Libdl.find_library(
            ["libML$(Sys.WORD_SIZE)i4","libML$(Sys.WORD_SIZE)i3"],
            [joinpath(basepath,"SystemFiles/Links/MathLink/DeveloperKit",archdir,"CompilerAdditions")])

        return lib, ker
    elseif Sys.iswindows()
        archdir = Sys.ARCH == :x86_64 ? "Windows-x86-64" :
            "Windows"

        # TODO: query Windows Registry, see RCall.jl
        # it looks like it registers stuff in
        # HKEY_LOCAL_MACHINE\SOFTWARE\Wolfram Research\Installations\
        # but not clear how it is organized
        if haskey(ENV, "JULIA_WOLFRAM_DIR")
            wpaths = [ENV["JULIA_WOLFRAM_DIR"]]
        else
            wpaths = String[]
            for dir in ["C:\\Program Files\\Wolfram Research\\Mathematica", "C:\\Program Files\\Wolfram Research\\Wolfram Engine"]
                if isdir(mpath)
                    for ver in readdir(mpath)
                        push!(wpaths, joinpath(dir, ver))
                    end
                end
            end
        end
        for wpath in wpaths
            lib = Libdl.find_library(
                ["ml$(Sys.WORD_SIZE)i4.dll", "libML$(Sys.WORD_SIZE)i4", "ml$(Sys.WORD_SIZE)i3.dll", "libML$(Sys.WORD_SIZE)i3"],
                [joinpath(wpath,"SystemFiles\\Links\\MathLink\\DeveloperKit",archdir,"SystemAdditions")])
            ker = joinpath(wpath,"math.exe")
            return lib, ker
        end
    end

    error("Could not find Mathematica or Wolfram Engine installation.\nPlease set the `JULIA_MATHLINK` and `JULIA_MATHKERNEL` variables.")
end

@info "The JULIA_PKG_SERVER_REGISTRY_PREFERENCE variable" 
@info get(ENV, "JULIA_PKG_SERVER_REGISTRY_PREFERENCE", "false")

if get(ENV, "JULIA_REGISTRYCI_AUTOMERGE", "false") == "true"
    # We need to be able to install and load this package without error for
    # Julia's registry AutoMerge to work. Just write a fake Mathematica path.
    mlib = ""
    mker = "WolframKernel"
    @info "Pretending fake installation exists" mlib mker
elseif get(ENV, "JULIA_PKG_SERVER_REGISTRY_PREFERENCE", "false") != "false"
    # We need to be able to install and load this package without error for
    # Githubs CI checker to work. Just write a fake Mathematica path.
    mlib = ""
    mker = "WolframKernel"
    @info "Pretending fake Github CI installation exists" mlib mker
else
    mlib,mker = find_lib_ker()
    @info "Installation found" mlib mker
end    



open("deps.jl","w") do f
    println(f, "# this file is automatically generated")
    println(f, :(const mlib = $mlib))
    println(f, :(const mker = $mker))
end
