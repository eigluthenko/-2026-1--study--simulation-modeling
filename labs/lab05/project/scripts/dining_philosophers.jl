# # Basic experiment
#
# This script compares two Petri-net models for the dining philosophers task:
# a classical model without synchronization and a modified model with an arbiter.

using DrWatson
@quickactivate "project"

include(srcdir("DiningPhilosophers.jl"))

using .DiningPhilosophers
using CSV

function run_network(label, builder, N, tmax, seed)
    net, u0, _ = builder(N)
    df = simulate_stochastic(net, u0, tmax; seed = seed)
    dead = detect_deadlock(df, net)
    summary = summarize_final_state(df, N)

    println("[$label]")
    println("  final time: $(round(summary.final_time, digits = 3))")
    println("  events: $(summary.events)")
    println("  final hungry: $(summary.final_hungry)")
    println("  final eat: $(summary.final_eat)")
    println("  deadlock: $dead")

    return net, df, dead
end

function main()
    mkpath(datadir())
    mkpath(plotsdir())

    N = 5
    tmax = 50.0

    println("=== Classical network ===")
    net_classic, df_classic, _ = run_network(
        "classic",
        build_classical_network,
        N,
        tmax,
        123,
    )
    CSV.write(datadir("dining_classic.csv"), df_classic)
    plot_marking_evolution(
        df_classic,
        N,
        plotsdir("classic_simulation.png");
        title = "Classical",
    )

    println()
    println("=== Network with arbiter ===")
    net_arbiter, df_arbiter, _ = run_network(
        "arbiter",
        build_arbiter_network,
        N,
        tmax,
        123,
    )
    CSV.write(datadir("dining_arbiter.csv"), df_arbiter)
    plot_marking_evolution(
        df_arbiter,
        N,
        plotsdir("arbiter_simulation.png");
        title = "Arbiter",
    )

    println()
    println("Saved:")
    println("  $(datadir("dining_classic.csv"))")
    println("  $(datadir("dining_arbiter.csv"))")
    println("  $(plotsdir("classic_simulation.png"))")
    println("  $(plotsdir("arbiter_simulation.png"))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
