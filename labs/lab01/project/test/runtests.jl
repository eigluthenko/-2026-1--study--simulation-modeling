using Test
using DrWatson

@quickactivate "project"

include(srcdir("ExponentialGrowth.jl"))
using .ExponentialGrowth

@test analytic_growth(1.0, 0.3, 0.0) == 1.0
@test analytic_growth(1.0, 0.3, 10.0) ≈ exp(3.0)
@test doubling_time(0.3) ≈ log(2) / 0.3

df = run_growth(1.0, 0.3, (0.0, 10.0); dt = 0.05)
@test df.t[1] == 0.0 && df.t[end] ≈ 10.0
@test df.u[end] ≈ exp(3.0) rtol = 1e-3
@test maximum(df.abs_error) < 1e-2

scan = run_growth_scan(1.0, [0.1, 0.3, 0.5], (0.0, 10.0); dt = 0.05)
@test size(scan, 1) == 3
@test issorted(scan.doubling_time, rev = true)
