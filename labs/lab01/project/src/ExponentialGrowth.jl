module ExponentialGrowth

using CairoMakie
using DataFrames
using Statistics

export analytic_growth,
    doubling_time,
    run_growth,
    growth_summary,
    run_growth_scan,
    plot_growth,
    plot_growth_comparison,
    plot_doubling_time

# # Модель экспоненциального роста
#
# Уравнение `du/dt = α·u`, `u(0) = u0`, с аналитическим решением `u(t) = u0·e^{α t}`.

"Аналитическое решение `u(t) = u0·e^{α t}`."
analytic_growth(u0::Real, α::Real, t::Real) = u0 * exp(α * t)

"Время удвоения величины: `T₂ = ln 2 / α`."
doubling_time(α::Real) = log(2) / α

"Правая часть уравнения роста."
_growth_rhs(u, α) = α * u

"""
    run_growth(u0, α, tspan; dt = 0.1)

Численно интегрирует `du/dt = α·u` методом Рунге–Кутты 4-го порядка и
возвращает `DataFrame` с колонками `t`, `u` (численное решение),
`u_analytic` (точное решение) и `abs_error` (модуль их разности).
"""
function run_growth(u0::Real, α::Real, tspan; dt::Real = 0.1)
    t0, tf = Float64(tspan[1]), Float64(tspan[2])
    nsteps = Int(round((tf - t0) / dt))
    ts = zeros(Float64, nsteps + 1)
    us = zeros(Float64, nsteps + 1)
    ua = zeros(Float64, nsteps + 1)
    u = Float64(u0)
    ts[1], us[1], ua[1] = t0, u, Float64(u0)
    for step in 1:nsteps
        t = t0 + (step - 1) * dt
        k1 = _growth_rhs(u, α)
        k2 = _growth_rhs(u + dt / 2 * k1, α)
        k3 = _growth_rhs(u + dt / 2 * k2, α)
        k4 = _growth_rhs(u + dt * k3, α)
        u = u + dt / 6 * (k1 + 2k2 + 2k3 + k4)
        ts[step + 1] = t + dt
        us[step + 1] = u
        ua[step + 1] = analytic_growth(u0, α, t + dt)
    end
    return DataFrame(t = ts, u = us, u_analytic = ua, abs_error = abs.(us .- ua))
end

"""
    growth_summary(df, u0, α)

Однострочный `DataFrame` со сводкой прогона: начальное значение, параметр роста,
итоговая численность (численная и аналитическая), время удвоения и максимальная
абсолютная погрешность численного решения.
"""
function growth_summary(df::DataFrame, u0::Real, α::Real)
    return DataFrame([(
        u0 = Float64(u0),
        alpha = Float64(α),
        final_numeric = df.u[end],
        final_analytic = df.u_analytic[end],
        doubling_time = doubling_time(α),
        max_abs_error = maximum(df.abs_error),
    )])
end

"""
    run_growth_scan(u0, alphas, tspan; dt = 0.1)

Перебирает значения параметра роста `α` и для каждого возвращает строку с
итоговой численностью, временем удвоения и максимальной погрешностью.
"""
function run_growth_scan(u0::Real, alphas::AbstractVector{<:Real}, tspan; dt::Real = 0.1)
    rows = NamedTuple[]
    for α in alphas
        df = run_growth(u0, α, tspan; dt = dt)
        push!(rows, (
            alpha = Float64(α),
            final_numeric = df.u[end],
            final_analytic = df.u_analytic[end],
            doubling_time = doubling_time(α),
            max_abs_error = maximum(df.abs_error),
        ))
    end
    return DataFrame(rows)
end

# # Визуализация

const PALETTE = [:royalblue3, :darkorange3, :seagreen4, :firebrick2, :purple4, :goldenrod4]

"График базового прогона: численное решение и аналитическая кривая."
function plot_growth(df::DataFrame, α::Real)
    fig = Figure(size = (1000, 580))
    ax = Axis(fig[1, 1]; xlabel = "Time t", ylabel = "Population u(t)",
        title = "Exponential growth (α = $(α))")
    lines!(ax, df.t, df.u_analytic; color = :slateblue3, linewidth = 3, label = "analytic")
    scatter!(ax, df.t, df.u; color = :firebrick2, markersize = 7, label = "RK4")
    axislegend(ax; position = :lt)
    return fig
end

"Сравнение траекторий роста для набора значений `α`."
function plot_growth_comparison(u0::Real, alphas::AbstractVector{<:Real}, tspan; dt::Real = 0.1)
    fig = Figure(size = (1000, 580))
    ax = Axis(fig[1, 1]; xlabel = "Time t", ylabel = "Population u(t)",
        title = "Exponential growth by rate α")
    for (idx, α) in enumerate(alphas)
        df = run_growth(u0, α, tspan; dt = dt)
        lines!(ax, df.t, df.u; color = PALETTE[mod1(idx, length(PALETTE))],
            linewidth = 2.5, label = "α = $(α)")
    end
    axislegend(ax; position = :lt)
    return fig
end

"Зависимость времени удвоения от `α`: имитация и теоретическая кривая `ln2/α`."
function plot_doubling_time(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Growth rate α", ylabel = "Doubling time T₂",
        title = "Doubling time vs growth rate")
    ordered = sort(scan, :alpha)
    α_grid = range(minimum(ordered.alpha), maximum(ordered.alpha); length = 200)
    lines!(ax, collect(α_grid), log(2) ./ collect(α_grid);
        color = :slateblue3, linewidth = 2.5, label = "theory: ln2/α")
    scatter!(ax, ordered.alpha, ordered.doubling_time;
        color = :firebrick2, markersize = 12, label = "simulation")
    axislegend(ax; position = :rt)
    return fig
end

end
