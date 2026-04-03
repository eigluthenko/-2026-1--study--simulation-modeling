using DrWatson
@quickactivate "project"

using BlackBoxOptim
using CSV
using DataFrames

include(srcdir("sir_model.jl"))

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(datadir(script_name))

const OPTIMIZATION_SEEDS = (101, 202, 303)

function objective(x)
    beta_und = x[1]
    detection_time = round(Int, x[2])
    death_rate = x[3]
    score = 0.0
    for seed in OPTIMIZATION_SEEDS
        model = initialize_sir(
            Ns = [1000, 1000, 1000],
            Is = [1, 0, 0],
            beta_und = beta_und,
            beta_det = beta_und / 10,
            infection_period = 14,
            detection_time = clamp(detection_time, 2, 12),
            death_rate = clamp(death_rate, 0.0, 0.1),
            reinfection_probability = 0.1,
            migration_intensity = 0.2,
            seed = seed,
        )
        df = simulate_sir!(model, 60)
        metrics = summarize_dynamics(df, 3000)
        score += metrics.death_fraction + 0.7 * metrics.peak
    end
    return score / length(OPTIMIZATION_SEEDS)
end

res = bboptimize(objective;
    SearchRange = [(0.25, 0.8), (2.0, 12.0), (0.01, 0.08)],
    NumDimensions = 3,
    MaxSteps = 25,
    TraceMode = :verbose,
)

best = best_candidate(res)
beta_und = best[1]
detection_time = round(Int, best[2])
death_rate = best[3]
objective_value = best_fitness(res)

out = DataFrame(
    beta_und = [beta_und],
    beta_det = [beta_und / 10],
    detection_time = [detection_time],
    death_rate = [death_rate],
    objective = [objective_value],
)
CSV.write(datadir(script_name, "optimization_basic.csv"), out)
println(out)
println("saved: ", datadir(script_name, "optimization_basic.csv"))
