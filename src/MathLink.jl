module MathLink

export @W_str, weval

include("../deps/deps.jl")
include("types.jl")
include("consts.jl")
include("init.jl")
include("link.jl")
include("wstp.jl")
include("extras.jl")
include("eval.jl")

end
