```@meta
EditURL = "../scripts/mmc_literate.jl"
```

# Базовый эксперимент M/M/c
Этот сценарий строит имитационную модель M/M/c, сохраняет журнал заявок,
журнал событий и сводную таблицу, а также формирует четыре графика.

````@example mmc
using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("QueueingModels.jl"))
using .QueueingModels

mkpath(datadir())
mkpath(plotsdir())

lambda = 0.9
mu = 0.5
c = 2
num_customers = 5000
seed = 123

customers, events, summary = run_mmc_experiment(lambda, mu, c, num_customers, seed)

CSV.write(datadir("mmc_customers.csv"), customers)
CSV.write(datadir("mmc_events.csv"), events)
CSV.write(datadir("mmc_summary.csv"), summary)

save(plotsdir("mmc_queue_length.png"), plot_mmc_queue_length(events))
save(plotsdir("mmc_busy_servers.png"), plot_mmc_busy_servers(events))
save(plotsdir("mmc_wait_histogram.png"), plot_mmc_wait_histogram(customers))
save(plotsdir("mmc_analytic_vs_simulation.png"), plot_mmc_analytic_vs_simulation(summary))

println("M/M/c baseline experiment completed")
println(summary)
````

