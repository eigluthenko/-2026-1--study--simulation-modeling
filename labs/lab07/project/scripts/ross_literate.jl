# # Базовый эксперимент модели Росса
# Сценарий моделирует работу системы с резервом и одним ремонтником, сохраняет
# журнал событий демонстрационного прогона, набор независимых прогонов и
# итоговую сводку.

using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("QueueingModels.jl"))
using .QueueingModels

mkpath(datadir())
mkpath(plotsdir())

N = 10
S = 3
repairers = 1
mean_time_to_failure = 100.0
mean_repair_time = 1.0
runs = 300
seed = 150

events, runs_df, summary = run_ross_experiment(N, S, repairers, mean_time_to_failure, mean_repair_time, runs, seed)

CSV.write(datadir("ross_events_sample.csv"), events)
CSV.write(datadir("ross_runs.csv"), runs_df)
CSV.write(datadir("ross_summary.csv"), summary)

save(plotsdir("ross_good_machines.png"), plot_ross_good_machines(events))
save(plotsdir("ross_spares.png"), plot_ross_spares(events))
save(plotsdir("ross_repair_queue.png"), plot_ross_repair_queue(events))
save(plotsdir("ross_crash_time_histogram.png"), plot_ross_crash_histogram(runs_df))
save(plotsdir("ross_simulation_vs_analytic.png"), plot_ross_simulation_vs_analytic(summary))
save(plotsdir("ross_repairer_utilization.png"), plot_ross_repairer_utilization(summary))

println("Ross baseline experiment completed")
println(summary)
