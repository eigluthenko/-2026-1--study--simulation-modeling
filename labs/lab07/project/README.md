# Laboratory work 7

Topic: discrete-event modeling with the `M/M/c` queue and the Ross machine-repair model.

Main files:

- `src/QueueingModels.jl` - simulation functions, analytic formulas, tables and plots.
- `scripts/mmc.jl` - baseline `M/M/c` experiment.
- `scripts/mmc_parameters.jl` - parameter scan for `M/M/c`.
- `scripts/ross.jl` - baseline Ross experiment.
- `scripts/ross_parameters.jl` - parameter scan for the Ross model.
- `scripts/tangle.jl` - generation of clean scripts, markdown files and notebooks with `Literate.jl`.

Generated artifacts:

- `data/mmc_customers.csv`
- `data/mmc_events.csv`
- `data/mmc_summary.csv`
- `data/mmc_parameter_scan.csv`
- `data/ross_events_sample.csv`
- `data/ross_runs.csv`
- `data/ross_summary.csv`
- `data/ross_parameter_scan.csv`
- `plots/*.png`
