# Laboratory work 1

Topic: workspace setup and the exponential growth model `du/dt = α·u`.

Main files:

- `src/ExponentialGrowth.jl` - RK4 solver, analytic solution, doubling time, parameter scan and plots.
- `scripts/growth.jl` - baseline experiment (α = 0.3).
- `scripts/growth_parameters.jl` - parameter scan over α.
- `scripts/tangle.jl` - generation of clean scripts, markdown files and notebooks with `Literate.jl`.

Generated artifacts:

- `data/growth_trajectory.csv`
- `data/growth_summary.csv`
- `data/growth_parameter_scan.csv`
- `plots/*.png`
