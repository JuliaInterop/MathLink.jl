module MathLink

# TODO:
#   Read and store native arrays / matrices
#   MRefs (https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)

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
