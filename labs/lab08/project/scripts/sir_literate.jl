# # Базовый дискретно-событийный эксперимент SIR
#
# Этот сценарий строит дискретно-событийную модель распространения инфекции SIR,
# в которой каждый индивид представлен отдельным процессом ConcurrentSim. Прогон
# сохраняет временной ряд численности `S`, `I`, `R`, сводные метрики, ансамбль
# независимых стохастических реализаций и детерминированную систему ОДУ для
# сравнения, а также формирует графики.

using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("SIRModels.jl"))
using .SIRModels

mkpath(datadir())
mkpath(plotsdir())

# ## Параметры модели
#
# Начальное состояние популяции `u0 = [S0, I0, R0]` и параметры `p = [β, c, γ]`:
# вероятность передачи при контакте, частота контактов и интенсивность
# выздоровления. Базовое репродуктивное число `R0 = β·c/γ = 2.0`.

u0 = [990, 10, 0]
p = [0.05, 10.0, 0.25]
tmax = 40.0
seed = 1234

# ## Базовый прогон
#
# Один прогон дискретно-событийной модели и его сводные характеристики.

des = run_sir_des(u0, p, tmax; seed = seed)
summary = sir_summary(des, u0, p)

# ## Детерминированное сравнение
#
# Та же система в виде ОДУ, проинтегрированная методом Рунге–Кутты 4-го порядка.

ode = run_sir_ode(u0, p, tmax; dt = 0.05)

# ## Ансамбль стохастических реализаций
#
# Набор независимых прогонов с разными зёрнами позволяет увидеть разброс
# траекторий и оценить вероятность раннего затухания эпидемии.

trajectories, ensemble = run_sir_ensemble(u0, p, tmax, 24; seed = 1000)

# ## Сохранение результатов

CSV.write(datadir("sir_trajectory.csv"), des)
CSV.write(datadir("sir_ode.csv"), ode)
CSV.write(datadir("sir_summary.csv"), summary)
CSV.write(datadir("sir_ensemble.csv"), ensemble)

# ## Графики

save(plotsdir("sir_trajectory.png"), plot_sir_trajectory(des))
save(plotsdir("sir_des_vs_ode.png"), plot_sir_des_vs_ode(des, ode))
save(plotsdir("sir_ensemble.png"), plot_sir_ensemble(trajectories, ode))
save(plotsdir("sir_phase.png"), plot_sir_phase(des))

# ## Оценка производительности
#
# Замер времени одного прогона для популяций разного размера показывает, как
# растёт стоимость симуляции с числом агентов.

for n in (1000, 2000)
    local_u0 = [n - 10, 10, 0]
    elapsed = @elapsed run_sir_des(local_u0, p, tmax; seed = seed)
    println("sir_run for N=$(n): $(round(elapsed, digits = 3)) s")
end

println("SIR baseline experiment completed")
println(summary)
