### generic features that apply to all active-power-only (apo) approximations


"apo models ignore reactive power flows"
function variable_reactive_generation(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_generation_on_off(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_storage(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_storage_on_off(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_branch_flow(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_branch_flow_ne(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_dcline_flow(pm::AbstractActivePowerModel; kwargs...)
end

"do nothing, apo models do not have reactive variables"
function constraint_reactive_gen_setpoint(pm::AbstractActivePowerModel, n::Int, i, qg)
end


"on/off constraint for generators"
function constraint_generation_on_off(pm::AbstractActivePowerModel, n::Int, i::Int, pmin, pmax, qmin, qmax)
    pg = var(pm, n, :pg, i)
    z = var(pm, n, :z_gen, i)

    JuMP.@constraint(pm.model, pg <= pmax*z)
    JuMP.@constraint(pm.model, pg >= pmin*z)
end



""
function constraint_power_balance(pm::AbstractActivePowerModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    p    = get(var(pm, n),    :p, Dict()); _check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = get(var(pm, n),   :pg, Dict()); _check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = get(var(pm, n),   :ps, Dict()); _check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = get(var(pm, n),  :psw, Dict()); _check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(var(pm, n), :p_dc, Dict()); _check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")


    con(pm, n, :kcl_p)[i] = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*1.0^2
    )
end


""
function constraint_power_balance_ne(pm::AbstractDCPModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_arcs_ne, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    p    = get(var(pm, n),    :p, Dict()); _check_var_keys(p, bus_arcs, "active power", "branch")
    pg   = get(var(pm, n),   :pg, Dict()); _check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = get(var(pm, n),   :ps, Dict()); _check_var_keys(ps, bus_storage, "active power", "storage")
    psw  = get(var(pm, n),  :psw, Dict()); _check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    p_dc = get(var(pm, n), :p_dc, Dict()); _check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    p_ne = get(var(pm, n), :p_ne, Dict()); _check_var_keys(p_ne, bus_arcs_ne, "active power", "ne_branch")

    con(pm, n, :kcl_p)[i] = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        + sum(p_ne[a] for a in bus_arcs_ne)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*1.0^2
    )
end


""
function expression_power_injection(pm::AbstractActivePowerModel, n::Int, i::Int, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    pg   = get(var(pm, n),   :pg, Dict()); _check_var_keys(pg, bus_gens, "active power", "generator")
    ps   = get(var(pm, n),   :ps, Dict()); _check_var_keys(ps, bus_storage, "active power", "storage")

    pg_total = 0.0
    if length(bus_gens) > 0
        pg_total = sum(pg[g] for g in bus_gens)
    end

    ps_total = 0.0
    if length(bus_storage) > 0
        ps_total = sum(ps[s] for s in bus_storage)
    end

    pd_total = 0.0
    if length(bus_pd) > 0
        pd_total = sum(pd for pd in values(bus_pd))
    end

    gs_total = 0.0
    if length(bus_gs) > 0
        gs_total = sum(gs for gs in values(bus_gs))*1.0^2
    end

    var(pm, n, :inj_p)[i] = pg_total - ps_total - pd_total - gs_total
end


"`-rate_a <= p[f_idx] <= rate_a`"
function constraint_thermal_limit_from(pm::AbstractActivePowerModel, n::Int, f_idx, rate_a)
    p_fr = var(pm, n, :p, f_idx)
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_lower_bound(p_fr)
        con(pm, n, :sm_fr)[f_idx[1]] = JuMP.LowerBoundRef(p_fr)
        JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
        if JuMP.has_upper_bound(p_fr)
            JuMP.upper_bound(p_fr) > rate_a && JuMP.set_upper_bound(p_fr, rate_a)
        end
    else
        con(pm, n, :sm_fr)[f_idx[1]] = JuMP.@constraint(pm.model, p_fr <= rate_a)
    end
end

""
function constraint_thermal_limit_to(pm::AbstractActivePowerModel, n::Int, t_idx, rate_a)
    p_to = var(pm, n, :p, t_idx)
    if isa(p_to, JuMP.VariableRef) && JuMP.has_lower_bound(p_to)
        con(pm, n, :sm_to)[t_idx[1]] = JuMP.LowerBoundRef(p_to)
        JuMP.lower_bound(p_to) < -rate_a && JuMP.set_lower_bound(p_to, -rate_a)
        if JuMP.has_upper_bound(p_to)
            JuMP.upper_bound(p_to) >  rate_a && JuMP.set_upper_bound(p_to,  rate_a)
        end
    else
        con(pm, n, :sm_to)[t_idx[1]] = JuMP.@constraint(pm.model, p_to <= rate_a)
    end
end

""
function constraint_current_limit(pm::AbstractActivePowerModel, n::Int, f_idx, c_rating_a)
    p_fr = var(pm, n, :p, f_idx)

    JuMP.lower_bound(p_fr) < -c_rating_a && JuMP.set_lower_bound(p_fr, -c_rating_a)
    JuMP.upper_bound(p_fr) >  c_rating_a && JuMP.set_upper_bound(p_fr,  c_rating_a)
end


""
function constraint_thermal_limit_from_on_off(pm::AbstractActivePowerModel, n::Int, i, f_idx, rate_a)
    p_fr = var(pm, n, :p, f_idx)
    z = var(pm, n, :z_branch, i)

    JuMP.@constraint(pm.model, p_fr <=  rate_a*z)
    JuMP.@constraint(pm.model, p_fr >= -rate_a*z)
end

""
function constraint_thermal_limit_to_on_off(pm::AbstractActivePowerModel, n::Int, i, t_idx, rate_a)
    p_to = var(pm, n, :p, t_idx)
    z = var(pm, n, :z_branch, i)

    JuMP.@constraint(pm.model, p_to <=  rate_a*z)
    JuMP.@constraint(pm.model, p_to >= -rate_a*z)
end

""
function constraint_thermal_limit_from_ne(pm::AbstractActivePowerModel, n::Int, i, f_idx, rate_a)
    p_fr = var(pm, n, :p_ne, f_idx)
    z = var(pm, n, :branch_ne, i)

    JuMP.@constraint(pm.model, p_fr <=  rate_a*z)
    JuMP.@constraint(pm.model, p_fr >= -rate_a*z)
end

""
function constraint_thermal_limit_to_ne(pm::AbstractActivePowerModel, n::Int, i, t_idx, rate_a)
    p_to = var(pm, n, :p_ne, t_idx)
    z = var(pm, n, :branch_ne, i)

    JuMP.@constraint(pm.model, p_to <=  rate_a*z)
    JuMP.@constraint(pm.model, p_to >= -rate_a*z)
end



""
function constraint_switch_thermal_limit(pm::AbstractActivePowerModel, n::Int, f_idx, rating)
    psw = var(pm, n, :psw, f_idx)

    JuMP.lower_bound(psw) < -rating && JuMP.set_lower_bound(psw, -rating)
    JuMP.upper_bound(psw) >  rating && JuMP.set_upper_bound(psw,  rating)
end



""
function constraint_storage_thermal_limit(pm::AbstractActivePowerModel, n::Int, i, rating)
    ps = var(pm, n, :ps, i)

    JuMP.lower_bound(ps) < -rating && JuMP.set_lower_bound(ps, -rating)
    JuMP.upper_bound(ps) >  rating && JuMP.set_upper_bound(ps,  rating)
end

""
function constraint_storage_current_limit(pm::AbstractActivePowerModel, n::Int, i, bus, rating)
    ps = var(pm, n, :ps, i)

    JuMP.lower_bound(ps) < -rating && JuMP.set_lower_bound(ps, -rating)
    JuMP.upper_bound(ps) >  rating && JuMP.set_upper_bound(ps,  rating)
end

""
function constraint_storage_loss(pm::AbstractActivePowerModel, n::Int, i, bus, r, x, p_loss, q_loss; conductors=[1])
    ps = var(pm, n, :ps, i)
    sc = var(pm, n, :sc, i)
    sd = var(pm, n, :sd, i)

    JuMP.@constraint(pm.model,
        sum(ps[c] for c in conductors) + (sd - sc)
        ==
        p_loss + sum(r[c]*ps[c]^2 for c in conductors)
    )
end

function constraint_storage_on_off(pm::AbstractActivePowerModel, n::Int, i, pmin, pmax, qmin, qmax, charge_ub, discharge_ub)
    z_storage = var(pm, n, :z_storage, i)
    ps = var(pm, n, :ps, i)

    JuMP.@constraint(pm.model, ps <= z_storage*pmax)
    JuMP.@constraint(pm.model, ps >= z_storage*pmin)
end


""
function add_setpoint_switch_flow!(sol, pm::AbstractActivePowerModel)
    add_setpoint!(sol, pm, "switch", "psw", :psw, var_key = (idx,item) -> (idx, item["f_bus"], item["t_bus"]))
    add_setpoint_fixed!(sol, pm, "switch", "qsw")
end
