module CheckSolve

using JuMP

include("utils.jl")
include("checkresult.jl")

export check_result
export is_exact
export count_constraint_errors

end # module
