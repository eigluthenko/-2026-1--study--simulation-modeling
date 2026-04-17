using DrWatson
@quickactivate "project"

include(srcdir("DiningPhilosophers.jl"))

using .DiningPhilosophers
using CSV
using DataFrames
using Statistics

function add_result!(results, network, N, tmax, seed, net, df)
    summary = summarize_final_state(df, N)
    push!(
        results,
        (
            network = network,
            N = N,
            tmax = tmax,
            seed = seed,
            deadlock = detect_deadlock(df, net),
            events = summary.events,
            final_hungry = summary.final_hungry,
            final_eat = summary.final_eat,
        ),
    )
end

function main()
    mkpath(datadir())
    mkpath(plotsdir())

    n_values = [3, 5, 7]
    tmax_values = [30.0, 50.0, 80.0]
    seeds = [123, 124, 125]

    results = DataFrame(
        network = String[],
        N = Int[],
        tmax = Float64[],
        seed = Int[],
        deadlock = Bool[],
        events = Int[],
        final_hungry = Float64[],
        final_eat = Float64[],
    )

    for N in n_values, tmax in tmax_values, seed in seeds
        net_classic, u0_classic, _ = build_classical_network(N)
        df_classic = simulate_stochastic(net_classic, u0_classic, tmax; seed = seed)
        add_result!(results, "classic", N, tmax, seed, net_classic, df_classic)

        net_arbiter, u0_arbiter, _ = build_arbiter_network(N)
        df_arbiter = simulate_stochastic(net_arbiter, u0_arbiter, tmax; seed = seed)
        add_result!(results, "arbiter", N, tmax, seed, net_arbiter, df_arbiter)
    end

    CSV.write(datadir("dining_params.csv"), results)
    plot_deadlock_rates(results, plotsdir("dining_params.png"))

    println("Parameter study saved:")
    println("  $(datadir("dining_params.csv"))")
    println("  $(plotsdir("dining_params.png"))")
    println()
    println(combine(groupby(results, :network), :deadlock => mean => :deadlock_rate))
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
