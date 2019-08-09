const REFCOUNT = Threads.Atomic{Int}(1)
const globalenv = Env(C_NULL)
const defaultlink = Link(C_NULL)

function refcount_inc()
    Threads.atomic_add!(REFCOUNT, 1)
end
function refcount_dec()
    # refcount zero, all objects finalized, now finalize MathLink
    if Threads.atomic_sub!(REFCOUNT, 1) == 1
        deinitialize!(globalenv)
    end
end

function __init__()
    initialize!(globalenv)
    atexit(refcount_dec)
end

function _defaultlink()
    if defaultlink.ptr == C_NULL
        args = "-linkname '\"$mker\" -mathlink' -linkmode launch"
        open!(defaultlink, globalenv, args)
        
        # Ignore first input packet
        @assert nextpacket(defaultlink) == PKT_INPUTNAME
        NewPacket(defaultlink)
    end
    return defaultlink
end
