module SIRModels

using ConcurrentSim
using ResumableFunctions
using CairoMakie
using DataFrames
using Distributions
using Random
using StableRNGs
using Statistics

export SIRPerson,
    SIRModel,
    make_sir_model,
    activate_sir!,
    run_sir!,
    out,
    run_sir_des,
    sir_summary,
    basic_reproduction_number,
    final_size_root,
    run_sir_ensemble,
    run_sir_ode,
    run_sir_parameter_scan,
    plot_sir_trajectory,
    plot_sir_des_vs_ode,
    plot_sir_ensemble,
    plot_sir_phase,
    plot_sir_peak_by_beta,
    plot_sir_peak_by_contacts,
    plot_sir_final_size_by_r0,
    plot_sir_peak_heatmap

# # Структуры данных

"Агент-индивид: уникальный идентификатор и текущий статус (:S, :I, :R)."
mutable struct SIRPerson
    id::Int
    status::Symbol
end

"""
Полное состояние дискретно-событийной SIR-модели.

`sim` — объект виртуального времени и очереди событий ConcurrentSim;
`β`, `c`, `γ` — вероятность передачи при контакте, частота контактов и
интенсивность выздоровления; `det_recovery` переключает экспоненциальную
длительность болезни на детерминированную `1/γ`; `rng` обеспечивает
воспроизводимость; `ta`, `Sa`, `Ia`, `Ra` — временные ряды событий и
численности; `individuals` — список всех агентов.
"""
mutable struct SIRModel
    sim::Simulation
    β::Float64
    c::Float64
    γ::Float64
    det_recovery::Bool
    rng::AbstractRNG
    ta::Vector{Float64}
    Sa::Vector{Int}
    Ia::Vector{Int}
    Ra::Vector{Int}
    individuals::Vector{SIRPerson}
end

# # Вспомогательные функции мутации рядов статистики

"Добавляет в конец массива значение, увеличенное на 1 относительно последнего."
increment!(a::Vector{Int}) = push!(a, a[end] + 1)

"Добавляет значение, уменьшенное на 1 относительно последнего."
decrement!(a::Vector{Int}) = push!(a, a[end] - 1)

"Дублирует последнее значение массива."
carryover!(a::Vector{Int}) = push!(a, a[end])

# # Обновление статистики при событиях

"Заражение: фиксирует время, уменьшает S, увеличивает I, переносит R."
function infection_update!(sim::Simulation, m::SIRModel)
    push!(m.ta, now(sim))
    decrement!(m.Sa)
    increment!(m.Ia)
    carryover!(m.Ra)
end

"Выздоровление: фиксирует время, переносит S, уменьшает I, увеличивает R."
function recovery_update!(sim::Simulation, m::SIRModel)
    push!(m.ta, now(sim))
    carryover!(m.Sa)
    decrement!(m.Ia)
    increment!(m.Ra)
end

# # Основной процесс агента

"""
Жизненный цикл одного индивида как возобновляемая функция-генератор.

Пока агент восприимчив, он ждёт случайное время до следующего контакта
(экспоненциально с параметром `1/c`), выбирает случайного собеседника и,
если тот инфицирован, с вероятностью `β` заражается. После заражения агент
ждёт время до выздоровления и переходит в `:R`.
"""
@resumable function live(env::Simulation, individual::SIRPerson, m::SIRModel)
    while individual.status == :S
        @yield timeout(env, rand(m.rng, Exponential(1 / m.c)))
        alter = individual
        while alter === individual
            alter = m.individuals[rand(m.rng, 1:length(m.individuals))]
        end
        if alter.status == :I
            if rand(m.rng) < m.β
                individual.status = :I
                infection_update!(env, m)
            end
        end
    end
    if individual.status == :I
        recovery_delay = m.det_recovery ? 1 / m.γ : rand(m.rng, Exponential(1 / m.γ))
        @yield timeout(env, recovery_delay)
        individual.status = :R
        recovery_update!(env, m)
    end
end

# # Функции управления моделью

"""
    make_sir_model(u0, p; seed = 1234, det_recovery = false)

Создаёт экземпляр `SIRModel` по начальным условиям `u0 = [S0, I0, R0]` и
параметрам `p = [β, c, γ]`. Генерирует список индивидов с соответствующими
статусами и инициализирует временные ряды.
"""
function make_sir_model(u0, p; seed::Integer = 1234, det_recovery::Bool = false)
    (S, I, R) = u0
    (β, c, γ) = p
    N = S + I + R
    sim = Simulation()
    rng = StableRNG(seed)
    individuals = SIRPerson[]
    for i in 1:S
        push!(individuals, SIRPerson(i, :S))
    end
    for i in (S + 1):(S + I)
        push!(individuals, SIRPerson(i, :I))
    end
    for i in (S + I + 1):N
        push!(individuals, SIRPerson(i, :R))
    end
    return SIRModel(sim, Float64(β), Float64(c), Float64(γ), det_recovery, rng,
        Float64[0.0], Int[S], Int[I], Int[R], individuals)
end

"Запускает процессы агентов; на этом этапе они только регистрируются в симуляции."
function activate_sir!(m::SIRModel)
    for individual in m.individuals
        @process live(m.sim, individual, m)
    end
    return m
end

"Продвигает виртуальное время до `tf`, обрабатывая все запланированные события."
function run_sir!(m::SIRModel, tf::Real)
    run(m.sim, Float64(tf))
    return m
end

"Собирает накопленные временные ряды в `DataFrame` с колонками `t`, `S`, `I`, `R`."
function out(m::SIRModel)
    return DataFrame(t = m.ta, S = m.Sa, I = m.Ia, R = m.Ra)
end

"""
    run_sir_des(u0, p, tf; seed, det_recovery)

Полный прогон дискретно-событийной модели: создание, активация процессов,
запуск симуляции и сбор результатов в `DataFrame`.
"""
function run_sir_des(u0, p, tf; seed::Integer = 1234, det_recovery::Bool = false)
    m = make_sir_model(u0, p; seed = seed, det_recovery = det_recovery)
    activate_sir!(m)
    run_sir!(m, tf)
    return out(m)
end

# # Сводные характеристики прогона

"Базовое репродуктивное число `R0 = β · c / γ`."
basic_reproduction_number(β, c, γ) = Float64(β) * Float64(c) / Float64(γ)

"""
    final_size_root(r0; iterations = 200)

Численное решение уравнения конечного размера эпидемии `z = 1 - exp(-R0 · z)`
методом простых итераций. Возвращает долю переболевших при `R0 > 1` и `0` иначе.
"""
function final_size_root(r0::Real; iterations::Integer = 200)
    r0 <= 1 && return 0.0
    z = 0.5
    for _ in 1:iterations
        z = 1 - exp(-r0 * z)
    end
    return z
end

"""
    sir_summary(df, u0, p)

Формирует однострочный `DataFrame` с ключевыми метриками прогона: высота и
время пика инфицированных, итоговая доля переболевших, `R0` и аналитическая
оценка конечного размера эпидемии.
"""
function sir_summary(df::DataFrame, u0, p)
    (β, c, γ) = p
    N = sum(u0)
    peak_idx = argmax(df.I)
    r0 = basic_reproduction_number(β, c, γ)
    return DataFrame([(
        beta = Float64(β),
        c = Float64(c),
        gamma = Float64(γ),
        N = Int(N),
        r0 = r0,
        peak_I = df.I[peak_idx],
        peak_time = df.t[peak_idx],
        final_R = df.R[end],
        final_fraction = df.R[end] / N,
        analytic_final_fraction = final_size_root(r0),
        events = nrow(df) - 1,
    )])
end

"""
    run_sir_ensemble(u0, p, tf, runs; seed, det_recovery)

Выполняет `runs` независимых прогонов модели с разными зёрнами и возвращает
кортеж `(trajectories, stats)`: вектор траекторий и таблицу метрик прогонов.
Прогон считается «затухшим», если итоговая доля переболевших не превышает 5%.
"""
function run_sir_ensemble(u0, p, tf, runs::Integer; seed::Integer = 1000, det_recovery::Bool = false)
    N = sum(u0)
    trajectories = DataFrame[]
    rows = NamedTuple[]
    for r in 1:runs
        df = run_sir_des(u0, p, tf; seed = seed + r, det_recovery = det_recovery)
        push!(trajectories, df)
        peak_idx = argmax(df.I)
        final_fraction = df.R[end] / N
        push!(rows, (
            run_id = r,
            peak_I = df.I[peak_idx],
            peak_time = df.t[peak_idx],
            final_R = df.R[end],
            final_fraction = final_fraction,
            extinct = final_fraction <= 0.05,
        ))
    end
    return trajectories, DataFrame(rows)
end

# # Детерминированная модель сравнения

"Правая часть детерминированной системы ОДУ для модели SIR."
function _sir_ode_rhs(u, β, c, γ, N)
    S, I, R = u
    force = β * c * I / N
    return (-force * S, force * S - γ * I, γ * I)
end

"""
    run_sir_ode(u0, p, tf; dt = 0.05)

Интегрирует детерминированную систему SIR методом Рунге–Кутты 4-го порядка.
Сила инфекции `β · c · I / N` согласована с логикой контактов дискретной модели.
Возвращает `DataFrame` с колонками `t`, `S`, `I`, `R`.
"""
function run_sir_ode(u0, p, tf; dt::Real = 0.05)
    (β, c, γ) = Float64.(p)
    N = Float64(sum(u0))
    nsteps = Int(round(tf / dt))
    ts = zeros(Float64, nsteps + 1)
    Ss = zeros(Float64, nsteps + 1)
    Is = zeros(Float64, nsteps + 1)
    Rs = zeros(Float64, nsteps + 1)
    u = Float64.(collect(u0))
    ts[1], Ss[1], Is[1], Rs[1] = 0.0, u[1], u[2], u[3]
    for step in 1:nsteps
        t = (step - 1) * dt
        k1 = _sir_ode_rhs(u, β, c, γ, N)
        k2 = _sir_ode_rhs(u .+ dt / 2 .* k1, β, c, γ, N)
        k3 = _sir_ode_rhs(u .+ dt / 2 .* k2, β, c, γ, N)
        k4 = _sir_ode_rhs(u .+ dt .* k3, β, c, γ, N)
        u = u .+ dt / 6 .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4)
        ts[step + 1] = t + dt
        Ss[step + 1], Is[step + 1], Rs[step + 1] = u[1], u[2], u[3]
    end
    return DataFrame(t = ts, S = Ss, I = Is, R = Rs)
end

# # Параметрическое исследование (анализ чувствительности)

"""
    run_sir_parameter_scan(u0; betas, contacts, gammas, tf, runs, seed)

Перебирает сетку параметров `β × c × γ`, для каждого набора усредняет метрики
по `runs` прогонам и возвращает `DataFrame` с `R0`, средними высотой и временем
пика, средней итоговой долей переболевших и аналитической оценкой.
"""
function run_sir_parameter_scan(u0;
        betas::AbstractVector{<:Real},
        contacts::AbstractVector{<:Real},
        gammas::AbstractVector{<:Real},
        tf::Real,
        runs::Integer = 10,
        seed::Integer = 2000)
    N = sum(u0)
    rows = NamedTuple[]
    scenario = 0
    for β in betas
        for c in contacts
            for γ in gammas
                scenario += 1
                peak_I = Float64[]
                peak_time = Float64[]
                final_fraction = Float64[]
                for r in 1:runs
                    df = run_sir_des(u0, (β, c, γ), tf; seed = seed + 1000 * scenario + r)
                    idx = argmax(df.I)
                    push!(peak_I, df.I[idx])
                    push!(peak_time, df.t[idx])
                    push!(final_fraction, df.R[end] / N)
                end
                r0 = basic_reproduction_number(β, c, γ)
                push!(rows, (
                    beta = Float64(β),
                    c = Float64(c),
                    gamma = Float64(γ),
                    r0 = r0,
                    runs = Int(runs),
                    mean_peak_I = mean(peak_I),
                    std_peak_I = length(peak_I) > 1 ? std(peak_I) : 0.0,
                    mean_peak_time = mean(peak_time),
                    mean_final_fraction = mean(final_fraction),
                    analytic_final_fraction = final_size_root(r0),
                ))
            end
        end
    end
    return DataFrame(rows)
end

# # Визуализация

const PALETTE = [:royalblue3, :darkorange3, :seagreen4, :firebrick2, :purple4, :goldenrod4]

"График временных рядов S, I, R одного прогона."
function plot_sir_trajectory(df::DataFrame)
    fig = Figure(size = (1000, 580))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Individuals", title = "Discrete-event SIR dynamics")
    stairs!(ax, df.t, Float64.(df.S); color = :royalblue3, linewidth = 2, label = "S")
    stairs!(ax, df.t, Float64.(df.I); color = :firebrick2, linewidth = 2, label = "I")
    stairs!(ax, df.t, Float64.(df.R); color = :seagreen4, linewidth = 2, label = "R")
    axislegend(ax; position = :rc)
    return fig
end

"Сравнение дискретно-событийной и детерминированной траекторий S, I, R."
function plot_sir_des_vs_ode(des::DataFrame, ode::DataFrame)
    fig = Figure(size = (1000, 600))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Individuals", title = "Discrete-event vs deterministic SIR")
    stairs!(ax, des.t, Float64.(des.S); color = :royalblue3, linewidth = 2, label = "S (DES)")
    stairs!(ax, des.t, Float64.(des.I); color = :firebrick2, linewidth = 2, label = "I (DES)")
    stairs!(ax, des.t, Float64.(des.R); color = :seagreen4, linewidth = 2, label = "R (DES)")
    lines!(ax, ode.t, ode.S; color = :royalblue3, linestyle = :dash, linewidth = 2.5, label = "S (ODE)")
    lines!(ax, ode.t, ode.I; color = :firebrick2, linestyle = :dash, linewidth = 2.5, label = "I (ODE)")
    lines!(ax, ode.t, ode.R; color = :seagreen4, linestyle = :dash, linewidth = 2.5, label = "R (ODE)")
    axislegend(ax; position = :rc, nbanks = 2)
    return fig
end

"Ансамбль стохастических траекторий I(t) и детерминированная кривая для сравнения."
function plot_sir_ensemble(trajectories::Vector{DataFrame}, ode::DataFrame)
    fig = Figure(size = (1000, 580))
    ax = Axis(fig[1, 1]; xlabel = "Time", ylabel = "Infected", title = "SIR stochastic ensemble (infected)")
    for (idx, df) in enumerate(trajectories)
        lbl = idx == 1 ? "stochastic runs" : nothing
        stairs!(ax, df.t, Float64.(df.I); color = (:steelblue, 0.35), linewidth = 1, label = lbl)
    end
    lines!(ax, ode.t, ode.I; color = :firebrick2, linewidth = 3, label = "deterministic")
    axislegend(ax; position = :rt)
    return fig
end

"Фазовый портрет: число инфицированных против числа восприимчивых."
function plot_sir_phase(df::DataFrame)
    fig = Figure(size = (820, 700))
    ax = Axis(fig[1, 1]; xlabel = "Susceptible", ylabel = "Infected", title = "SIR phase portrait (S vs I)")
    lines!(ax, Float64.(df.S), Float64.(df.I); color = :purple4, linewidth = 2)
    scatter!(ax, [Float64(df.S[1])], [Float64(df.I[1])]; color = :seagreen4, markersize = 12, label = "start")
    scatter!(ax, [Float64(df.S[end])], [Float64(df.I[end])]; color = :firebrick2, markersize = 12, label = "end")
    axislegend(ax; position = :rt)
    return fig
end

"Высота пика инфицированных как функция вероятности передачи β."
function plot_sir_peak_by_beta(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Beta", ylabel = "Mean peak infected", title = "SIR peak by transmission probability")
    for (idx, c) in enumerate(sort(unique(scan.c)))
        sub = sort(scan[scan.c .== c, :], :beta)
        lines!(ax, sub.beta, sub.mean_peak_I; color = PALETTE[mod1(idx, length(PALETTE))], linewidth = 2.5, label = "c=$(c)")
        scatter!(ax, sub.beta, sub.mean_peak_I; color = PALETTE[mod1(idx, length(PALETTE))], markersize = 10)
    end
    axislegend(ax; position = :rb)
    return fig
end

"Высота пика инфицированных как функция частоты контактов c."
function plot_sir_peak_by_contacts(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Contact rate c", ylabel = "Mean peak infected", title = "SIR peak by contact rate")
    for (idx, γ) in enumerate(sort(unique(scan.gamma)))
        sub = sort(scan[scan.gamma .== γ, :], :c)
        lines!(ax, sub.c, sub.mean_peak_I; color = PALETTE[mod1(idx, length(PALETTE))], linewidth = 2.5, label = "γ=$(γ)")
        scatter!(ax, sub.c, sub.mean_peak_I; color = PALETTE[mod1(idx, length(PALETTE))], markersize = 10)
    end
    axislegend(ax; position = :rb)
    return fig
end

"Итоговая доля переболевших против R0: имитация и аналитическая кривая конечного размера."
function plot_sir_final_size_by_r0(scan::DataFrame)
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "R0", ylabel = "Final fraction recovered", title = "SIR final size by R0")
    ordered = sort(scan, :r0)
    scatter!(ax, ordered.r0, ordered.mean_final_fraction; color = :firebrick2, markersize = 11, label = "simulation")
    r0_grid = range(max(0.1, minimum(scan.r0)), maximum(scan.r0); length = 200)
    analytic = [final_size_root(r0) for r0 in r0_grid]
    lines!(ax, collect(r0_grid), analytic; color = :slateblue3, linewidth = 2.5, label = "analytic")
    vlines!(ax, [1.0]; color = :gray40, linestyle = :dash, linewidth = 1.5)
    axislegend(ax; position = :rb)
    return fig
end

"Тепловая карта высоты пика инфицированных по сетке (β, γ) при фиксированном c."
function plot_sir_peak_heatmap(scan::DataFrame)
    target_c = sort(unique(scan.c))[1]
    sub = scan[scan.c .== target_c, :]
    betas = sort(unique(sub.beta))
    gammas = sort(unique(sub.gamma))
    matrix = [sub[(sub.beta .== β) .& (sub.gamma .== γ), :mean_peak_I][1] for β in betas, γ in gammas]
    fig = Figure(size = (1000, 560))
    ax = Axis(fig[1, 1]; xlabel = "Gamma", ylabel = "Beta", title = "SIR peak infected heatmap (c=$(target_c))")
    hm = heatmap!(ax, gammas, betas, permutedims(matrix); colormap = :viridis)
    Colorbar(fig[1, 2], hm, label = "Mean peak infected")
    return fig
end

end
