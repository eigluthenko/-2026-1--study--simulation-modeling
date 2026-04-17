module DiningPhilosophers

using CairoMakie
using DataFrames
using Random
using Statistics

export PetriNet
export build_classical_network, build_arbiter_network
export simulate_stochastic, simulate_ode, detect_deadlock
export plot_marking_evolution, plot_eat_comparison, plot_deadlock_rates
export save_marking_animation, summarize_final_state

struct PetriNet
    n_places::Int
    n_transitions::Int
    incidence::Matrix{Int}
    place_names::Vector{Symbol}
    transition_names::Vector{Symbol}
end

function PetriNet(n_places::Int, n_transitions::Int)
    place_names = [Symbol("p$i") for i in 1:n_places]
    transition_names = [Symbol("t$j") for j in 1:n_transitions]
    incidence = zeros(Int, n_places, n_transitions)
    return PetriNet(n_places, n_transitions, incidence, place_names, transition_names)
end

function add_arc!(net::PetriNet, place::Int, transition::Int, sign::Int)
    net.incidence[place, transition] += sign
    return net
end

function build_classical_network(N::Int)
    n_places = 4N
    n_transitions = 3N
    net = PetriNet(n_places, n_transitions)

    for i in 1:N
        net.place_names[i] = Symbol("Think_$i")
        net.place_names[N + i] = Symbol("Hungry_$i")
        net.place_names[2N + i] = Symbol("Eat_$i")
        net.place_names[3N + i] = Symbol("Fork_$i")

        net.transition_names[i] = Symbol("GetLeft_$i")
        net.transition_names[N + i] = Symbol("GetRight_$i")
        net.transition_names[2N + i] = Symbol("PutForks_$i")
    end

    for i in 1:N
        think = i
        hungry = N + i
        eat = 2N + i
        left_fork = 3N + i
        right_fork = 3N + (i % N + 1)

        get_left = i
        get_right = N + i
        put_forks = 2N + i

        add_arc!(net, think, get_left, -1)
        add_arc!(net, left_fork, get_left, -1)
        add_arc!(net, hungry, get_left, +1)

        add_arc!(net, hungry, get_right, -1)
        add_arc!(net, right_fork, get_right, -1)
        add_arc!(net, eat, get_right, +1)

        add_arc!(net, eat, put_forks, -1)
        add_arc!(net, think, put_forks, +1)
        add_arc!(net, left_fork, put_forks, +1)
        add_arc!(net, right_fork, put_forks, +1)
    end

    u0 = zeros(Float64, n_places)
    for i in 1:N
        u0[i] = 1.0
        u0[3N + i] = 1.0
    end
    return net, u0, net.place_names
end

function build_arbiter_network(N::Int)
    n_places = 4N + 1
    n_transitions = 3N
    net = PetriNet(n_places, n_transitions)

    for i in 1:N
        net.place_names[i] = Symbol("Think_$i")
        net.place_names[N + i] = Symbol("Hungry_$i")
        net.place_names[2N + i] = Symbol("Eat_$i")
        net.place_names[3N + i] = Symbol("Fork_$i")

        net.transition_names[i] = Symbol("GetLeft_$i")
        net.transition_names[N + i] = Symbol("GetRight_$i")
        net.transition_names[2N + i] = Symbol("PutForks_$i")
    end
    net.place_names[4N + 1] = :Arbiter

    arbiter = 4N + 1
    for i in 1:N
        think = i
        hungry = N + i
        eat = 2N + i
        left_fork = 3N + i
        right_fork = 3N + (i % N + 1)

        get_left = i
        get_right = N + i
        put_forks = 2N + i

        add_arc!(net, think, get_left, -1)
        add_arc!(net, left_fork, get_left, -1)
        add_arc!(net, arbiter, get_left, -1)
        add_arc!(net, hungry, get_left, +1)

        add_arc!(net, hungry, get_right, -1)
        add_arc!(net, right_fork, get_right, -1)
        add_arc!(net, eat, get_right, +1)

        add_arc!(net, eat, put_forks, -1)
        add_arc!(net, think, put_forks, +1)
        add_arc!(net, left_fork, put_forks, +1)
        add_arc!(net, right_fork, put_forks, +1)
        add_arc!(net, arbiter, put_forks, +1)
    end

    u0 = zeros(Float64, n_places)
    for i in 1:N
        u0[i] = 1.0
        u0[3N + i] = 1.0
    end
    u0[arbiter] = N - 1
    return net, u0, net.place_names
end

function transition_propensities(net::PetriNet, u::AbstractVector{<:Real}, rates)
    a = zeros(Float64, net.n_transitions)
    for j in 1:net.n_transitions
        value = Float64(rates[j])
        for i in 1:net.n_places
            required = -net.incidence[i, j]
            if required > 0
                value *= max(Float64(u[i]), 0.0)^required
            end
        end
        a[j] = value
    end
    return a
end

function states_dataframe(times, states, names::Vector{Symbol})
    df = DataFrame(time = times)
    for i in eachindex(names)
        df[!, String(names[i])] = [state[i] for state in states]
    end
    return df
end

function simulate_stochastic(
    net::PetriNet,
    u0::Vector{Float64},
    tmax::Float64;
    rates = ones(Float64, net.n_transitions),
    seed::Union{Nothing, Int} = nothing,
)
    rng = seed === nothing ? Random.default_rng() : MersenneTwister(seed)
    u = copy(u0)
    t = 0.0
    times = [t]
    states = [copy(u)]

    while t < tmax
        a = transition_propensities(net, u, rates)
        a0 = sum(a)
        if a0 <= 0
            break
        end

        dt = -log(rand(rng)) / a0
        if t + dt > tmax
            push!(times, tmax)
            push!(states, copy(u))
            break
        end

        r = rand(rng) * a0
        chosen = searchsortedfirst(cumsum(a), r)
        u .+= net.incidence[:, chosen]
        t += dt

        push!(times, t)
        push!(states, copy(u))
    end

    return states_dataframe(times, states, net.place_names)
end

function simulate_ode(
    net::PetriNet,
    u0::Vector{Float64},
    tmax::Float64;
    dt::Float64 = 0.05,
    rates = ones(Float64, net.n_transitions),
)
    u = copy(u0)
    times = collect(0.0:dt:tmax)
    states = Vector{Vector{Float64}}()
    for _ in times
        push!(states, copy(u))
        a = transition_propensities(net, u, rates)
        du = net.incidence * a
        u .= max.(u .+ dt .* du, 0.0)
    end
    return states_dataframe(times, states, net.place_names)
end

function final_vector(df::DataFrame, net::PetriNet)
    return [Float64(df[end, String(net.place_names[i])]) for i in 1:net.n_places]
end

function detect_deadlock(df::DataFrame, net::PetriNet; tol = 1e-9)
    u = final_vector(df, net)
    for j in 1:net.n_transitions
        enabled = true
        for i in 1:net.n_places
            required = -net.incidence[i, j]
            if required > 0 && u[i] < required - tol
                enabled = false
                break
            end
        end
        enabled && return false
    end
    return true
end

function summarize_final_state(df::DataFrame, N::Int)
    hungry_cols = [Symbol("Hungry_$i") for i in 1:N]
    eat_cols = [Symbol("Eat_$i") for i in 1:N]
    return (
        final_time = Float64(df.time[end]),
        events = nrow(df) - 1,
        final_hungry = sum(Float64(df[end, col]) for col in hungry_cols),
        final_eat = sum(Float64(df[end, col]) for col in eat_cols),
    )
end

function plot_marking_evolution(df::DataFrame, N::Int, path::AbstractString; title = "")
    CairoMakie.activate!()
    fig = Figure(size = (900, 1000), fontsize = 14)
    groups = ["Think", "Hungry", "Eat", "Fork"]
    colors = Makie.wong_colors()

    for (row, group) in enumerate(groups)
        ax = Axis(
            fig[row, 1],
            xlabel = row == length(groups) ? "time" : "",
            ylabel = "tokens",
            title = isempty(title) ? "$group states" : "$title: $group states",
        )
        for i in 1:N
            col = Symbol("$(group)_$i")
            if String(col) in names(df)
                lines!(ax, df.time, df[!, col], label = "P$i", color = colors[i])
            end
        end
        axislegend(ax, position = :rt, orientation = :horizontal, nbanks = 1)
    end

    save(path, fig)
    return fig
end

function plot_eat_comparison(
    df_classic::DataFrame,
    df_arbiter::DataFrame,
    N::Int,
    path::AbstractString,
)
    CairoMakie.activate!()
    fig = Figure(size = (900, 650), fontsize = 14)
    colors = Makie.wong_colors()
    datasets = [
        ("Classical network", df_classic),
        ("Network with arbiter", df_arbiter),
    ]

    for (row, (title, df)) in enumerate(datasets)
        ax = Axis(fig[row, 1], xlabel = "time", ylabel = "Eat_i", title = title)
        for i in 1:N
            col = Symbol("Eat_$i")
            lines!(ax, df.time, df[!, col], label = "P$i", color = colors[i])
        end
        axislegend(ax, position = :rt, orientation = :horizontal, nbanks = 1)
    end

    save(path, fig)
    return fig
end

function plot_deadlock_rates(results::DataFrame, path::AbstractString)
    CairoMakie.activate!()
    summary = combine(groupby(results, [:network, :N]), :deadlock => mean => :deadlock_rate)
    fig = Figure(size = (760, 480), fontsize = 14)
    ax = Axis(fig[1, 1], xlabel = "N", ylabel = "deadlock rate", title = "Deadlock frequency")

    networks = sort(unique(summary.network))
    colors = Makie.wong_colors()
    for (idx, network) in enumerate(networks)
        part = sort(summary[summary.network .== network, :], :N)
        lines!(ax, part.N, part.deadlock_rate, label = network, color = colors[idx], linewidth = 3)
        scatter!(ax, part.N, part.deadlock_rate, color = colors[idx], markersize = 12)
    end
    ylims!(ax, -0.05, 1.05)
    axislegend(ax, position = :rc)
    save(path, fig)
    return fig
end

function save_marking_animation(
    df::DataFrame,
    place_names::Vector{Symbol},
    path::AbstractString;
    fps::Int = 2,
)
    CairoMakie.activate!()
    state_cols = names(df)[2:end]
    x = 1:length(state_cols)
    first_state = Float64.(Vector(df[1, state_cols]))
    ymax = max(1.0, maximum([maximum(Float64.(Vector(df[row, state_cols]))) for row in 1:nrow(df)])) + 1

    values = Observable(first_state)
    current_time = Observable(Float64(df.time[1]))

    fig = Figure(size = (950, 520), fontsize = 13)
    Label(fig[1, 1], lift(t -> "Petri net marking, time = $(round(t, digits = 2))", current_time))
    ax = Axis(
        fig[2, 1],
        xlabel = "place",
        ylabel = "tokens",
        xticks = (x, string.(place_names)),
        xticklabelrotation = pi / 4,
    )
    ylims!(ax, 0, ymax)
    barplot!(ax, x, values, color = :steelblue)

    record(fig, path, 1:nrow(df); framerate = fps) do row
        values[] = Float64.(Vector(df[row, state_cols]))
        current_time[] = Float64(df.time[row])
    end
    return path
end

end
