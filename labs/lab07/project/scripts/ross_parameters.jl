using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("QueueingModels.jl"))
using .QueueingModels

mkpath(datadir())
mkpath(plotsdir())

N_values = [5, 10, 15]
S_values = [1, 3]
repairer_values = [1, 2]
mean_time_to_failure = 100.0
mean_repair_time = 1.0
runs = 20
seed = 500

scan = run_ross_parameter_scan(N_values, S_values, repairer_values, mean_time_to_failure, mean_repair_time, runs, seed)

CSV.write(datadir("ross_parameter_scan.csv"), scan)

save(plotsdir("ross_crash_time_by_n.png"), plot_ross_crash_time_by_n(scan))
save(plotsdir("ross_crash_time_by_spares.png"), plot_ross_crash_time_by_spares(scan))
save(plotsdir("ross_repairers_comparison.png"), plot_ross_repairers_comparison(scan))
save(plotsdir("ross_repairer_utilization_by_scenario.png"), plot_ross_repairer_utilization_by_scenario(scan))

println("Ross model parameter scan completed")
println("  scenarios: ", size(scan, 1))
