module MathLink

using Printf

export @W_str, @W_cmd, weval

using WolframAppDiscovery_jll

if VERSION >= v"1.8"
    libwstp::String = ""
else
    libwstp = ""
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
