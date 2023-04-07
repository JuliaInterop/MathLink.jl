"""
    Env

A WSTP library environment.

# External links
 - [WSENV](https://reference.wolfram.com/language/ref/c/WSENV.html)
"""
mutable struct Env
    ptr::Ptr{Cvoid}
end

const CEnv = Ptr{Cvoid}
Base.cconvert(::Type{CEnv}, env::Env) = env.ptr


# global environment object
const env = Env(C_NULL)
# reference counter to ensure all links are closed before deinitialize
const REFCOUNT = Threads.Atomic{Int}(1)

# this should be called when opening a link
function refcount_inc()
    Threads.atomic_add!(REFCOUNT, 1)
end

# this should be called in the finalizer of a link
function refcount_dec()
    # refcount zero, all objects finalized, now finalize MathLink
    if Threads.atomic_sub!(REFCOUNT, 1) == 1
        # void WSDeinitialize(WSENV env)
        ccall((:WSDeinitialize, libwstp), Cvoid, (CEnv,), env)
        env.ptr = C_NULL
    end
end


function __init__()

    out = IOBuffer()
    if !success(pipeline(`$(wolfram_app_discovery()) default --raw-value wstp-compiler-additions-directory`, out))
        @debug "Could not find WSTP installation"
        return
    end
    wstp_dir = String(take!(out))

    if Sys.iswindows()
        global libwstp = joinpath(wstp_dir, "..", "SystemAdditions", "wstp$(Sys.WORD_SIZE)i4.dll")
    elseif Sys.isapple()
        global libwstp = joinpath(wstp_dir, "wstp.framework", "wstp")
    elseif Sys.isunix()
        global libwstp = joinpath(wstp_dir, "libWSTP$(Sys.WORD_SIZE)i4.so")
    end

    @info "WSTP installation found" wstp_dir libwstp

    if libwstp != ""
        # WSENV WSInitialize(WSEnvironmentParameter p) 
        env.ptr = ccall((:WSInitialize, libwstp), CEnv, (Ptr{Cvoid},), C_NULL)
        if env.ptr == C_NULL
            error("Could not initialize MathLink library")
        end
        atexit(refcount_dec)
    end
end
