using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("SIRModels.jl"))
using .SIRModels

mkpath(datadir())
mkpath(plotsdir())

u0 = [990, 10, 0]
p = [0.05, 10.0, 0.25]
tmax = 40.0
seed = 1234

des = run_sir_des(u0, p, tmax; seed = seed)
summary = sir_summary(des, u0, p)

ode = run_sir_ode(u0, p, tmax; dt = 0.05)

trajectories, ensemble = run_sir_ensemble(u0, p, tmax, 24; seed = 1000)

CSV.write(datadir("sir_trajectory.csv"), des)
CSV.write(datadir("sir_ode.csv"), ode)
CSV.write(datadir("sir_summary.csv"), summary)
CSV.write(datadir("sir_ensemble.csv"), ensemble)

save(plotsdir("sir_trajectory.png"), plot_sir_trajectory(des))
save(plotsdir("sir_des_vs_ode.png"), plot_sir_des_vs_ode(des, ode))
save(plotsdir("sir_ensemble.png"), plot_sir_ensemble(trajectories, ode))
save(plotsdir("sir_phase.png"), plot_sir_phase(des))

for n in (1000, 2000)
    local_u0 = [n - 10, 10, 0]
    elapsed = @elapsed run_sir_des(local_u0, p, tmax; seed = seed)
    println("sir_run for N=$(n): $(round(elapsed, digits = 3)) s")
end

println("SIR baseline experiment completed")
println(summary)
