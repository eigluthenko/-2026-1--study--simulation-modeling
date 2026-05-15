using Test
using DrWatson

@quickactivate "project"

include(srcdir("QueueingModels.jl"))
using .QueueingModels

@test analytic_mmc_metrics(0.9, 0.5, 2).rho ≈ 0.9
@test analytic_ross_crash_time(10, 3, 1, 100.0, 1.0) > 0
