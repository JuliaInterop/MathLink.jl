module MathLink

using Printf

export @W_str, @W_cmd, weval


###Checking that the deps.jl file exists. And throwing a readable error if it does not!
if isfile("../deps/deps.jl")
    include("../deps/deps.jl")
else
    FilePath=@__DIR__
    FilePath=FilePath[1:end-4]*"/deps/deps.jl"
    error("The file $FilePath does not exist.\n"
          *"This usually means that the MathLink installation failed.\n"
          *"Have you checked that Mathematica is installed on your system?")
end
include("types.jl")
include("consts.jl")
include("init.jl")
include("link.jl")
include("wstp.jl")
include("extras.jl")
include("eval.jl")
include("display.jl")
include("operators.jl")

end
