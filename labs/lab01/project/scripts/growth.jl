using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("ExponentialGrowth.jl"))
using .ExponentialGrowth

mkpath(datadir())
mkpath(plotsdir())

u0 = 1.0
α = 0.3
tspan = (0.0, 10.0)
dt = 0.1

df = run_growth(u0, α, tspan; dt = dt)
summary = growth_summary(df, u0, α)

CSV.write(datadir("growth_trajectory.csv"), df)
CSV.write(datadir("growth_summary.csv"), summary)

save(plotsdir("growth_base.png"), plot_growth(df, α))

println("Exponential growth baseline completed")
println("  doubling time = ", round(doubling_time(α), digits = 3))
println(summary)
