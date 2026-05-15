module QueueingModels

using CairoMakie
using DataFrames
using Distributions
using StableRNGs
using Statistics
using LinearAlgebra

export analytic_mmc_metrics,
    run_mmc_experiment,
    run_mmc_parameter_scan,
    plot_mmc_queue_length,
    plot_mmc_busy_servers,
    plot_mmc_wait_histogram,
    plot_mmc_analytic_vs_simulation,
    plot_mmc_wait_by_channels,
    plot_mmc_wait_by_lambda,
    plot_mmc_utilization_heatmap,
    analytic_ross_crash_time,
    run_ross_experiment,
    run_ross_parameter_scan,
    plot_ross_good_machines,
    plot_ross_spares,
    plot_ross_repair_queue,
    plot_ross_crash_histogram,
    plot_ross_simulation_vs_analytic,
    plot_ross_repairer_utilization,
    plot_ross_crash_time_by_n,
    plot_ross_crash_time_by_spares,
    plot_ross_repairers_comparison,
    plot_ross_repairer_utilization_by_scenario

const MMC_EVENT = NamedTuple{
    (:time, :event, :customer_id, :queue_length, :busy_servers, :system_size),
    Tuple{Float64, String, Int, Int, Int, Int},
}

const ROSS_EVENT = NamedTuple{
    (:time, :event, :working, :spares, :broken, :repair_queue, :busy_repairers, :good_machines),
    Tuple{Float64, String, Int, Int, Int, Int, Int, Int},
}

safe_mean(xs) = isempty(xs) ? 0.0 : mean(xs)
safe_std(xs) = length(xs) <= 1 ? 0.0 : std(xs)

function analytic_mmc_metrics(lambda::Real, mu::Real, c::Integer)
    lambda_f = Float64(lambda)
    mu_f = Float64(mu)
    rho = lambda_f / (c * mu_f)
    if rho >= 1
        return (
            rho = rho,
            p0 = NaN,
            pwait = NaN,
            lq = Inf,
            wq = Inf,
            w = Inf,
            l = Inf,
        )
    end

    a = lambda_f / mu_f
    sum_terms = sum((a^n) / factorial(big(n)) for n in 0:(c - 1))
    tail_term = (a^c) / (factorial(big(c)) * (1 - rho))
    p0 = 1 / Float64(sum_terms + tail_term)
    pwait = Float64((a^c) / (factorial(big(c)) * (1 - rho))) * p0
    lq = pwait * rho / (1 - rho)
    wq = lq / lambda_f
    w = wq + 1 / mu_f
    l = lambda_f * w
    return (
        rho = rho,
        p0 = p0,
        pwait = pwait,
        lq = lq,
        wq = wq,
        w = w,
        l = l,
    )
end

function _mmc_time_weighted(events_internal::Vector{MMC_EVENT}, field::Symbol)
    accum = 0.0
    for idx in 1:(length(events_internal) - 1)
        dt = events_internal[idx + 1].time - events_internal[idx].time
        accum += dt * getfield(events_internal[idx], field)
    end
    horizon = events_internal[end].time
    return horizon > 0 ? accum / horizon : 0.0
end

function _mmc_time_weighted(events_internal::Vector{MMC_EVENT}, field::Symbol, t0::Real)
    start_time = Float64(t0)
    horizon = events_internal[end].time
    horizon <= start_time && return 0.0

    accum = 0.0
    current_value = getfield(events_internal[1], field)
    current_time = start_time

    for event in events_internal
        if event.time <= start_time
            current_value = getfield(event, field)
            continue
        end
        dt = event.time - current_time
        accum += dt * current_value
        current_time = event.time
        current_value = getfield(event, field)
    end

    return accum / (horizon - start_time)
end

function run_mmc_experiment(lambda::Real, mu::Real, c::Integer, num_customers::Integer, seed::Integer; warmup_customers::Integer = max(0, min(num_customers ÷ 10, num_customers - 1)))
    rng = StableRNG(seed)
    interarrival_dist = Exponential(1 / Float64(lambda))
    service_dist = Exponential(1 / Float64(mu))

    arrival_time = zeros(Float64, num_customers)
    service_start = zeros(Float64, num_customers)
    departure_time = zeros(Float64, num_customers)
    wait_time = zeros(Float64, num_customers)
    service_time = zeros(Float64, num_customers)
    system_time = zeros(Float64, num_customers)
    server_id = zeros(Int, num_customers)

    queue = Int[]
    server_busy = falses(c)
    server_departure = fill(Inf, c)
    server_customer = fill(0, c)
    busy_servers = 0

    next_arrival = rand(rng, interarrival_dist)
    next_customer_id = 1
    departed_customers = 0

    events_internal = MMC_EVENT[(time = 0.0, event = "init", customer_id = 0, queue_length = 0, busy_servers = 0, system_size = 0)]

    while departed_customers < num_customers
        next_departure = minimum(server_departure)
        departure_server = argmin(server_departure)

        process_arrival = next_customer_id <= num_customers && next_arrival < next_departure - 1e-12

        if process_arrival
            customer_id = next_customer_id
            next_customer_id += 1
            time = next_arrival
            arrival_time[customer_id] = time
            service_time[customer_id] = rand(rng, service_dist)

            if next_customer_id <= num_customers
                next_arrival += rand(rng, interarrival_dist)
            else
                next_arrival = Inf
            end

            if busy_servers < c
                sid = findfirst(!, server_busy)
                server_busy[sid] = true
                busy_servers += 1
                service_start[customer_id] = time
                wait_time[customer_id] = 0.0
                departure_time[customer_id] = time + service_time[customer_id]
                system_time[customer_id] = departure_time[customer_id] - arrival_time[customer_id]
                server_id[customer_id] = sid
                server_departure[sid] = departure_time[customer_id]
                server_customer[sid] = customer_id
                push!(events_internal, (
                    time = time,
                    event = "arrival",
                    customer_id = customer_id,
                    queue_length = length(queue),
                    busy_servers = busy_servers,
                    system_size = busy_servers + length(queue),
                ))
                push!(events_internal, (
                    time = time,
                    event = "service_start",
                    customer_id = customer_id,
                    queue_length = length(queue),
                    busy_servers = busy_servers,
                    system_size = busy_servers + length(queue),
                ))
            else
                push!(queue, customer_id)
                push!(events_internal, (
                    time = time,
                    event = "arrival",
                    customer_id = customer_id,
                    queue_length = length(queue),
                    busy_servers = busy_servers,
                    system_size = busy_servers + length(queue),
                ))
            end
        else
            time = next_departure
            customer_id = server_customer[departure_server]
            departed_customers += 1
            server_busy[departure_server] = false
            busy_servers -= 1
            server_departure[departure_server] = Inf
            server_customer[departure_server] = 0

            push!(events_internal, (
                time = time,
                event = "departure",
                customer_id = customer_id,
                queue_length = length(queue),
                busy_servers = busy_servers,
                system_size = busy_servers + length(queue),
            ))

            if !isempty(queue)
                waiting_customer = popfirst!(queue)
                server_busy[departure_server] = true
                busy_servers += 1
                service_start[waiting_customer] = time
                wait_time[waiting_customer] = time - arrival_time[waiting_customer]
                departure_time[waiting_customer] = time + service_time[waiting_customer]
                system_time[waiting_customer] = departure_time[waiting_customer] - arrival_time[waiting_customer]
                server_id[waiting_customer] = departure_server
                server_departure[departure_server] = departure_time[waiting_customer]
                server_customer[departure_server] = waiting_customer
                push!(events_internal, (
                    time = time,
                    event = "service_start",
                    customer_id = waiting_customer,
                    queue_length = length(queue),
                    busy_servers = busy_servers,
                    system_size = busy_servers + length(queue),
                ))
            end
        end
    end

    customers = DataFrame(
        id = 1:num_customers,
        arrival_time = arrival_time,
        service_start = service_start,
        departure_time = departure_time,
        wait_time = wait_time,
        service_time = service_time,
        system_time = system_time,
        server_id = server_id,
    )

    events = DataFrame(events_internal[2:end])
    analytic = analytic_mmc_metrics(lambda, mu, c)
    warmup_index = min(max(warmup_customers, 0), num_customers - 1)
    sample = customers[(warmup_index + 1):end, :]
    start_time = arrival_time[warmup_index + 1]
    sim_lq = _mmc_time_weighted(events_internal, :queue_length, start_time)
    sim_l = _mmc_time_weighted(events_internal, :system_size, start_time)
    sim_utilization = _mmc_time_weighted(events_internal, :busy_servers, start_time) / c

    summary = DataFrame([(
        lambda = Float64(lambda),
        mu = Float64(mu),
        c = Int(c),
        num_customers = Int(num_customers),
        seed = Int(seed),
        warmup_customers = warmup_index,
        rho = analytic.rho,
        analytic_wq = analytic.wq,
        sim_wq = mean(sample.wait_time),
        analytic_w = analytic.w,
        sim_w = mean(sample.system_time),
        analytic_lq = analytic.lq,
        sim_lq = sim_lq,
        analytic_l = analytic.l,
        sim_l = sim_l,
        analytic_pwait = analytic.pwait,
        sim_pwait = mean(sample.wait_time .> 0),
        sim_utilization = sim_utilization,
    )])

    return customers, events, summary
end

function run_mmc_parameter_scan(lambdas::AbstractVector{<:Real}, channels::AbstractVector{<:Integer}, mu::Real, num_customers::Integer, seed::Integer)
    rows = NamedTuple[]
    scenario = 0
    for lambda in lambdas
        for c in channels
            scenario += 1
            customers, _, summary = run_mmc_experiment(lambda, mu, c, num_customers, seed + scenario)
            analytic = analytic_mmc_metrics(lambda, mu, c)
            push!(rows, (
                lambda = Float64(lambda),
                mu = Float64(mu),
                c = Int(c),
                warmup_customers = summary.warmup_customers[1],
                rho = analytic.rho,
                analytic_wq = analytic.wq,
                sim_wq = summary.sim_wq[1],
                analytic_w = analytic.w,
                sim_w = summary.sim_w[1],
                sim_utilization = summary.sim_utilization[1],
                sim_pwait = mean(customers.wait_time .> 0),
            ))
        end
    end
    return DataFrame(rows)
end

function _prepare_series(df::DataFrame, y::Symbol)
    return df.time, Float64.(df[!, y])
end

function plot_mmc_queue_length(events::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Queue length", title = "M/M/c queue length over time")
    times, values = _prepare_series(events, :queue_length)
    stairs!(ax, times, values; color = :steelblue4, linewidth = 2)
    return fig
end

function plot_mmc_busy_servers(events::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Busy servers", title = "M/M/c busy servers over time")
    times, values = _prepare_series(events, :busy_servers)
    stairs!(ax, times, values; color = :darkorange3, linewidth = 2)
    return fig
end

function plot_mmc_wait_histogram(customers::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Waiting time", ylabel = "Count", title = "M/M/c waiting time histogram")
    hist!(ax, customers.wait_time; bins = 40, color = (:seagreen4, 0.82), strokecolor = :white)
    return fig
end

function plot_mmc_analytic_vs_simulation(summary::DataFrame)
    fig = Figure(size = (1000, 620))
    ax = Axis(fig[1, 1]; xlabel = "Metric", ylabel = "Value", title = "M/M/c analytic vs simulation")
    metrics = ["Wq", "W", "Lq", "L", "Pwait"]
    analytic = [
        summary.analytic_wq[1],
        summary.analytic_w[1],
        summary.analytic_lq[1],
        summary.analytic_l[1],
        summary.analytic_pwait[1],
    ]
    simulation = [
        summary.sim_wq[1],
        summary.sim_w[1],
        summary.sim_lq[1],
        summary.sim_l[1],
        summary.sim_pwait[1],
    ]
    xs = collect(1:length(metrics))
    barplot!(ax, xs .- 0.18, analytic; width = 0.34, color = :slateblue3, label = "Analytic")
    barplot!(ax, xs .+ 0.18, simulation; width = 0.34, color = :firebrick2, label = "Simulation")
    ax.xticks = (xs, metrics)
    axislegend(ax; position = :rt)
    return fig
end

function plot_mmc_wait_by_channels(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Channels", ylabel = "Mean waiting time", title = "M/M/c waiting time by channels")
    palette = [:royalblue3, :darkorange3, :seagreen4, :firebrick2]
    for (idx, lambda) in enumerate(sort(unique(scan.lambda)))
        sub = sort(scan[scan.lambda .== lambda, :], :c)
        lines!(ax, sub.c, sub.sim_wq; color = palette[idx], linewidth = 2.5, label = "sim λ=$(lambda)")
        scatter!(ax, sub.c, sub.sim_wq; color = palette[idx], markersize = 11)
        stable = sub[isfinite.(sub.analytic_wq), :]
        if size(stable, 1) > 0
            lines!(ax, stable.c, stable.analytic_wq; color = palette[idx], linestyle = :dash, linewidth = 1.8, label = "analytic λ=$(lambda)")
        end
    end
    axislegend(ax; position = :rt)
    return fig
end

function plot_mmc_wait_by_lambda(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Lambda", ylabel = "Mean waiting time", title = "M/M/c waiting time by arrival rate")
    palette = [:royalblue3, :darkorange3, :seagreen4, :firebrick2, :purple4, :goldenrod4]
    for (idx, c) in enumerate(sort(unique(scan.c)))
        sub = sort(scan[scan.c .== c, :], :lambda)
        lines!(ax, sub.lambda, sub.sim_wq; color = palette[idx], linewidth = 2.5, label = "c=$(c)")
        scatter!(ax, sub.lambda, sub.sim_wq; color = palette[idx], markersize = 10)
    end
    axislegend(ax; position = :rt)
    return fig
end

function plot_mmc_utilization_heatmap(scan::DataFrame)
    lambdas = sort(unique(scan.lambda))
    channels = sort(unique(scan.c))
    matrix = [scan[(scan.lambda .== lambda) .& (scan.c .== c), :sim_utilization][1] for lambda in lambdas, c in channels]
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Channels", ylabel = "Lambda", title = "M/M/c server utilization heatmap")
    hm = heatmap!(ax, channels, lambdas, matrix; colormap = :viridis)
    Colorbar(fig[1, 2], hm, label = "Utilization")
    return fig
end

function analytic_ross_crash_time(N::Integer, S::Integer, repairers::Integer, mean_time_to_failure::Real, mean_repair_time::Real)
    failure_rate = N / Float64(mean_time_to_failure)
    nstates = S + 1
    A = zeros(Float64, nstates, nstates)
    b = ones(Float64, nstates)

    for k in 0:S
        row = k + 1
        repair_rate = min(repairers, S - k) / Float64(mean_repair_time)
        A[row, row] = failure_rate + repair_rate
        if k > 0
            A[row, row - 1] = -failure_rate
        end
        if k < S
            A[row, row + 1] = -repair_rate
        end
    end

    expected = A \ b
    return expected[end]
end

function _ross_time_weighted(events_internal::Vector{ROSS_EVENT}, field::Symbol)
    accum = 0.0
    for idx in 1:(length(events_internal) - 1)
        dt = events_internal[idx + 1].time - events_internal[idx].time
        accum += dt * getfield(events_internal[idx], field)
    end
    horizon = events_internal[end].time
    return horizon > 0 ? accum / horizon : 0.0
end

function _ross_once(N::Integer, S::Integer, repairers::Integer, mean_time_to_failure::Real, mean_repair_time::Real, seed::Integer)
    rng = StableRNG(seed)
    working = N
    spares = S
    broken = 0
    busy_repairers = 0
    repair_queue = 0
    time = 0.0
    active_repairs = Float64[]

    events_internal = ROSS_EVENT[(time = 0.0, event = "init", working = working, spares = spares, broken = broken, repair_queue = repair_queue, busy_repairers = busy_repairers, good_machines = working + spares)]

    while true
        failure_dist = Exponential(mean_time_to_failure / working)
        next_failure = time + rand(rng, failure_dist)
        next_repair = isempty(active_repairs) ? Inf : minimum(active_repairs)

        if next_failure < next_repair - 1e-12
            time = next_failure
            if spares > 0
                spares -= 1
                broken += 1
                if busy_repairers < repairers
                    busy_repairers += 1
                    push!(active_repairs, time + rand(rng, Exponential(mean_repair_time)))
                else
                    repair_queue += 1
                end
                push!(events_internal, (
                    time = time,
                    event = "failure",
                    working = working,
                    spares = spares,
                    broken = broken,
                    repair_queue = repair_queue,
                    busy_repairers = busy_repairers,
                    good_machines = working + spares,
                ))
            else
                working -= 1
                broken += 1
                push!(events_internal, (
                    time = time,
                    event = "crash",
                    working = working,
                    spares = spares,
                    broken = broken,
                    repair_queue = repair_queue,
                    busy_repairers = busy_repairers,
                    good_machines = working + spares,
                ))
                break
            end
        else
            repair_idx = argmin(active_repairs)
            time = active_repairs[repair_idx]
            broken -= 1
            spares += 1
            if repair_queue > 0
                repair_queue -= 1
                active_repairs[repair_idx] = time + rand(rng, Exponential(mean_repair_time))
            else
                deleteat!(active_repairs, repair_idx)
                busy_repairers -= 1
            end
            push!(events_internal, (
                time = time,
                event = "repair_complete",
                working = working,
                spares = spares,
                broken = broken,
                repair_queue = repair_queue,
                busy_repairers = busy_repairers,
                good_machines = working + spares,
            ))
        end
    end

    events = DataFrame(events_internal[2:end])
    mean_queue = _ross_time_weighted(events_internal, :repair_queue)
    repairer_utilization = repairers > 0 ? _ross_time_weighted(events_internal, :busy_repairers) / repairers : 0.0
    return (
        events = events,
        crash_time = events_internal[end].time,
        mean_repair_queue = mean_queue,
        repairer_utilization = repairer_utilization,
    )
end

function run_ross_experiment(N::Integer, S::Integer, repairers::Integer, mean_time_to_failure::Real, mean_repair_time::Real, runs::Integer, seed::Integer)
    sample = _ross_once(N, S, repairers, mean_time_to_failure, mean_repair_time, seed)
    run_rows = NamedTuple[]
    crash_times = Float64[]
    queues = Float64[]
    utilizations = Float64[]

    for run_id in 1:runs
        result = _ross_once(N, S, repairers, mean_time_to_failure, mean_repair_time, seed + run_id)
        push!(crash_times, result.crash_time)
        push!(queues, result.mean_repair_queue)
        push!(utilizations, result.repairer_utilization)
        push!(run_rows, (
            run_id = run_id,
            crash_time = result.crash_time,
            mean_repair_queue = result.mean_repair_queue,
            repairer_utilization = result.repairer_utilization,
        ))
    end

    runs_df = DataFrame(run_rows)
    summary_df = DataFrame([(
        N = N,
        S = S,
        repairers = repairers,
        runs = runs,
        mean_crash_time = safe_mean(crash_times),
        std_crash_time = safe_std(crash_times),
        analytic_crash_time = analytic_ross_crash_time(N, S, repairers, mean_time_to_failure, mean_repair_time),
        mean_repair_queue = safe_mean(queues),
        repairer_utilization = safe_mean(utilizations),
    )])

    return sample.events, runs_df, summary_df
end

function run_ross_parameter_scan(N_values::AbstractVector{<:Integer}, S_values::AbstractVector{<:Integer}, repairer_values::AbstractVector{<:Integer}, mean_time_to_failure::Real, mean_repair_time::Real, runs::Integer, seed::Integer)
    rows = NamedTuple[]
    scenario = 0
    for N in N_values
        for S in S_values
            for repairers in repairer_values
                scenario += 1
                _, runs_df, summary_df = run_ross_experiment(N, S, repairers, mean_time_to_failure, mean_repair_time, runs, seed + 100 * scenario)
                push!(rows, (
                    N = N,
                    S = S,
                    repairers = repairers,
                    runs = runs,
                    mean_crash_time = summary_df.mean_crash_time[1],
                    std_crash_time = summary_df.std_crash_time[1],
                    analytic_crash_time = summary_df.analytic_crash_time[1],
                    mean_repair_queue = summary_df.mean_repair_queue[1],
                    repairer_utilization = summary_df.repairer_utilization[1],
                ))
            end
        end
    end
    return DataFrame(rows)
end

function plot_ross_good_machines(events::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Good machines", title = "Ross model: good machines over time")
    stairs!(ax, events.time, Float64.(events.good_machines); color = :royalblue3, linewidth = 2)
    return fig
end

function plot_ross_spares(events::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Spare machines", title = "Ross model: spare machines over time")
    stairs!(ax, events.time, Float64.(events.spares); color = :seagreen4, linewidth = 2)
    return fig
end

function plot_ross_repair_queue(events::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Repair queue", title = "Ross model: repair queue over time")
    stairs!(ax, events.time, Float64.(events.repair_queue); color = :darkorange3, linewidth = 2)
    return fig
end

function plot_ross_crash_histogram(runs_df::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Crash time", ylabel = "Count", title = "Ross model: crash time histogram")
    hist!(ax, runs_df.crash_time; bins = 32, color = (:firebrick2, 0.82), strokecolor = :white)
    return fig
end

function plot_ross_simulation_vs_analytic(summary_df::DataFrame)
    fig = Figure(size = (900, 560))
    ax = Axis(fig[1, 1]; xlabel = "Metric", ylabel = "Time", title = "Ross model: simulation vs analytic")
    labels = ["Simulation", "Analytic"]
    values = [summary_df.mean_crash_time[1], summary_df.analytic_crash_time[1]]
    barplot!(ax, 1:2, values; color = [:steelblue4, :firebrick2], width = 0.6)
    ax.xticks = (1:2, labels)
    return fig
end

function plot_ross_repairer_utilization(summary_df::DataFrame)
    fig = Figure(size = (900, 560))
    ax = Axis(fig[1, 1]; xlabel = "Scenario", ylabel = "Utilization", title = "Ross model: repairer utilization")
    barplot!(ax, [1], [summary_df.repairer_utilization[1]]; color = :purple4, width = 0.55)
    ax.xticks = ([1], ["baseline"])
    ylims!(ax, 0, 1)
    return fig
end

function plot_ross_crash_time_by_n(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "N", ylabel = "Mean crash time", title = "Ross model: crash time by N")
    palette = [:royalblue3, :darkorange3, :seagreen4, :firebrick2]
    scenarios = unique([(row.S, row.repairers) for row in eachrow(scan)])
    for (idx, (S, repairers)) in enumerate(scenarios)
        sub = sort(scan[(scan.S .== S) .& (scan.repairers .== repairers), :], :N)
        lines!(ax, sub.N, sub.mean_crash_time; color = palette[idx], linewidth = 2.5, label = "S=$(S), r=$(repairers)")
        scatter!(ax, sub.N, sub.mean_crash_time; color = palette[idx], markersize = 10)
    end
    axislegend(ax; position = :rt)
    return fig
end

function plot_ross_crash_time_by_spares(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "S", ylabel = "Mean crash time", title = "Ross model: crash time by spares")
    palette = [:royalblue3, :darkorange3, :seagreen4, :firebrick2, :purple4, :goldenrod4]
    scenarios = unique([(row.N, row.repairers) for row in eachrow(scan)])
    for (idx, (N, repairers)) in enumerate(scenarios)
        sub = sort(scan[(scan.N .== N) .& (scan.repairers .== repairers), :], :S)
        lines!(ax, sub.S, sub.mean_crash_time; color = palette[idx], linewidth = 2.5, label = "N=$(N), r=$(repairers)")
        scatter!(ax, sub.S, sub.mean_crash_time; color = palette[idx], markersize = 10)
    end
    axislegend(ax; position = :rt)
    return fig
end

function plot_ross_repairers_comparison(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Repairers", ylabel = "Mean crash time", title = "Ross model: repairers comparison")
    palette = [:royalblue3, :darkorange3, :seagreen4, :firebrick2, :purple4, :goldenrod4]
    scenarios = unique([(row.N, row.S) for row in eachrow(scan)])
    for (idx, (N, S)) in enumerate(scenarios)
        sub = sort(scan[(scan.N .== N) .& (scan.S .== S), :], :repairers)
        lines!(ax, sub.repairers, sub.mean_crash_time; color = palette[idx], linewidth = 2.5, label = "N=$(N), S=$(S)")
        scatter!(ax, sub.repairers, sub.mean_crash_time; color = palette[idx], markersize = 10)
    end
    axislegend(ax; position = :rt)
    return fig
end

function plot_ross_repairer_utilization_by_scenario(scan::DataFrame)
    labels = ["N=$(row.N), S=$(row.S), r=$(row.repairers)" for row in eachrow(scan)]
    values = Float64.(scan.repairer_utilization)
    fig = Figure(size = (1200, 560))
    ax = Axis(fig[1, 1]; xlabel = "Scenario", ylabel = "Utilization", title = "Ross model: repairer utilization by scenario")
    barplot!(ax, 1:length(labels), values; color = :teal, width = 0.72)
    ax.xticks = (1:length(labels), labels)
    ax.xticklabelrotation = pi / 6
    ylims!(ax, 0, 1)
    return fig
end

end
