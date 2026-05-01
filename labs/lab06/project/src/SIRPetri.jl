module SIRPetri

using CairoMakie
using DataFrames
using Random

export PetriNet,
    build_sir_network,
    sir_ode,
    simulate_deterministic,
    simulate_stochastic,
    plot_sir,
    plot_scan,
    plot_comparison,
    plot_sensitivity,
    make_animation,
    to_graphviz_sir

struct PetriNet
    places::Vector{Symbol}
    transitions::Vector{Symbol}
    pre::Matrix{Int}
    post::Matrix{Int}
    rates::Vector{Float64}
end

function build_sir_network(beta::Real = 0.3, gamma::Real = 0.1)
    places = [:S, :I, :R]
    transitions = [:infection, :recovery]
    pre = [
        1 0
        1 1
        0 0
    ]
    post = [
        0 0
        2 0
        0 1
    ]
    net = PetriNet(places, transitions, pre, post, Float64[beta, gamma])
    u0 = Float64[990, 10, 0]
    return net, u0, places
end

function sir_ode(net::PetriNet, rates::AbstractVector{<:Real} = net.rates)
    beta, gamma = Float64.(rates)
    function f(u)
        s, i, r = u
        infection_rate = beta * s * i
        recovery_rate = gamma * i
        return Float64[-infection_rate, infection_rate - recovery_rate, recovery_rate]
    end
    return f
end

function rk4_step(f, u::Vector{Float64}, dt::Float64)
    k1 = f(u)
    k2 = f(u .+ 0.5dt .* k1)
    k3 = f(u .+ 0.5dt .* k2)
    k4 = f(u .+ dt .* k3)
    next_u = u .+ (dt / 6.0) .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4)
    return max.(next_u, 0.0)
end

function simulate_deterministic(
    net::PetriNet,
    u0::AbstractVector{<:Real},
    tspan::Tuple{<:Real,<:Real};
    saveat::Real = 0.5,
    rates::AbstractVector{<:Real} = net.rates,
    dt_internal::Real = 0.001,
)
    f = sir_ode(net, rates)
    t0, tmax = Float64.(tspan)
    times = collect(t0:Float64(saveat):tmax)
    rows = Vector{NamedTuple{(:time, :S, :I, :R),Tuple{Float64,Float64,Float64,Float64}}}()
    u = Float64.(u0)
    t = t0

    for target in times
        while t + 1e-12 < target
            h = min(Float64(dt_internal), target - t)
            u = rk4_step(f, u, h)
            t += h
        end
        push!(rows, (time = target, S = u[1], I = u[2], R = u[3]))
    end
    return DataFrame(rows)
end

function simulate_stochastic(
    net::PetriNet,
    u0::AbstractVector{<:Real},
    tspan::Tuple{<:Real,<:Real};
    rates::AbstractVector{<:Real} = net.rates,
    rng::AbstractRNG = Random.GLOBAL_RNG,
)
    beta, gamma = Float64.(rates)
    u = Int.(round.(u0))
    t = Float64(tspan[1])
    tmax = Float64(tspan[2])
    rows = [(time = t, S = u[1], I = u[2], R = u[3])]

    while t < tmax
        s, i, r = u
        a_inf = beta * s * i
        a_rec = gamma * i
        a0 = a_inf + a_rec
        a0 <= 0 && break

        t += -log(rand(rng)) / a0
        t <= tmax || break

        if rand(rng) * a0 < a_inf && u[1] > 0
            u[1] -= 1
            u[2] += 1
        elseif u[2] > 0
            u[2] -= 1
            u[3] += 1
        end
        push!(rows, (time = t, S = u[1], I = u[2], R = u[3]))
    end

    return DataFrame(rows)
end

function plot_sir(df::DataFrame; title = "SIR dynamics")
    fig = Figure(size = (980, 560))
    ax = Axis(fig[1, 1]; title, xlabel = "Time", ylabel = "Population")
    lines!(ax, df.time, df.S; color = :royalblue3, linewidth = 2, label = "S")
    lines!(ax, df.time, df.I; color = :firebrick2, linewidth = 2, label = "I")
    lines!(ax, df.time, df.R; color = :seagreen4, linewidth = 2, label = "R")
    axislegend(ax; position = :rt)
    return fig
end

function plot_scan(df::DataFrame)
    fig = Figure(size = (980, 560))
    ax = Axis(fig[1, 1]; xlabel = "beta", ylabel = "Population", title = "Sensitivity to infection rate")
    lines!(ax, df.beta, df.peak_I; color = :firebrick2, linewidth = 2, label = "Peak I")
    scatter!(ax, df.beta, df.peak_I; color = :firebrick2, markersize = 9)
    lines!(ax, df.beta, df.final_R; color = :seagreen4, linewidth = 2, label = "Final R")
    scatter!(ax, df.beta, df.final_R; color = :seagreen4, markersize = 9)
    axislegend(ax; position = :rb)
    return fig
end

function plot_comparison(df_det::DataFrame, df_stoch::DataFrame)
    fig = Figure(size = (980, 560))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Infected", title = "Deterministic and stochastic infected trajectories")
    lines!(ax, df_det.time, df_det.I; color = :firebrick2, linewidth = 2, label = "Deterministic I")
    lines!(ax, df_stoch.time, df_stoch.I; color = :gray25, linewidth = 1.7, label = "Stochastic I")
    axislegend(ax; position = :rt)
    return fig
end

function plot_sensitivity(df_scan::DataFrame)
    fig = Figure(size = (980, 560))
    ax = Axis(fig[1, 1]; xlabel = "beta", ylabel = "Peak I", title = "Peak infected by beta")
    lines!(ax, df_scan.beta, df_scan.peak_I; color = :purple4, linewidth = 2)
    scatter!(ax, df_scan.beta, df_scan.peak_I; color = :purple4, markersize = 9)
    return fig
end

function make_animation(df::DataFrame, outfile::AbstractString; fps::Int = 10)
    fig = Figure(size = (720, 520))
    ax = Axis(fig[1, 1]; xlabel = "State", ylabel = "Population", title = "SIR Petri net marking")
    ylims!(ax, 0, 1000)
    labels = ["S", "I", "R"]
    values = Observable([df.S[1], df.I[1], df.R[1]])
    barplot!(ax, 1:3, values; color = [:royalblue3, :firebrick2, :seagreen4])
    ax.xticks = (1:3, labels)

    record(fig, outfile, 1:nrow(df); framerate = fps) do idx
        values[] = [df.S[idx], df.I[idx], df.R[idx]]
        ax.title = "SIR Petri net marking, t=$(round(df.time[idx], digits = 1))"
    end
    return outfile
end

function to_graphviz_sir(net::PetriNet)
    lines = String["digraph SIR {", "rankdir=LR;", "node [fontname=\"DejaVu Sans\"];"]
    for p in net.places
        push!(lines, "\"$p\" [shape=circle];")
    end
    for t in net.transitions
        push!(lines, "\"$t\" [shape=box];")
    end
    for (j, t) in enumerate(net.transitions)
        for (i, p) in enumerate(net.places)
            net.pre[i, j] > 0 && push!(lines, "\"$p\" -> \"$t\" [label=\"$(net.pre[i, j])\"];")
            net.post[i, j] > 0 && push!(lines, "\"$t\" -> \"$p\" [label=\"$(net.post[i, j])\"];")
        end
    end
    push!(lines, "}")
    return join(lines, "\n")
end

end
