```@meta
EditURL = "../scripts/growth_parameters_literate.jl"
```

# Параметрическое исследование экспоненциального роста

Этот сценарий исследует влияние скорости роста `α` на динамику: перебирает
сетку значений, для каждого считает итоговую численность и время удвоения,
сравнивает с теоретической зависимостью `T₂ = ln2/α` и строит графики.

````@example growth_parameters
using DrWatson
@quickactivate "project"

using CSV
using CairoMakie

include(srcdir("ExponentialGrowth.jl"))
using .ExponentialGrowth

mkpath(datadir())
mkpath(plotsdir())
````

## Сетка параметров

````@example growth_parameters
u0 = 1.0
alphas = [0.1, 0.3, 0.5, 0.8, 1.0]
tspan = (0.0, 10.0)
dt = 0.1
````

## Параметрическое сканирование

````@example growth_parameters
scan = run_growth_scan(u0, alphas, tspan; dt = dt)
````

## Сохранение результатов

````@example growth_parameters
CSV.write(datadir("growth_parameter_scan.csv"), scan)
````

## Графики

````@example growth_parameters
save(plotsdir("growth_comparison.png"), plot_growth_comparison(u0, alphas, tspan; dt = dt))
save(plotsdir("growth_doubling.png"), plot_doubling_time(scan))

println("Exponential growth parameter scan completed")
println("  scenarios: $(size(scan, 1))")
println(scan)
````

