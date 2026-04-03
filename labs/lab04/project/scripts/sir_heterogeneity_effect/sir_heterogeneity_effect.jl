using DrWatson
@quickactivate "project"

using CSV
using CairoMakie
using DataFrames

include(srcdir("sir_model.jl"))

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir())
mkpath(datadir(script_name))

beta_und = [0.3, 0.5, 0.8]
beta_det = beta_und ./ 10
model = initialize_sir(
    Ns = [1000, 1000, 1000],
    Is = [1, 0, 0],
    beta_und = beta_und,
    beta_det = beta_det,
    infection_period = 14,
    detection_time = 7,
    death_rate = 0.02,
    reinfection_probability = 0.1,
    migration_intensity = 0.2,
    seed = 9001,
)

df = simulate_sir!(model, 80; by_city = true)
CSV.write(datadir(script_name, "heterogeneity_dynamics.csv"), df)

summary = DataFrame(
    city = 1:3,
    beta_und = beta_und,
    beta_det = beta_det,
    peak_infected = [maximum(df[!, Symbol("I_city$(city)")]) for city in 1:3],
)
CSV.write(datadir(script_name, "heterogeneity_summary.csv"), summary)

fig = Figure(size = (1000, 900))
for city in 1:3
    ax = Axis(fig[city, 1]; title = "City $(city)", xlabel = "Step", ylabel = "Agents")
    lines!(ax, df.time, df[!, Symbol("S_city$(city)")]; color = :royalblue3, linewidth = 2, label = "S")
    lines!(ax, df.time, df[!, Symbol("I_city$(city)")]; color = :firebrick2, linewidth = 2, label = "I")
    lines!(ax, df.time, df[!, Symbol("R_city$(city)")]; color = :seagreen4, linewidth = 2, label = "R")
    axislegend(ax; position = :rt)
end

outfile = plotsdir("heterogeneity_dynamics.png")
save(outfile, fig)
println(summary)
println("saved: ", outfile)
println("saved: ", datadir(script_name, "heterogeneity_dynamics.csv"))
println("saved: ", datadir(script_name, "heterogeneity_summary.csv"))
