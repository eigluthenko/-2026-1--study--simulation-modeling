# # Базовый агентный эксперимент SIR
# Один запуск модели SIR на полном графе из трёх городов.

using DrWatson
@quickactivate "project"

using CSV
using CairoMakie
using DataFrames

include(srcdir("sir_model.jl"))

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir())
mkpath(datadir(script_name))

params = (
    Ns = [1000, 1000, 1000],
    Is = [1, 0, 0],
    beta_und = 0.5,
    beta_det = 0.05,
    infection_period = 14,
    detection_time = 7,
    death_rate = 0.02,
    reinfection_probability = 0.1,
    migration_intensity = 0.0,
    seed = 2026,
    n_steps = 80,
)

model = initialize_sir(
    Ns = params.Ns,
    Is = params.Is,
    beta_und = params.beta_und,
    beta_det = params.beta_det,
    infection_period = params.infection_period,
    detection_time = params.detection_time,
    death_rate = params.death_rate,
    reinfection_probability = params.reinfection_probability,
    migration_intensity = params.migration_intensity,
    seed = params.seed,
)

df = simulate_sir!(model, params.n_steps)
CSV.write(datadir(script_name, "basic_dynamics.csv"), df)

metrics = summarize_dynamics(df, sum(params.Ns))
println("Basic SIR run")
println("  peak infected fraction = ", round(metrics.peak, digits = 4))
println("  peak time              = ", metrics.peak_time)
println("  final recovered frac   = ", round(metrics.final_rec, digits = 4))
println("  death fraction         = ", round(metrics.death_fraction, digits = 4))

fig = Figure(size = (1000, 550))
ax = Axis(fig[1, 1]; title = "Agent SIR dynamics", xlabel = "Step", ylabel = "Agents")
lines!(ax, df.time, df.susceptible; color = :royalblue3, linewidth = 2, label = "S")
lines!(ax, df.time, df.infected; color = :firebrick2, linewidth = 2, label = "I")
lines!(ax, df.time, df.recovered; color = :seagreen4, linewidth = 2, label = "R")
lines!(ax, df.time, df.total; color = :gray30, linewidth = 2, linestyle = :dash, label = "total")
axislegend(ax; position = :rt)

outfile = plotsdir("sir_basic_dynamics.png")
save(outfile, fig)
println("saved: ", outfile)
println("saved: ", datadir(script_name, "basic_dynamics.csv"))
