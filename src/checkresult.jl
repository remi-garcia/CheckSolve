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

function check_constraint(con::ConstraintRef; kwargs...)
    set = reshape_set(moi_set(constraint_object(con)), shape(constraint_object(con)))
    return check_constraint(con, set; kwargs...)
end

function check_result(model::Model; ignore_floats::Bool=false, kwargs...)::Float64
    all_cons = all_constraints_affexpr(model)
    val_check_results = zeros(length(all_cons))
    for i in 1:length(all_cons)
        curr_constraint = all_cons[i]
        if ignore_floats
            cst_object = constraint_object(curr_constraint)
            cst_variables = [k for k in keys(cst_object.func.terms)]
            has_float_var = true in [is_binary.(cst_variables) || is_integer.(cst_variables)]
            if !has_float_var
                continue
            end
        end
        val_check_results[i] = check_constraint(curr_constraint; kwargs...)
    end

    return maximum(val_check_results)
end

function is_exact(model::Model; kwargs...)
    return check_result(model; kwargs...) == 0.0 
end

function simplify_model!(model::Model; kwargs...)
    fix_int!(model)
    simplify_fix_var!(model)

    return model
end
