using DrWatson
@quickactivate "project"

using DifferentialEquations
using Tables
using DataFrames
using StatsPlots
using LaTeXStrings
using Plots

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

function sir_ode!(du, u, p, t)
    (S, I, R) = u
    (β, c, γ) = p
    N = S + I + R
    @inbounds begin
        du[1] = -β * c * I / N * S
        du[2] = β * c * I / N * S - γ * I
        du[3] = γ * I
    end
    nothing
end

δt = 0.1
tmax = 60.0
tspan = (0.0, tmax)
u0 = [990.0, 10.0, 0.0]   # S, I, R

β_values = [0.02, 0.04, 0.06, 0.08, 0.1]
c_base = 10.0
γ_base = 0.25

println("="^60)
println("Параметрическое исследование модели SIR")
println("="^60)
println("Фиксированные параметры: c = $c_base, γ = $γ_base")
println("Варьируемый параметр: β ∈ $β_values")
println()

results = DataFrame(
    β = Float64[],
    R0 = Float64[],
    I_max = Float64[],
    t_peak = Float64[],
    R_final = Float64[],
    R_final_pct = Float64[]
)

plt_all = plot(xlabel="Время, дни", ylabel="Инфицированные I(t)",
    title="Влияние β на динамику эпидемии",
    linewidth=2, legend=:topright, grid=true, size=(900, 500))

for β in β_values
    p = [β, c_base, γ_base]
    R0 = (c_base * β) / γ_base

    prob = ODEProblem(sir_ode!, u0, tspan, p)
    sol = solve(prob, dt = δt)

    df = DataFrame(Tables.table(sol'))
    rename!(df, ["S", "I", "R"])
    df[!, :t] = sol.t

    peak_idx = argmax(df.I)
    I_max = df.I[peak_idx]
    t_peak = df.t[peak_idx]
    R_final = df.R[end]
    N = u0[1] + u0[2] + u0[3]
    R_final_pct = R_final/N*100

    push!(results, (β=β, R0=R0, I_max=I_max, t_peak=t_peak,
        R_final=R_final, R_final_pct=R_final_pct))

    plot!(plt_all, df.t, df.I,
        label="β=$(β), R₀=$(round(R0, digits=1))",
        linewidth=2)

    println("β = $β: R₀ = $(round(R0, digits=2)), " *
        "I_max = $(round(I_max, digits=1)), " *
        "t_peak = $(round(t_peak, digits=1)) дн., " *
        "R(∞) = $(round(R_final_pct, digits=1))%")
end

savefig(plt_all, plotsdir(script_name, "sir_param_infected.png"))

println("\n" * "="^60)
println("Сводная таблица результатов")
println("="^60)
println(results)

plt_r0 = plot(results.β, results.R0,
    xlabel=L"\beta", ylabel=L"R_0",
    title="Зависимость R₀ от β",
    marker=:circle, markersize=6, linewidth=2,
    grid=true, size=(800, 400), legend=false, color=:blue)
hline!(plt_r0, [1.0], color=:red, linestyle=:dash, label="R₀=1 (порог)")
savefig(plt_r0, plotsdir(script_name, "sir_param_R0.png"))

plt_peak = plot(results.β, results.I_max,
    xlabel=L"\beta", ylabel=L"I_{max}",
    title="Пиковое число заражённых от β",
    marker=:circle, markersize=6, linewidth=2,
    grid=true, size=(800, 400), legend=false, color=:red)
savefig(plt_peak, plotsdir(script_name, "sir_param_peak.png"))

plt_final = plot(results.β, results.R_final_pct,
    xlabel=L"\beta", ylabel="Доля переболевших, %",
    title="Итоговая доля переболевших от β",
    marker=:circle, markersize=6, linewidth=2,
    grid=true, size=(800, 400), legend=false, color=:green)
savefig(plt_final, plotsdir(script_name, "sir_param_final.png"))

plt_panel = plot(plt_all, plt_r0, plt_peak, plt_final,
    layout=(2, 2), size=(1200, 800))
savefig(plt_panel, plotsdir(script_name, "sir_param_panel.png"))

println("\nПараметрическое исследование SIR завершено!")
