function check_constraint(val::Float64, set::MOI.LessThan; kwargs...)::Float64
    return max(0.0, val - set.upper)
end
function check_constraint(val::Float64, set::MOI.GreaterThan; kwargs...)::Float64
    return max(0.0, set.lower - val)
end
function check_constraint(val::Float64, set::MOI.EqualTo; kwargs...)::Float64
    return abs(val - set.value)
end
function check_constraint(val::Float64, set::MOI.Interval; kwargs...)::Float64
    return max(max(0.0, val - set.upper), max(0.0, set.lower - val))
end

function check_constraint(con::ConstraintRef, set::Union{MOI.LessThan, MOI.GreaterThan, MOI.EqualTo, MOI.Interval}; round_int::Bool=true, kwargs...)::Float64
    if round_int
        return check_constraint(value_int(con), set)
    end
    return check_constraint(value(con), set)
end

function _check_constraint(con::ConstraintRef, set::MOI.Indicator; round_int::Bool=true, kwargs...)::Float64
    if round_int
        return check_constraint(value_int(con)[2], set.set; kwargs...)
    end
    return check_constraint(value(con)[2], set.set; kwargs...)
end

function check_constraint(con::ConstraintRef, set::MOI.Indicator{MOI.ACTIVATE_ON_ONE}; kwargs...)::Float64
    if iszero(value_int(con)[1])
        return 0.0
    end
    return _check_constraint(con, set; kwargs...)
end

function check_constraint(con::ConstraintRef, set::MOI.Indicator{MOI.ACTIVATE_ON_ZERO}; kwargs...)::Float64
    if isone(value_int(con)[1])
        return 0.0
    end
    return _check_constraint(con, set; kwargs...)
end

function check_constraint(con::ConstraintRef; kwargs...)::Float64
    set = reshape_set(moi_set(constraint_object(con)), shape(constraint_object(con)))
    return check_constraint(con, set; kwargs...)
end

function check_result(
        model::Model;
        ignore_floats::Bool=false,
        print_cst_check::Bool=false,
        print_all_cst_check::Bool=false,
        print_var_values::Bool=false,
        kwargs...
    )::Float64
    all_cons_affexpr = all_constraints_affexpr(model)
    all_cons_ind_affexpr = all_constraints_ind_affexpr(model)
    val_check_results = zeros(length(all_cons_affexpr)+length(all_cons_ind_affexpr))
    for i in 1:length(all_cons_affexpr)
        curr_constraint = all_cons_affexpr[i]
        if ignore_floats
            cst_object = constraint_object(curr_constraint)
            cst_variables = [k for k in keys(cst_object.func.terms)]
            has_float_var = true in [is_binary.(cst_variables) .|| is_integer.(cst_variables)]
            if !has_float_var
                continue
            end
        end
        val_check_results[i] = check_constraint(curr_constraint; kwargs...)
        if print_all_cst_check && !iszero(val_check_results[i])
            println("Constraint: $(curr_constraint)")
            println("\tError: $(val_check_results[i])")
        end
    end
    for i in 1:length(all_cons_ind_affexpr)
        curr_constraint = all_cons_ind_affexpr[i]
        if ignore_floats
            cst_object = constraint_object(curr_constraint)
            cst_variables = [k for k in keys(cst_object.func[2].terms)]
            has_float_var = true in [is_binary.(cst_variables) .|| is_integer.(cst_variables)]
            if !has_float_var
                continue
            end
        end
        val_check_results[length(all_cons_affexpr)+i] = check_constraint(curr_constraint; kwargs...)
        if print_all_cst_check && !iszero(val_check_results[length(all_cons_affexpr)+i])
            println("Constraint: $(curr_constraint)")
            println("\tError: $(val_check_results[i])")
            if print_var_values
                print_values_in_cst(model, curr_constraint)
            end
        end
    end

    if print_cst_check
        i = argmax(val_check_results)
        curr_constraint = all_cons_affexpr[i]
        if i > length(all_cons_affexpr)
            curr_constraint = all_cons_ind_affexpr[i-length(all_cons_affexpr)]
        end
        println("Constraint: $(curr_constraint)")
        println("\tError: $(val_check_results[i])")
        if print_var_values
            print_values_in_cst(model, curr_constraint)
        end
    end

    return maximum(val_check_results)
end

function count_constraint_errors(model::Model; ignore_floats::Bool=false, kwargs...)::Float64
    all_cons = all_constraints_affexpr(model)
    val_check_results = zeros(length(all_cons))
    for i in 1:length(all_cons)
        curr_constraint = all_cons[i]
        if ignore_floats
            cst_object = constraint_object(curr_constraint)
            cst_variables = [k for k in keys(cst_object.func.terms)]
            has_float_var = true in [is_binary.(cst_variables) .|| is_integer.(cst_variables)]
            if !has_float_var
                continue
            end
        end
        val_check_results[i] = check_constraint(curr_constraint; kwargs...)
    end

    return count(x -> x != 0, val_check_results)
end

function is_exact(model::Model; kwargs...)
    return check_result(model; kwargs...) == 0.0
end

function simplify_model!(model::Model; kwargs...)
    fix_int!(model)
    simplify_fix_var!(model)

    return model
end
