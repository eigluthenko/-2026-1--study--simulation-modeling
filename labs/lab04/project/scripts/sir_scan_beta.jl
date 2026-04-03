# # Исследование коэффициента заразности
# Сканирование параметра beta и усреднение эпидемических характеристик.

using DrWatson
@quickactivate "project"

using CSV
using CairoMakie
using DataFrames
using Statistics

include(srcdir("sir_model.jl"))

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir())
mkpath(datadir(script_name))

beta_values = 0.1:0.1:0.8
seeds = 1:8
base = (
    Ns = [1000, 1000, 1000],
    Is = [1, 0, 0],
    infection_period = 14,
    detection_time = 7,
    death_rate = 0.02,
    reinfection_probability = 0.1,
    migration_intensity = 0.0,
    n_steps = 80,
)

rows = DataFrame(
    n_steps = Int[], final_rec = Float64[], Ns = Vector{Int}[], death_rate = Float64[],
    Is = Vector{Int}[], beta = Float64[], infection_period = Int[], final_inf = Float64[],
    detection_time = Int[], deaths = Int[], peak = Float64[],
    reinfection_probability = Float64[], seed = Int[]
)

for beta in beta_values
    beta_det = beta / 10
    for seed in seeds
        model = initialize_sir(
            Ns = base.Ns,
            Is = base.Is,
            beta_und = beta,
            beta_det = beta_det,
            infection_period = base.infection_period,
            detection_time = base.detection_time,
            death_rate = base.death_rate,
            reinfection_probability = base.reinfection_probability,
            migration_intensity = base.migration_intensity,
            seed = seed,
        )
        df = simulate_sir!(model, base.n_steps)
        metrics = summarize_dynamics(df, sum(base.Ns))
        push!(rows, (
            base.n_steps,
            metrics.final_rec,
            base.Ns,
            base.death_rate,
            base.Is,
            beta,
            base.infection_period,
            metrics.final_inf,
            base.detection_time,
            metrics.deaths,
            metrics.peak,
            base.reinfection_probability,
            seed,
        ))
    end
    println("beta = ", beta, " completed")
end

CSV.write(datadir(script_name, "beta_scan_all.csv"), rows)
summary = combine(groupby(rows, :beta),
    :peak => mean => :peak_mean,
    :final_rec => mean => :final_rec_mean,
    :deaths => mean => :deaths_mean)
CSV.write(datadir(script_name, "beta_scan_summary.csv"), summary)

fig = Figure(size = (950, 900))
ax1 = Axis(fig[1, 1]; title = "Peak infected fraction", xlabel = "beta", ylabel = "Peak share")
lines!(ax1, summary.beta, summary.peak_mean; color = :firebrick2, linewidth = 2)
ax2 = Axis(fig[2, 1]; title = "Mean deaths", xlabel = "beta", ylabel = "Deaths")
lines!(ax2, summary.beta, summary.deaths_mean; color = :gray20, linewidth = 2)
ax3 = Axis(fig[3, 1]; title = "Mean recovered share", xlabel = "beta", ylabel = "Recovered share")
lines!(ax3, summary.beta, summary.final_rec_mean; color = :seagreen4, linewidth = 2)

outfile = plotsdir("beta_scan_summary.png")
save(outfile, fig)
println("saved: ", outfile)
println("saved: ", datadir(script_name, "beta_scan_all.csv"))
println("saved: ", datadir(script_name, "beta_scan_summary.csv"))
