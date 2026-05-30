# # Базовый эксперимент: экспоненциальный рост
#
# Этот сценарий решает уравнение экспоненциального роста `du/dt = α·u` методом
# Рунге–Кутты 4-го порядка, сравнивает численное решение с аналитическим
# `u(t) = u0·e^{α t}`, сохраняет временной ряд и сводные метрики и строит график.

using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("ExponentialGrowth.jl"))
using .ExponentialGrowth

mkpath(datadir())
mkpath(plotsdir())

# ## Параметры модели
#
# Начальная численность `u0`, скорость роста `α`, временной интервал и шаг сетки.

u0 = 1.0
α = 0.3
tspan = (0.0, 10.0)
dt = 0.1

# ## Прогон модели
#
# Численное интегрирование и сводные характеристики прогона.

df = run_growth(u0, α, tspan; dt = dt)
summary = growth_summary(df, u0, α)

# ## Сохранение результатов

CSV.write(datadir("growth_trajectory.csv"), df)
CSV.write(datadir("growth_summary.csv"), summary)

# ## График

save(plotsdir("growth_base.png"), plot_growth(df, α))

println("Exponential growth baseline completed")
println("  doubling time = ", round(doubling_time(α), digits = 3))
println(summary)
