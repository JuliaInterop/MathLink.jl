function mma_list2array(list::WExpr)
    n = weval(W"Length"(list))
    [mma_list2array(weval(W"Extract"(list, W"List"(i)))) for i in 1:n]
end

function mma_list2array(num::Number)
    return num
end