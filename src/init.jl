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
        ccall((:MLDeinitialize, mlib), Cvoid, (CEnv,), env)
        env.ptr = C_NULL
    end
end

function __init__()
    # WSENV WSInitialize(WSEnvironmentParameter p) 
    env.ptr = ccall((:MLInitialize, mlib), CEnv, (Ptr{Cvoid},), C_NULL)
    if env.ptr == C_NULL
        error("Could not initialize MathLink library")
    end
    atexit(refcount_dec)
end
