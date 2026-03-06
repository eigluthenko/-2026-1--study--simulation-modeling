# # Модель Лотки-Вольтерры: Параметрическое исследование
# **Цель:** Исследовать влияние параметров на динамику хищник-жертва.
#
# ## Инициализация проекта

using DrWatson
@quickactivate "project"

using DifferentialEquations
using DataFrames
using StatsPlots
using LaTeXStrings
using Plots
using Statistics

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# ## Определение модели Лотки-Вольтерры

function lotka_volterra!(du, u, p, t)
    x, y = u
    α, β, δ, γ = p
    @inbounds begin
        du[1] = α*x - β*x*y
        du[2] = δ*x*y - γ*y
    end
    nothing
end

# ## Базовые параметры
u0_lv = [40.0, 9.0]
tspan_lv = (0.0, 200.0)
dt_lv = 0.01

# ## Параметрическое сканирование по α
# Исследуем влияние скорости размножения жертв $\alpha$ на динамику системы.

α_values = [0.05, 0.1, 0.15, 0.2, 0.3]
β_base = 0.02
δ_base = 0.01
γ_base = 0.3

println("="^60)
println("Параметрическое исследование модели Лотки-Вольтерры")
println("="^60)
println("Фиксированные параметры: β = $β_base, δ = $δ_base, γ = $γ_base")
println("Варьируемый параметр: α ∈ $α_values")
println()

# ## Хранение результатов
results = DataFrame(
    α = Float64[],
    x_star = Float64[],
    y_star = Float64[],
    prey_min = Float64[],
    prey_max = Float64[],
    prey_mean = Float64[],
    pred_min = Float64[],
    pred_max = Float64[],
    pred_mean = Float64[]
)

# ## Графики: динамика для разных α
plt_prey = plot(xlabel="Время", ylabel="Популяция жертв",
    title="Влияние α на динамику жертв",
    linewidth=2, legend=:topright, grid=true, size=(900, 400))
plt_pred = plot(xlabel="Время", ylabel="Популяция хищников",
    title="Влияние α на динамику хищников",
    linewidth=2, legend=:topright, grid=true, size=(900, 400))
plt_phase = plot(xlabel="Жертвы (x)", ylabel="Хищники (y)",
    title="Фазовые портреты при разных α",
    linewidth=1.5, legend=:topright, grid=true, size=(800, 600))

for α in α_values
    p = [α, β_base, δ_base, γ_base]

    x_star = γ_base / δ_base
    y_star = α / β_base

    prob = ODEProblem(lotka_volterra!, u0_lv, tspan_lv, p)
    sol = solve(prob, Tsit5(), dt=dt_lv, reltol=1e-8, abstol=1e-10, saveat=0.1)

    prey = [u[1] for u in sol.u]
    predator = [u[2] for u in sol.u]
    t = sol.t

    push!(results, (α=α, x_star=x_star, y_star=y_star,
        prey_min=minimum(prey), prey_max=maximum(prey), prey_mean=mean(prey),
        pred_min=minimum(predator), pred_max=maximum(predator), pred_mean=mean(predator)))

    plot!(plt_prey, t, prey, label="α=$α", linewidth=1.5)
    plot!(plt_pred, t, predator, label="α=$α", linewidth=1.5)
    plot!(plt_phase, prey, predator, label="α=$α", linewidth=1.2)

    println("α = $α: x*=$(round(x_star, digits=1)), y*=$(round(y_star, digits=1)), " *
        "жертвы=$(round(minimum(prey), digits=1))..$(round(maximum(prey), digits=1)), " *
        "хищники=$(round(minimum(predator), digits=1))..$(round(maximum(predator), digits=1))")
end

savefig(plt_prey, plotsdir(script_name, "lv_param_prey.png"))
savefig(plt_pred, plotsdir(script_name, "lv_param_predator.png"))
savefig(plt_phase, plotsdir(script_name, "lv_param_phase.png"))

# ## Сводная таблица результатов
println("\n" * "="^60)
println("Сводная таблица результатов")
println("="^60)
println(results)

# ## График зависимости равновесия от α
plt_eq = plot(results.α, results.y_star,
    xlabel=L"\alpha", ylabel="Равновесное значение",
    title="Стационарные точки от α",
    label=L"y^* = \alpha/\beta", marker=:circle, markersize=6,
    linewidth=2, color=:red, grid=true, size=(800, 400))
hline!(plt_eq, [results.x_star[1]], color=:green, linestyle=:dash,
    label="x* = γ/δ = $(results.x_star[1]) (не зависит от α)")
savefig(plt_eq, plotsdir(script_name, "lv_param_equilibrium.png"))

# ## График амплитуд колебаний
plt_amp = plot(results.α, results.prey_max .- results.prey_min,
    xlabel=L"\alpha", ylabel="Амплитуда колебаний",
    title="Амплитуда колебаний от α",
    label="Жертвы", marker=:circle, markersize=6,
    linewidth=2, color=:green, grid=true, size=(800, 400))
plot!(plt_amp, results.α, results.pred_max .- results.pred_min,
    label="Хищники", marker=:square, markersize=6,
    linewidth=2, color=:red)
savefig(plt_amp, plotsdir(script_name, "lv_param_amplitude.png"))

# ## Компактная панель
plt_panel = plot(plt_prey, plt_pred, plt_phase, plt_eq,
    layout=(2, 2), size=(1200, 800))
savefig(plt_panel, plotsdir(script_name, "lv_param_panel.png"))

println("\nПараметрическое исследование Лотки-Вольтерры завершено!")
