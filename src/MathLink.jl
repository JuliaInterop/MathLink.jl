module MathLink

# TODO:
#   Read and store native arrays / matrices
#   https://groups.google.com/d/msg/comp.soft-sys.math.mathematica/tPim3jnfh9I/14rVRRZjM80J
#   https://mathematica.stackexchange.com/questions/180706/how-to-send-packed-array-from-math-kernel-to-3rd-party-app-via-wstp
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
