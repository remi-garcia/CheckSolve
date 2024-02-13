function check_constraint(con::ConstraintRef, set::MOI.LessThan; kwargs...)
    return max(0.0, value_int(con) - set.upper)
end
function check_constraint(con::ConstraintRef, set::MOI.GreaterThan; kwargs...)
    return max(0.0, set.lower - value_int(con))
end
function check_constraint(con::ConstraintRef, set::MOI.EqualTo; kwargs...)
    return abs(value_int(con) - set.value)
end
function check_constraint(con::ConstraintRef, set::MOI.Interval; kwargs...)
    return max(max(0.0, value_int(con) - set.upper), max(0.0, set.lower - value_int(con)))
end

function check_constraint(con::ConstraintRef)
    set = reshape_set(moi_set(constraint_object(con)), shape(constraint_object(con)))
    return check_constraint(con, set)
end


function check_result(model::Model)::Float64
    all_cons = all_constraints_affexpr(model)
    return maximum(check_constraint.(all_cons))
end

function is_exact(model::Model)
    return check_result(model) == 0.0 
end
