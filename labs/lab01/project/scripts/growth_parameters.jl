using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("ExponentialGrowth.jl"))
using .ExponentialGrowth

mkpath(datadir())
mkpath(plotsdir())

u0 = 1.0
alphas = [0.1, 0.3, 0.5, 0.8, 1.0]
tspan = (0.0, 10.0)
dt = 0.1

scan = run_growth_scan(u0, alphas, tspan; dt = dt)

CSV.write(datadir("growth_parameter_scan.csv"), scan)

save(plotsdir("growth_comparison.png"), plot_growth_comparison(u0, alphas, tspan; dt = dt))
save(plotsdir("growth_doubling.png"), plot_doubling_time(scan))

println("Exponential growth parameter scan completed")
println("  scenarios: $(size(scan, 1))")
println(scan)
