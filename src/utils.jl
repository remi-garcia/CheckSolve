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

function value_int(x)
    return value(x -> is_integer(x) || is_binary(x) ? round(Int, value(x)) : value(x), con)
end
