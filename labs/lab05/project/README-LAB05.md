# Laboratory work 5

Topic: Petri nets and the dining philosophers problem.

Main files:

- `src/DiningPhilosophers.jl` - Petri-net model, simulation, deadlock detection, plots.
- `scripts/dining_philosophers.jl` - basic experiment for the classical network and the arbiter network.
- `scripts/dining_philosophers_animation.jl` - marking animation.
- `scripts/dining_philosophers_report.jl` - final Eat_i comparison plot.
- `scripts/dining_philosophers_params.jl` - parameter study by N, tmax, and seed.
- `scripts/tangle.jl` - generation of clean scripts, Quarto documents, and notebooks with Literate.jl.

Generated artifacts:

- `data/dining_classic.csv`
- `data/dining_arbiter.csv`
- `data/dining_params.csv`
- `plots/classic_simulation.png`
- `plots/arbiter_simulation.png`
- `plots/philosophers_simulation.gif`
- `plots/final_report.png`
- `plots/dining_params.png`
- `scripts/<name>/<name>.jl`
- `docs/<name>/<name>.qmd`
- `notebooks/<name>/<name>.ipynb`
