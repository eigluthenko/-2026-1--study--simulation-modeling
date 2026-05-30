# Laboratory work 8

Topic: discrete-event modeling of the SIR epidemic with `ConcurrentSim` and `ResumableFunctions`.

Main files:

- `src/SIRModels.jl` - discrete-event SIR model, deterministic ODE reference, parameter scan, summaries and plots.
- `scripts/sir.jl` - baseline discrete-event experiment.
- `scripts/sir_parameters.jl` - parameter sensitivity scan over `β`, `c`, `γ`.
- `scripts/tangle.jl` - generation of clean scripts, markdown files and notebooks with `Literate.jl`.

Generated artifacts:

- `data/sir_trajectory.csv`
- `data/sir_ode.csv`
- `data/sir_summary.csv`
- `data/sir_ensemble.csv`
- `data/sir_parameter_scan.csv`
- `plots/*.png`
