using DrWatson
@quickactivate "project"

include(srcdir("SIRPetri.jl"))
using .SIRPetri

mkpath(plotsdir())

beta = 0.3
gamma = 0.1
tmax = 100.0

net, u0, _ = build_sir_network(beta, gamma)
df = simulate_deterministic(net, u0, (0.0, tmax); saveat = 1.0, rates = [beta, gamma])

make_animation(df, plotsdir("sir_animation.gif"); fps = 10)

println("Animation saved: plots/sir_animation.gif")
