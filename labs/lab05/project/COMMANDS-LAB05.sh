#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

~/.juliaup/bin/julia --version

~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

~/.juliaup/bin/julia --project=. scripts/dining_philosophers.jl
~/.juliaup/bin/julia --project=. scripts/dining_philosophers_animation.jl
~/.juliaup/bin/julia --project=. scripts/dining_philosophers_report.jl
~/.juliaup/bin/julia --project=. scripts/dining_philosophers_params.jl

~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/dining_philosophers.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/dining_philosophers_animation.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/dining_philosophers_report.jl
~/.juliaup/bin/julia --project=. scripts/tangle.jl scripts/dining_philosophers_params.jl

ls -1 plots | sort
find data -maxdepth 1 -type f | sort
find scripts -maxdepth 2 -type f | sort
find notebooks -maxdepth 2 -type f | sort
find docs -maxdepth 2 -type f | sort
