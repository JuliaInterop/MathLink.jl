function warray(x::AbstractArray{T,N}) where {T,N}
    if N == 1
        WExpr(W"List", x)
    else
        s = size(x)
        x = reshape(x, s[1], :)
        WExpr(W"List", warray.(reshape(x[i,:], s[2:N]) for i in 1:s[1]))
    end
end
