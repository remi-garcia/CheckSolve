import JuMP.all_constraints
function all_constraints(model::Model)
    cstr = Vector{ConstraintRef}()
    for (F, S) in list_of_constraint_types(model)
        append!(cstr, all_constraints(model, F, S))
    end
    return cstr
end
function all_constraints_affexpr(model::Model)
    cstr = Vector{ConstraintRef}()
    for (F, S) in list_of_constraint_types(model)
        if F == AffExpr
            append!(cstr, all_constraints(model, F, S))
        end
    end
    return cstr
end
function all_constraints_ind_affexpr(model::Model)
    cstr = Vector{ConstraintRef}()
    for (F, S) in list_of_constraint_types(model)
        if F == Vector{AffExpr}
            append!(cstr, all_constraints(model, F, S))
        end
    end
    return cstr
end

function value_int(con)
    return value(x -> is_integer(x) || is_binary(x) ? round(Int, value(x)) : value(x), con)
end

function fix_int!(model::Model)
    all_variable_names = sort!(name.(all_variables(model)))
    all_values = Dict{String, Int}()
    for var_name in all_variable_names
        var_curr = variable_by_name(model, var_name)
        if is_integer(var_curr) || is_binary(var_curr)
            var_val = round(Int, var_val)
            all_values[var_name] = var_val
        end
    end

    for (var_name, var_val) in all_values
        var_curr = variable_by_name(model, var_name)
        fix(var_curr, var_val, force=true)
    end

    return model
end

function simplify_fix_var!(model::Model)
    cstr = all_constraints_affexpr(model)
    for curr_constraint in cstr
        cst_object = constraint_object(curr_constraint)
        cst_variables = [k for k in keys(cst_object.func.terms)]
        for curr_variable in cst_variables
            set_normalized_rhs(curr_constraint, normalized_rhs(curr_constraint)-normalized_coefficient(curr_constraint, curr_variable)*fix_value(curr_variable))
            set_normalized_coefficient(curr_constraint, curr_variable, 0)
        end
    end

    return model
end

function _var_in_constraint(con::AffExpr)
    return [k for k in keys(con.terms)]
end
function _var_in_constraint(con::Vector{AffExpr})
    return reduce(vcat, [_var_in_constraint(curr_con) for curr_con in con])
end

function var_in_constraint(con::ConstraintRef)
    return _var_in_constraint(constraint_object(con).func)
end

function print_values_in_cst(con::ConstraintRef; ignore_vars::Vector{VariableRef})
    var_in = setdiff(var_in_constraint(con), ignore_vars)
    for curr_var_in in var_in
        println("$(name(curr_var_in)) = $(value(curr_var_in))")
    end

    return nothing
end
