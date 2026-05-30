using Test
using DrWatson

@quickactivate "project"

include(srcdir("SIRModels.jl"))
using .SIRModels

@test basic_reproduction_number(0.05, 10.0, 0.25) ≈ 2.0
@test final_size_root(0.8) == 0.0
@test 0.79 < final_size_root(2.0) < 0.81

ode = run_sir_ode([990, 10, 0], [0.05, 10.0, 0.25], 40.0; dt = 0.1)
@test all(isapprox.(ode.S .+ ode.I .+ ode.R, 1000.0; atol = 1e-6))
@test ode.R[end] > ode.R[1]

des = run_sir_des([90, 10, 0], [0.05, 10.0, 0.25], 40.0; seed = 1)
@test des.S[end] + des.I[end] + des.R[end] == 100
@test des.R[end] >= des.R[1]
