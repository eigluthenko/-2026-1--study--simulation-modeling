# Laboratory work 6

Topic: SIR model implemented with a Petri-net representation.

Main files:

- `src/SIRPetri.jl` - Petri-net structure, deterministic RK4 solver, stochastic Gillespie simulation, plots and animation.
- `scripts/sirpetri_run.jl` - baseline deterministic and stochastic run.
- `scripts/sirpetri_scan_parameters.jl` - beta sensitivity scan.
- `scripts/sirpetri_animate.jl` - GIF animation of S, I, R markings.
- `scripts/sirpetri_report.jl` - final comparison and sensitivity plots.
- `scripts/tangle.jl` - generation of clean scripts, Quarto documents, and notebooks with Literate.jl.

Generated artifacts:

- `data/sir_det.csv`
- `data/sir_stoch.csv`
- `data/sir_scan.csv`
- `plots/sir_det_dynamics.png`
- `plots/sir_stoch_dynamics.png`
- `plots/sir_scan.png`
- `plots/sir_animation.gif`
- `plots/comparison.png`
- `plots/sensitivity.png`
