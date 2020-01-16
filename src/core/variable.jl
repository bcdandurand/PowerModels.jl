################################################################################
# This file defines common variables used in power flow models
# This will hopefully make everything more compositional
################################################################################


function comp_start_value(comp::Dict{String,<:Any}, key::String, default=0.0)
    return get(comp, key, default)
end


"variable: `t[i]` for `i` in `bus`es"
function variable_voltage_angle(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true)
    var(pm, nw)[:va] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :bus)], base_name="$(nw)_va",
        start = comp_start_value(ref(pm, nw, :bus, i), "va_start")
    )
end

"variable: `v[i]` for `i` in `bus`es"
function variable_voltage_magnitude(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    if bounded
        var(pm, nw)[:vm] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_vm",
            lower_bound = ref(pm, nw, :bus, i, "vmin"),
            upper_bound = ref(pm, nw, :bus, i, "vmax"),
            start = comp_start_value(ref(pm, nw, :bus, i), "vm_start", 1.0)
        )
    else
        var(pm, nw)[:vm] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_vm",
            start = comp_start_value(ref(pm, nw, :bus, i), "vm_start", 1.0)
        )
    end
end


"real part of the voltage variable `i` in `bus`es"
function variable_voltage_real(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true)
    if bounded
        var(pm, nw)[:vr] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_vr",
            lower_bound = -ref(pm, nw, :bus, i, "vmax"),
            upper_bound =  ref(pm, nw, :bus, i, "vmax"),
            start = comp_start_value(ref(pm, nw, :bus, i), "vr_start", 1.0)
        )
    else
        var(pm, nw)[:vr] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_vr",
            start = comp_start_value(ref(pm, nw, :bus, i), "vr_start", 1.0)
        )
    end
end

"real part of the voltage variable `i` in `bus`es"
function variable_voltage_imaginary(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true)
    if bounded
        var(pm, nw)[:vi] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_vi",
            lower_bound = -ref(pm, nw, :bus, i, "vmax"),
            upper_bound =  ref(pm, nw, :bus, i, "vmax"),
            start = comp_start_value(ref(pm, nw, :bus, i), "vi_start")
        )
    else
        var(pm, nw)[:vi] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_vi",
            start = comp_start_value(ref(pm, nw, :bus, i), "vi_start")
        )
    end
end



"variable: `0 <= vm_fr[l] <= buses[branches[l][\"f_bus\"]][\"vmax\"]` for `l` in `branch`es"
function variable_voltage_magnitude_from_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    buses = ref(pm, nw, :bus)
    branches = ref(pm, nw, :branch)

    var(pm, nw)[:vm_fr] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :branch)], base_name="$(nw)_vm_fr",
        lower_bound = 0,
        upper_bound = buses[branches[i]["f_bus"]]["vmax"],
        start = comp_start_value(ref(pm, nw, :branch, i), "vm_fr_start", 1.0)
    )
end

"variable: `0 <= vm_to[l] <= buses[branches[l][\"t_bus\"]][\"vmax\"]` for `l` in `branch`es"
function variable_voltage_magnitude_to_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    buses = ref(pm, nw, :bus)
    branches = ref(pm, nw, :branch)

    var(pm, nw)[:vm_to] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :branch)], base_name="$(nw)_vm_to",
        lower_bound = 0,
        upper_bound = buses[branches[i]["t_bus"]]["vmax"],
        start = comp_start_value(ref(pm, nw, :branch, i), "vm_to_start", 1.0)
    )
end


"variable: `w[i] >= 0` for `i` in `bus`es"
function variable_voltage_magnitude_sqr(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    if bounded
        var(pm, nw)[:w] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_w",
            lower_bound = ref(pm, nw, :bus, i, "vmin")^2,
            upper_bound = ref(pm, nw, :bus, i, "vmax")^2,
            start = comp_start_value(ref(pm, nw, :bus, i), "w_start", 1.001)
        )
    else
        var(pm, nw)[:w] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :bus)], base_name="$(nw)_w",
            lower_bound = 0.0,
            start = comp_start_value(ref(pm, nw, :bus, i), "w_start", 1.001)
        )
    end
end

"variable: `0 <= w_fr[l] <= buses[branches[l][\"f_bus\"]][\"vmax\"]^2` for `l` in `branch`es"
function variable_voltage_magnitude_sqr_from_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    buses = ref(pm, nw, :bus)
    branches = ref(pm, nw, :branch)

    var(pm, nw)[:w_fr] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :branch)], base_name="$(nw)_w_fr",
        lower_bound = 0,
        upper_bound = buses[branches[i]["f_bus"]]["vmax"]^2,
        start = comp_start_value(ref(pm, nw, :branch, i), "w_fr_start", 1.001)
    )
end

"variable: `0 <= w_to[l] <= buses[branches[l][\"t_bus\"]][\"vmax\"]^2` for `l` in `branch`es"
function variable_voltage_magnitude_sqr_to_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    buses = ref(pm, nw, :bus)
    branches = ref(pm, nw, :branch)

    var(pm, nw)[:w_to] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :branch)], base_name="$(nw)_w_to",
        lower_bound = 0,
        upper_bound = buses[branches[i]["t_bus"]]["vmax"]^2,
        start = comp_start_value(ref(pm, nw, :branch, i), "w_to_start", 1.001)
    )
end

""
function variable_cosine(pm::AbstractPowerModel; nw::Int=pm.cnw)
    cos_min = Dict((bp, -Inf) for bp in ids(pm, nw, :buspairs))
    cos_max = Dict((bp,  Inf) for bp in ids(pm, nw, :buspairs))

    for (bp, buspair) in ref(pm, nw, :buspairs)
        angmin = buspair["angmin"]
        angmax = buspair["angmax"]
        if angmin >= 0
            cos_max[bp] = cos(angmin)
            cos_min[bp] = cos(angmax)
        end
        if angmax <= 0
            cos_max[bp] = cos(angmax)
            cos_min[bp] = cos(angmin)
        end
        if angmin < 0 && angmax > 0
            cos_max[bp] = 1.0
            cos_min[bp] = min(cos(angmin), cos(angmax))
        end
    end

    var(pm, nw)[:cs] = JuMP.@variable(pm.model,
        [bp in ids(pm, nw, :buspairs)], base_name="$(nw)_cs",
        lower_bound = cos_min[bp],
        upper_bound = cos_max[bp],
        start = comp_start_value(ref(pm, nw, :buspairs, bp), "cs_start", 1.0)
    )
end

""
function variable_sine(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:si] = JuMP.@variable(pm.model,
        [bp in ids(pm, nw, :buspairs)], base_name="$(nw)_si",
        lower_bound = sin(ref(pm, nw, :buspairs, bp, "angmin")),
        upper_bound = sin(ref(pm, nw, :buspairs, bp, "angmax")),
        start = comp_start_value(ref(pm, nw, :buspairs, bp), "si_start")
    )
end

""
function variable_voltage_product(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    wr = var(pm, nw)[:wr] = JuMP.@variable(pm.model,
        [bp in ids(pm, nw, :buspairs)], base_name="$(nw)_wr",
        start = comp_start_value(ref(pm, nw, :buspairs, bp), "wr_start", 1.0)
    )
    wi = var(pm, nw)[:wi] = JuMP.@variable(pm.model,
        [bp in ids(pm, nw, :buspairs)], base_name="$(nw)_wi",
        start = comp_start_value(ref(pm, nw, :buspairs, bp), "wi_start")
    )

    if bounded
        wr_min, wr_max, wi_min, wi_max = ref_calc_voltage_product_bounds(ref(pm, nw, :buspairs))

        for bp in ids(pm, nw, :buspairs)
            JuMP.set_lower_bound(wr[bp], wr_min[bp])
            JuMP.set_upper_bound(wr[bp], wr_max[bp])

            JuMP.set_lower_bound(wi[bp], wi_min[bp])
            JuMP.set_upper_bound(wi[bp], wi_max[bp])
        end
    end
end

""
function variable_voltage_product_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    wr_min, wr_max, wi_min, wi_max = ref_calc_voltage_product_bounds(ref(pm, nw, :buspairs))
    bi_bp = Dict((i, (b["f_bus"], b["t_bus"])) for (i,b) in ref(pm, nw, :branch))

    var(pm, nw)[:wr] = JuMP.@variable(pm.model,
        [b in ids(pm, nw, :branch)], base_name="$(nw)_wr",
        lower_bound = min(0, wr_min[bi_bp[b]]),
        upper_bound = max(0, wr_max[bi_bp[b]]),
        start = comp_start_value(ref(pm, nw, :buspairs, bi_bp[b]), "wr_start", 1.0)
    )
    var(pm, nw)[:wi] = JuMP.@variable(pm.model,
        [b in ids(pm, nw, :branch)], base_name="$(nw)_wi",
        lower_bound = min(0, wi_min[bi_bp[b]]),
        upper_bound = max(0, wi_max[bi_bp[b]]),
        start = comp_start_value(ref(pm, nw, :buspairs, bi_bp[b]), "wi_start")
    )
end


"generates variables for both `active` and `reactive` generation"
function variable_generation(pm::AbstractPowerModel; kwargs...)
    variable_active_generation(pm; kwargs...)
    variable_reactive_generation(pm; kwargs...)
end


"variable: `pg[j]` for `j` in `gen`"
function variable_active_generation(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    if bounded
        var(pm, nw)[:pg] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :gen)], base_name="$(nw)_pg",
            lower_bound = ref(pm, nw, :gen, i, "pmin"),
            upper_bound = ref(pm, nw, :gen, i, "pmax"),
            start = comp_start_value(ref(pm, nw, :gen, i), "pg_start")
        )
    else
        var(pm, nw)[:pg] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :gen)], base_name="$(nw)_pg",
            start = comp_start_value(ref(pm, nw, :gen, i), "pg_start")
        )
    end
end

"variable: `qq[j]` for `j` in `gen`"
function variable_reactive_generation(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    if bounded
        var(pm, nw)[:qg] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :gen)], base_name="$(nw)_qg",
            lower_bound = ref(pm, nw, :gen, i, "qmin"),
            upper_bound = ref(pm, nw, :gen, i, "qmax"),
            start = comp_start_value(ref(pm, nw, :gen, i), "qg_start")
        )
    else
        var(pm, nw)[:qg] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :gen)], base_name="$(nw)_qg",
            start = comp_start_value(ref(pm, nw, :gen, i), "qg_start")
        )
    end
end

"variable: `crg[j]` for `j` in `gen`"
function variable_gen_current_real(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    gen = ref(pm, nw, :gen)
    bus = ref(pm, nw, :bus)

    crg = var(pm, nw)[:crg] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :gen)], base_name="$(nw)_crg",
        start = comp_start_value(ref(pm, nw, :gen, i), "crg_start")
    )

    if bounded
        ub = Dict()
        for (i, g) in gen
            vmin = bus[g["gen_bus"]]["vmin"]
            @assert vmin>0
            s = sqrt(max(abs(g["pmax"]), abs(g["pmin"]))^2 + max(abs(g["qmax"]), abs(g["qmin"]))^2)
            ub[i] = s/vmin
        end

        for (i, g) in gen
            JuMP.set_lower_bound(crg[i], -ub[i])
            JuMP.set_upper_bound(crg[i], ub[i])
        end
    end
end

"variable: `cig[j]` for `j` in `gen`"
function variable_gen_current_imaginary(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    gen = ref(pm, nw, :gen)
    bus = ref(pm, nw, :bus)

    cig = var(pm, nw)[:cig] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :gen)], base_name="$(nw)_cig",
        start = comp_start_value(ref(pm, nw, :gen, i), "cig_start")
    )

    if bounded
        ub = Dict()
        for (i, g) in gen
            vmin = bus[g["gen_bus"]]["vmin"]
            @assert vmin>0
            s = sqrt(max(abs(g["pmax"]), abs(g["pmin"]))^2 + max(abs(g["qmax"]), abs(g["qmin"]))^2)
            ub[i] = s/vmin
        end

        for (i, g) in gen
            JuMP.set_lower_bound(cig[i], -ub[i])
            JuMP.set_upper_bound(cig[i], ub[i])
        end
    end
end

function variable_generation_indicator(pm::AbstractPowerModel; nw::Int=pm.cnw, relax=false)
    if !relax
        var(pm, nw)[:z_gen] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :gen)], base_name="$(nw)_z_gen",
            binary = true,
            start = comp_start_value(ref(pm, nw, :gen, i), "z_gen_start", 1.0)
        )
    else
        var(pm, nw)[:z_gen] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :gen)], base_name="$(nw)_z_gen",
            lower_bound = 0,
            upper_bound = 1,
            start = comp_start_value(ref(pm, nw, :gen, i), "z_gen_start", 1.0)
        )
    end
end


function variable_generation_on_off(pm::AbstractPowerModel; kwargs...)
    variable_active_generation_on_off(pm; kwargs...)
    variable_reactive_generation_on_off(pm; kwargs...)
end

function variable_active_generation_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:pg] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :gen)], base_name="$(nw)_pg",
        lower_bound = min(0, ref(pm, nw, :gen, i, "pmin")),
        upper_bound = max(0, ref(pm, nw, :gen, i, "pmax")),
        start = comp_start_value(ref(pm, nw, :gen, i), "pg_start")
    )
end

function variable_reactive_generation_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:qg] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :gen)], base_name="$(nw)_qg",
        lower_bound = min(0, ref(pm, nw, :gen, i, "qmin")),
        upper_bound = max(0, ref(pm, nw, :gen, i, "qmax")),
        start = comp_start_value(ref(pm, nw, :gen, i), "qg_start")
    )
end



""
function variable_branch_flow(pm::AbstractPowerModel; kwargs...)
    variable_active_branch_flow(pm; kwargs...)
    variable_reactive_branch_flow(pm; kwargs...)
end


"variable: `p[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_active_branch_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    p = var(pm, nw)[:p] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_p",
        start = comp_start_value(ref(pm, nw, :branch, l), "p_start")
    )

    if bounded
        flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :branch), ref(pm, nw, :bus))

        for arc in ref(pm, nw, :arcs)
            l,i,j = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(p[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(p[arc], flow_ub[l])
            end
        end
    end

    for (l,branch) in ref(pm, nw, :branch)
        if haskey(branch, "pf_start")
            f_idx = (l, branch["f_bus"], branch["t_bus"])
            JuMP.set_start_value(p[f_idx], branch["pf_start"])
        end
        if haskey(branch, "pt_start")
            t_idx = (l, branch["t_bus"], branch["f_bus"])
            JuMP.set_start_value(p[t_idx], branch["pt_start"])
        end
    end
end

"variable: `q[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_reactive_branch_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    q = var(pm, nw)[:q] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_q",
        start = comp_start_value(ref(pm, nw, :branch, l), "q_start")
    )

    if bounded
        flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :branch), ref(pm, nw, :bus))

        for arc in ref(pm, nw, :arcs)
            l,i,j = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(q[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(q[arc], flow_ub[l])
            end
        end
    end

    for (l,branch) in ref(pm, nw, :branch)
        if haskey(branch, "qf_start")
            f_idx = (l, branch["f_bus"], branch["t_bus"])
            JuMP.set_start_value(q[f_idx], branch["qf_start"])
        end
        if haskey(branch, "qt_start")
            t_idx = (l, branch["t_bus"], branch["f_bus"])
            JuMP.set_start_value(q[t_idx], branch["qt_start"])
        end
    end
end

"variable: `cr[l,i,j]` for `(l,i,j)` in `arcs`"
function variable_branch_current_real(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    branch = ref(pm, nw, :branch)
    bus = ref(pm, nw, :bus)

    cr = var(pm, nw)[:cr] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_cr",
        start = comp_start_value(ref(pm, nw, :branch, l), "cr_start")
    )

    if bounded
        ub = Dict()
        for (l,i,j) in ref(pm, nw, :arcs_from)
            b = branch[l]
            ub[l] = Inf
            if haskey(b, "rate_a")
                rate_fr = b["rate_a"]*b["tap"]
                rate_to = b["rate_a"]
                ub[l]  = max(rate_fr/bus[i]["vmin"], rate_to/bus[j]["vmin"])
            end
            if haskey(b, "c_rating_a")
                ub[l] = b["c_rating_a"]
            end
        end

        for (l,i,j) in ref(pm, nw, :arcs)
            if !isinf(ub[l])
                JuMP.set_lower_bound(cr[(l,i,j)], -ub[l])
                JuMP.set_upper_bound(cr[(l,i,j)], ub[l])
            end
        end
    end
end


"variable: `ci[l,i,j] ` for `(l,i,j)` in `arcs`"
function variable_branch_current_imaginary(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    branch = ref(pm, nw, :branch)
    bus = ref(pm, nw, :bus)

    ci = var(pm, nw)[:ci] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs)], base_name="$(nw)_ci",
        start = comp_start_value(ref(pm, nw, :branch, l), "ci_start")
    )

    if bounded
        ub = Dict()
        for (l,i,j) in ref(pm, nw, :arcs_from)
            b = branch[l]
            ub[l] = Inf
            if haskey(b, "rate_a")
                rate_fr = b["rate_a"]*b["tap"]
                rate_to = b["rate_a"]
                ub[l]  = max(rate_fr/bus[i]["vmin"], rate_to/bus[j]["vmin"])
            end
            if haskey(b, "c_rating_a")
                ub[l] = b["c_rating_a"]
            end
        end

        for (l,i,j) in ref(pm, nw, :arcs)
            if !isinf(ub[l])
                JuMP.set_lower_bound(ci[(l,i,j)], -ub[l])
                JuMP.set_upper_bound(ci[(l,i,j)], ub[l])
            end
        end
    end
end


"variable: `csr[l,i,j]` for `(l,i,j)` in `arcs_from`"
function variable_branch_series_current_real(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    branch = ref(pm, nw, :branch)
    bus = ref(pm, nw, :bus)

    csr = var(pm, nw)[:csr] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_from)], base_name="$(nw)_csr",
        start = comp_start_value(branch[l], "csr_start", 0.0)
    )

    if bounded
        ub = Dict()
        for (l,i,j) in ref(pm, nw, :arcs_from)
            b = branch[l]
            ub[l] = Inf
            if haskey(b, "rate_a")
                rate = b["rate_a"]*b["tap"]
                y_fr = abs(b["g_fr"] + im*b["b_fr"])
                y_to = abs(b["g_to"] + im*b["b_to"])
                shuntcurrent = max(y_fr*bus[i]["vmax"]^2, y_to*bus[j]["vmax"]^2)
                seriescurrent = max(rate/bus[i]["vmin"], rate/bus[j]["vmin"])
                ub[l] = seriescurrent + shuntcurrent
            end
            if haskey(b, "c_rating_a")
                totalcurrent = b["c_rating_a"]
                y_fr = abs(b["g_fr"] + im*b["b_fr"])
                y_to = abs(b["g_to"] + im*b["b_to"])
                shuntcurrent = max(y_fr*bus[i]["vmax"]^2, y_to*bus[j]["vmax"]^2)
                ub[l] = totalcurrent + shuntcurrent
            end
        end

        for (l,i,j) in ref(pm, nw, :arcs_from)
            if !isinf(ub[l])
                JuMP.set_lower_bound(csr[(l,i,j)], -ub[l])
                JuMP.set_upper_bound(csr[(l,i,j)], ub[l])
            end
        end
    end
end

"variable: `csi[l,i,j] ` for `(l,i,j)` in `arcs_from`"
function variable_branch_series_current_imaginary(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    branch = ref(pm, nw, :branch)
    bus = ref(pm, nw, :bus)
    csi = var(pm, nw)[:csi] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_from)], base_name="$(nw)_csi",
        start = comp_start_value(branch[l], "csi_start", 0.0)
    )

    if bounded
        ub = Dict()
        for (l,i,j) in ref(pm, nw, :arcs_from)
            b = branch[l]
            ub[l] = Inf
            if haskey(b, "rate_a")
                rate = b["rate_a"]*b["tap"]
                y_fr = abs(b["g_fr"] + im*b["b_fr"])
                y_to = abs(b["g_to"] + im*b["b_to"])
                shuntcurrent = max(y_fr*bus[i]["vmax"]^2, y_to*bus[j]["vmax"]^2)
                seriescurrent = max(rate/bus[i]["vmin"], rate/bus[j]["vmin"])
                ub[l] = seriescurrent + shuntcurrent
            end
            if haskey(b, "c_rating_a")
                totalcurrent = b["c_rating_a"]
                y_fr = abs(b["g_fr"] + im*b["b_fr"])
                y_to = abs(b["g_to"] + im*b["b_to"])
                shuntcurrent = max(y_fr*bus[i]["vmax"]^2, y_to*bus[j]["vmax"]^2)
                ub[l] = totalcurrent + shuntcurrent
            end
        end

        for (l,i,j) in ref(pm, nw, :arcs_from)
            if !isinf(ub[l])
                JuMP.set_lower_bound(csi[(l,i,j)], -ub[l])
                JuMP.set_upper_bound(csi[(l,i,j)], ub[l])
            end
        end
    end
end


function variable_dcline_flow(pm::AbstractPowerModel; kwargs...)
    variable_active_dcline_flow(pm; kwargs...)
    variable_reactive_dcline_flow(pm; kwargs...)
end

"variable: `p_dc[l,i,j]` for `(l,i,j)` in `arcs_dc`"
function variable_active_dcline_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    p_dc = var(pm, nw)[:p_dc] = JuMP.@variable(pm.model,
        [arc in ref(pm, nw, :arcs_dc)], base_name="$(nw)_p_dc",
    )

    if bounded
        for (l,dcline) in ref(pm, nw, :dcline)
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])

            JuMP.set_lower_bound(p_dc[f_idx], dcline["pminf"])
            JuMP.set_upper_bound(p_dc[f_idx], dcline["pmaxf"])

            JuMP.set_lower_bound(p_dc[t_idx], dcline["pmint"])
            JuMP.set_upper_bound(p_dc[t_idx], dcline["pmaxt"])
        end
    end

    for (l,dcline) in ref(pm, nw, :dcline)
        if haskey(dcline, "pf")
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            JuMP.set_start_value(p_dc[f_idx], dcline["pf"])
        end

        if haskey(dcline, "pt")
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])
            JuMP.set_start_value(p_dc[t_idx], dcline["pt"])
        end
    end
end

"variable: `q_dc[l,i,j]` for `(l,i,j)` in `arcs_dc`"
function variable_reactive_dcline_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    q_dc = var(pm, nw)[:q_dc] = JuMP.@variable(pm.model,
        [arc in ref(pm, nw, :arcs_dc)], base_name="$(nw)_q_dc",
    )

    if bounded
        for (l,dcline) in ref(pm, nw, :dcline)
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])

            JuMP.set_lower_bound(q_dc[f_idx], dcline["qminf"])
            JuMP.set_upper_bound(q_dc[f_idx], dcline["qmaxf"])

            JuMP.set_lower_bound(q_dc[t_idx], dcline["qmint"])
            JuMP.set_upper_bound(q_dc[t_idx], dcline["qmaxt"])
        end
    end

    for (l,dcline) in ref(pm, nw, :dcline)
        if haskey(dcline, "qf")
            f_idx = (l, dcline["f_bus"], dcline["t_bus"])
            JuMP.set_start_value(q_dc[f_idx], dcline["qf"])
        end

        if haskey(dcline, "qt")
            t_idx = (l, dcline["t_bus"], dcline["f_bus"])
            JuMP.set_start_value(q_dc[t_idx], dcline["qt"])
        end
    end
end

"variable: `crdc[j]` for `j` in `dcline`"
function variable_dcline_current_real(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    bus = ref(pm, nw, :bus)
    dcline = ref(pm, nw, :dcline)

    crdc = var(pm, nw)[:crdc] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_dc)], base_name="$(nw)_crdc",
        start = comp_start_value(ref(pm, nw, :dcline, l), "crdc_start")
    )

    if bounded
        ub = Dict()
        for (l,i,j) in ref(pm, nw, :arcs_from_dc)
            vmin_fr = bus[i]["vmin"]
            vmin_to = bus[j]["vmin"]
            @assert vmin_fr>0
            @assert vmin_to>0
            s_fr = sqrt(max(abs(dcline[l]["pmaxf"]), abs(dcline[l]["pminf"]))^2 + max(abs(dcline[l]["qmaxf"]), abs(dcline[l]["qminf"]))^2)
            s_to = sqrt(max(abs(dcline[l]["pmaxt"]), abs(dcline[l]["pmint"]))^2 + max(abs(dcline[l]["qmaxt"]), abs(dcline[l]["qmint"]))^2)
            imax = max(s_fr,s_to)/ min(vmin_fr, vmin_to)
            ub[(l,i,j)] = imax
            ub[(l,j,i)] = imax
        end

        for (l,i,j) in ref(pm, nw, :arcs_dc)
            JuMP.set_lower_bound(crdc[(l,i,j)], -ub[(l,i,j)])
            JuMP.set_upper_bound(crdc[(l,i,j)], ub[(l,i,j)])
        end
    end
end

"variable:  `cidc[j]` for `j` in `dcline`"
function variable_dcline_current_imaginary(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    bus = ref(pm, nw, :bus)
    dcline = ref(pm, nw, :dcline)

    cidc = var(pm, nw)[:cidc] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_dc)], base_name="$(nw)_cidc",
        start = comp_start_value(ref(pm, nw, :dcline, l), "cidc_start")
    )

    if bounded
        ub = Dict()
        for (l,i,j) in ref(pm, nw, :arcs_from_dc)
            vmin_fr = bus[i]["vmin"]
            vmin_to = bus[j]["vmin"]
            @assert vmin_fr>0
            @assert vmin_to>0
            s_fr = sqrt(max(abs(dcline[l]["pmaxf"]), abs(dcline[l]["pminf"]))^2 + max(abs(dcline[l]["qmaxf"]), abs(dcline[l]["qminf"]))^2)
            s_to = sqrt(max(abs(dcline[l]["pmaxt"]), abs(dcline[l]["pmint"]))^2 + max(abs(dcline[l]["qmaxt"]), abs(dcline[l]["qmint"]))^2)
            imax = max(s_fr,s_to)/ min(vmin_fr, vmin_to)
            ub[(l,i,j)] = imax
            ub[(l,j,i)] = imax
        end

        for (l,i,j) in ref(pm, nw, :arcs_dc)
            JuMP.set_lower_bound(cidc[(l,i,j)], -ub[(l,i,j)])
            JuMP.set_upper_bound(cidc[(l,i,j)], ub[(l,i,j)])
        end
    end
end

function variable_switch_indicator(pm::AbstractPowerModel; nw::Int=pm.cnw, relax=false)
    if !relax
        var(pm, nw)[:z_switch] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :switch)], base_name="$(nw)_z_switch",
            binary = true,
            start = comp_start_value(ref(pm, nw, :switch, i), "z_switch_start", 1.0)
        )
    else
        var(pm, nw)[:z_switch] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :switch)], base_name="$(nw)_z_switch",
            lower_bound = 0,
            upper_bound = 1,
            start = comp_start_value(ref(pm, nw, :switch, i), "z_switch_start", 1.0)
        )
    end
end


""
function variable_switch_flow(pm::AbstractPowerModel; kwargs...)
    variable_active_switch_flow(pm; kwargs...)
    variable_reactive_switch_flow(pm; kwargs...)
end


"variable: `pws[l,i,j]` for `(l,i,j)` in `arcs_sw`"
function variable_active_switch_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    psw = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_from_sw)], base_name="$(nw)_psw",
        start = comp_start_value(ref(pm, nw, :switch, l), "psw_start")
    )

    if bounded
        flow_lb, flow_ub = ref_calc_switch_flow_bounds(ref(pm, nw, :switch), ref(pm, nw, :bus))

        for arc in ref(pm, nw, :arcs_from_sw)
            l,i,j = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(psw[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(psw[arc], flow_ub[l])
            end
        end
    end

    # this explicit type erasure is necessary
    psw_expr = Dict{Any,Any}( (l,i,j) => psw[(l,i,j)] for (l,i,j) in ref(pm, nw, :arcs_from_sw) )
    psw_expr = merge(psw_expr, Dict( (l,j,i) => -1.0*psw[(l,i,j)] for (l,i,j) in ref(pm, nw, :arcs_from_sw)))
    var(pm, nw)[:psw] = psw_expr
end


"variable: `pws[l,i,j]` for `(l,i,j)` in `arcs_sw`"
function variable_reactive_switch_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded = true)
    qsw = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :arcs_from_sw)], base_name="$(nw)_qsw",
        start = comp_start_value(ref(pm, nw, :switch, l), "qsw_start")
    )

    if bounded
        flow_lb, flow_ub = ref_calc_switch_flow_bounds(ref(pm, nw, :switch), ref(pm, nw, :bus))

        for arc in ref(pm, nw, :arcs_from_sw)
            l,i,j = arc
            if !isinf(flow_lb[l])
                JuMP.set_lower_bound(qsw[arc], flow_lb[l])
            end
            if !isinf(flow_ub[l])
                JuMP.set_upper_bound(qsw[arc], flow_ub[l])
            end
        end
    end

    # this explicit type erasure is necessary
    qsw_expr = Dict{Any,Any}( (l,i,j) => qsw[(l,i,j)] for (l,i,j) in ref(pm, nw, :arcs_from_sw) )
    qsw_expr = merge(qsw_expr, Dict( (l,j,i) => -1.0*qsw[(l,i,j)] for (l,i,j) in ref(pm, nw, :arcs_from_sw)))
    var(pm, nw)[:qsw] = qsw_expr
end



"variables for modeling storage units, includes grid injection and internal variables"
function variable_storage(pm::AbstractPowerModel; kwargs...)
    variable_active_storage(pm; kwargs...)
    variable_reactive_storage(pm; kwargs...)
    variable_current_storage(pm; kwargs...)
    variable_storage_energy(pm; kwargs...)
    variable_storage_charge(pm; kwargs...)
    variable_storage_discharge(pm; kwargs...)
end

"variables for modeling storage units, includes grid injection and internal variables, with mixed int variables for charge/discharge"
function variable_storage_mi(pm::AbstractPowerModel; kwargs...)
    variable_active_storage(pm; kwargs...)
    variable_reactive_storage(pm; kwargs...)
    variable_current_storage(pm; kwargs...)
    variable_storage_energy(pm; kwargs...)
    variable_storage_charge(pm; kwargs...)
    variable_storage_discharge(pm; kwargs...)
    variable_storage_complementary_indicator(pm; kwargs...)
end


""
function variable_active_storage(pm::AbstractPowerModel; nw::Int=pm.cnw)
    ps = var(pm, nw)[:ps] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_ps",
        start = comp_start_value(ref(pm, nw, :storage, i), "ps_start")
    )

    inj_lb, inj_ub = ref_calc_storage_injection_bounds(ref(pm, nw, :storage), ref(pm, nw, :bus))

    for i in ids(pm, nw, :storage)
        if !isinf(inj_lb[i])
            JuMP.set_lower_bound(ps[i], inj_lb[i])
        end
        if !isinf(inj_ub[i])
            JuMP.set_upper_bound(ps[i], inj_ub[i])
        end
    end
end

""
function variable_reactive_storage(pm::AbstractPowerModel; nw::Int=pm.cnw)
    inj_lb, inj_ub = ref_calc_storage_injection_bounds(ref(pm, nw, :storage), ref(pm, nw, :bus))

    var(pm, nw)[:qs] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_qs",
        lower_bound = max(inj_lb[i], ref(pm, nw, :storage, i, "qmin")),
        upper_bound = min(inj_ub[i], ref(pm, nw, :storage, i, "qmax")),
        start = comp_start_value(ref(pm, nw, :storage, i), "qs_start")
    )
end

"do nothing by default but some formulations require this"
function variable_current_storage(pm::AbstractPowerModel; nw::Int=pm.cnw)
end


""
function variable_storage_energy(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:se] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_se",
        lower_bound = 0,
        upper_bound = ref(pm, nw, :storage, i, "energy_rating"),
        start = comp_start_value(ref(pm, nw, :storage, i), "se_start", 1)
    )
end

""
function variable_storage_charge(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:sc] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_sc",
        lower_bound = 0,
        upper_bound = ref(pm, nw, :storage, i, "charge_rating"),
        start = comp_start_value(ref(pm, nw, :storage, i), "sc_start", 1)
    )
end

""
function variable_storage_discharge(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:sd] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_sd",
        lower_bound = 0,
        upper_bound = ref(pm, nw, :storage, i, "discharge_rating"),
        start = comp_start_value(ref(pm, nw, :storage, i), "sd_start", 1)
    )
end

""
function variable_storage_complementary_indicator(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:sc_on] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_sc_on", Bin,
        start = comp_start_value(ref(pm, nw, :storage, i), "sc_on_start", 0)
    )
    var(pm, nw)[:sd_on] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_sd_on", Bin,
        start = comp_start_value(ref(pm, nw, :storage, i), "sd_on_start", 0)
    )
end

function variable_storage_mi_on_off(pm::AbstractPowerModel; kwargs...)
    variable_active_storage_on_off(pm; kwargs...)
    variable_reactive_storage_on_off(pm; kwargs...)
    variable_storage_energy(pm; kwargs...)
    variable_storage_charge(pm; kwargs...)
    variable_storage_discharge(pm; kwargs...)
    variable_storage_complementary_indicator(pm; kwargs...)
end

function variable_active_storage_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    ps = var(pm, nw)[:ps] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_ps",
        start = comp_start_value(ref(pm, nw, :storage, i), "ps_start")
    )

    inj_lb, inj_ub = ref_calc_storage_injection_bounds(ref(pm, nw, :storage), ref(pm, nw, :bus))

    for i in ids(pm, nw, :storage)
        if !isinf(inj_lb[i])
            JuMP.set_lower_bound(ps[i], min(0, inj_lb[i]))
        end
        if !isinf(inj_lb[i])
            JuMP.set_upper_bound(ps[i], max(0, inj_ub[i]))
        end
    end
end

function variable_reactive_storage_on_off(pm::AbstractPowerModel; nw::Int=pm.cnw)
    inj_lb, inj_ub = ref_calc_storage_injection_bounds(ref(pm, nw, :storage), ref(pm, nw, :bus))

    var(pm, nw)[:qs] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :storage)], base_name="$(nw)_qs",
        lower_bound = min(0, max(inj_lb[i], ref(pm, nw, :storage, i, "qmin"))),
        upper_bound = max(0, min(inj_ub[i], ref(pm, nw, :storage, i, "qmax"))),
        start = comp_start_value(ref(pm, nw, :storage, i), "qs_start")
    )
end

function variable_storage_indicator(pm::AbstractPowerModel; nw::Int=pm.cnw, relax=false)
    if !relax
        var(pm, nw)[:z_storage] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :storage)], base_name="$(nw)_z_storage",
            binary = true,
            start = comp_start_value(ref(pm, nw, :storage, i), "z_storage_start", 1.0)
        )
    else
        var(pm, nw)[:z_storage] = JuMP.@variable(pm.model,
            [i in ids(pm, nw, :storage)], base_name="$(nw)_z_storage",
            lower_bound = 0,
            upper_bound = 1,
            start = comp_start_value(ref(pm, nw, :storage, i), "z_storage_start", 1.0)
        )
    end
end


##################################################################
### Network Expantion Variables

"generates variables for both `active` and `reactive` `branch_flow_ne`"
function variable_branch_flow_ne(pm::AbstractPowerModel; kwargs...)
    variable_active_branch_flow_ne(pm; kwargs...)
    variable_reactive_branch_flow_ne(pm; kwargs...)
end

"variable: `-ne_branch[l][\"rate_a\"] <= p_ne[l,i,j] <= ne_branch[l][\"rate_a\"]` for `(l,i,j)` in `ne_arcs`"
function variable_active_branch_flow_ne(pm::AbstractPowerModel; nw::Int=pm.cnw)
    p_ne = var(pm, nw)[:p_ne] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :ne_arcs)], base_name="$(nw)_p_ne",
        start = comp_start_value(ref(pm, nw, :ne_branch, l), "p_start")
    )

    flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :ne_branch), ref(pm, nw, :bus))

    for arc in ref(pm, nw, :ne_arcs)
        l,i,j = arc
        if !isinf(flow_lb[l])
            JuMP.set_lower_bound(p_ne[arc], flow_lb[l])
        end
        if !isinf(flow_ub[l])
            JuMP.set_upper_bound(p_ne[arc], flow_ub[l])
        end
    end
end

"variable: `-ne_branch[l][\"rate_a\"] <= q_ne[l,i,j] <= ne_branch[l][\"rate_a\"]` for `(l,i,j)` in `ne_arcs`"
function variable_reactive_branch_flow_ne(pm::AbstractPowerModel; nw::Int=pm.cnw)
    q_ne = var(pm, nw)[:q_ne] = JuMP.@variable(pm.model,
        [(l,i,j) in ref(pm, nw, :ne_arcs)], base_name="$(nw)_q_ne",
        start = comp_start_value(ref(pm, nw, :ne_branch, l), "q_start")
    )

    flow_lb, flow_ub = ref_calc_branch_flow_bounds(ref(pm, nw, :ne_branch), ref(pm, nw, :bus))

    for arc in ref(pm, nw, :ne_arcs)
        l,i,j = arc
        if !isinf(flow_lb[l])
            JuMP.set_lower_bound(q_ne[arc], flow_lb[l])
        end
        if !isinf(flow_ub[l])
            JuMP.set_upper_bound(q_ne[arc], flow_ub[l])
        end
    end
end

"variable: `0 <= z_branch[l] <= 1` for `l` in `branch`es"
function variable_branch_indicator(pm::AbstractPowerModel; nw::Int=pm.cnw, relax=false)
    if relax == false
        var(pm, nw)[:z_branch] = JuMP.@variable(pm.model,
            [l in ids(pm, nw, :branch)], base_name="$(nw)_z_branch",
            binary = true,
            start = comp_start_value(ref(pm, nw, :branch, l), "z_branch_start", 1.0)
        )
    else
        var(pm, nw)[:z_branch] = JuMP.@variable(pm.model,
            [l in ids(pm, nw, :branch)], base_name="$(nw)_z_branch",
            lower_bound = 0.0,
            upper_bound = 1.0,
            start = comp_start_value(ref(pm, nw, :branch, l), "z_branch_start", 1.0)
        )
    end
end

"variable: `0 <= branch_ne[l] <= 1` for `l` in `branch`es"
function variable_branch_ne(pm::AbstractPowerModel; nw::Int=pm.cnw)
    var(pm, nw)[:branch_ne] = JuMP.@variable(pm.model,
        [l in ids(pm, nw, :ne_branch)], base_name="$(nw)_branch_ne",
        binary = true,
        start = comp_start_value(ref(pm, nw, :ne_branch, l), "branch_tnep_start", 1.0)
    )
end
