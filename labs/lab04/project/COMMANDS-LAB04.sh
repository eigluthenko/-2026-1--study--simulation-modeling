#!/usr/bin/env bash
set -euo pipefail

cd /home/lilidji/github-push-work/labs/lab04/project

~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

~/.juliaup/bin/julia --project=. scripts/sir_run_basic.jl
~/.juliaup/bin/julia --project=. scripts/sir_scan_beta.jl
~/.juliaup/bin/julia --project=. scripts/sir_migration_effect.jl
~/.juliaup/bin/julia --project=. scripts/sir_optimize_parameters.jl
~/.juliaup/bin/julia --project=. scripts/sir_visualize_dynamics.jl
~/.juliaup/bin/julia --project=. scripts/sir_heterogeneity_effect.jl
~/.juliaup/bin/julia --project=. scripts/sir_quarantine_scenario.jl
~/.juliaup/bin/julia --project=. scripts/sir_optimize_with_constraint.jl

~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_run_basic.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_scan_beta.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_migration_effect.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_optimize_parameters.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_visualize_dynamics.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_heterogeneity_effect.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_quarantine_scenario.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/sir_optimize_with_constraint.jl

jupyter nbconvert --to notebook --execute --inplace notebooks/sir_run_basic/sir_run_basic.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/sir_scan_beta/sir_scan_beta.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/sir_migration_effect/sir_migration_effect.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/sir_optimize_parameters/sir_optimize_parameters.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/sir_visualize_dynamics/sir_visualize_dynamics.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/sir_heterogeneity_effect/sir_heterogeneity_effect.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/sir_quarantine_scenario/sir_quarantine_scenario.ipynb
jupyter nbconvert --to notebook --execute --inplace notebooks/sir_optimize_with_constraint/sir_optimize_with_constraint.ipynb

ls -1 plots | sort
find data -maxdepth 2 -type f | sort
find scripts -maxdepth 2 -type f | sort
find notebooks -maxdepth 2 -type f | sort
find docs -maxdepth 2 -type f | sort
