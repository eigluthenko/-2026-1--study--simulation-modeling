# # Итоговый отчетный сценарий
# Сценарий читает сохраненные CSV-файлы и строит итоговые графики:
# сравнение I(t) и зависимость peak_I от beta.

using DrWatson
@quickactivate "project"

using CairoMakie
using CSV
using DataFrames

include(srcdir("SIRPetri.jl"))
using .SIRPetri

mkpath(plotsdir())

df_det = CSV.read(datadir("sir_det.csv"), DataFrame)
df_stoch = CSV.read(datadir("sir_stoch.csv"), DataFrame)
df_scan = CSV.read(datadir("sir_scan.csv"), DataFrame)

save(plotsdir("comparison.png"), plot_comparison(df_det, df_stoch))
save(plotsdir("sensitivity.png"), plot_sensitivity(df_scan))

println("Report plots saved")
println("  plots/comparison.png")
println("  plots/sensitivity.png")
