using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("QueueingModels.jl"))
using .QueueingModels

mkpath(datadir())
mkpath(plotsdir())

lambdas = [0.3, 0.6, 0.9]
channels = 1:6
mu = 0.5
num_customers = 3000
seed = 321

scan = run_mmc_parameter_scan(lambdas, channels, mu, num_customers, seed)

CSV.write(datadir("mmc_parameter_scan.csv"), scan)

save(plotsdir("mmc_wait_by_channels.png"), plot_mmc_wait_by_channels(scan))
save(plotsdir("mmc_wait_by_lambda.png"), plot_mmc_wait_by_lambda(scan))
save(plotsdir("mmc_utilization_heatmap.png"), plot_mmc_utilization_heatmap(scan))

println("M/M/c parameter scan completed")
println(scan)
