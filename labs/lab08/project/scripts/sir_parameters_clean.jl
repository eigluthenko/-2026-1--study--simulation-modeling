using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("SIRModels.jl"))
using .SIRModels

mkpath(datadir())
mkpath(plotsdir())

u0 = [990, 10, 0]
betas = [0.03, 0.05, 0.07]
contacts = [6.0, 10.0, 14.0]
gammas = [0.2, 0.25, 0.33]
tmax = 40.0
runs = 6
seed = 2000

scan = run_sir_parameter_scan(u0;
    betas = betas,
    contacts = contacts,
    gammas = gammas,
    tf = tmax,
    runs = runs,
    seed = seed)

CSV.write(datadir("sir_parameter_scan.csv"), scan)

save(plotsdir("sir_peak_by_beta.png"), plot_sir_peak_by_beta(scan))
save(plotsdir("sir_peak_by_contacts.png"), plot_sir_peak_by_contacts(scan))
save(plotsdir("sir_final_size_by_r0.png"), plot_sir_final_size_by_r0(scan))
save(plotsdir("sir_peak_heatmap.png"), plot_sir_peak_heatmap(scan))

println("SIR parameter scan completed")
println("  scenarios: $(size(scan, 1))")
