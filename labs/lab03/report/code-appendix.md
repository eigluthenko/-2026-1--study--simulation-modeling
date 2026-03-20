# Литературный код

В данном разделе приведены основные исходные тексты, использованные при выполнении лабораторной работы. Код включён в отчёт полностью, чтобы обеспечить воспроизводимость результатов и соответствие формату литературного программирования.

## Основной модуль модели `src/daisyworld.jl`

В этом файле определены агент `Daisy`, функции расчёта температуры, правила эволюции агентов, построение модели и функции визуализации.

```julia
using Agents
using CairoMakie
using Random
using Statistics
using StatsBase

@agent struct Daisy(GridAgent{2})
    breed::Symbol
    age::Int
    albedo::Float64
end

function calc_temperature(albedo, model)
    absorbed_luminosity = (1 - albedo) * model.solar_luminosity
    return absorbed_luminosity > 0 ? 72 * log(absorbed_luminosity) + 80 : 80.0
end

global_temperature(model) = mean(model.temperature)
black(a) = a.breed == :black
white(a) = a.breed == :white

function occupancy_matrix(model)
    grid = fill(0.5, size(model.temperature))
    for pos in positions(model)
        if !isempty(pos, model)
            daisy = model[id_in_position(pos, model)]
            grid[pos...] = daisy.breed == :black ? 0.0 : 1.0
        end
    end
    return grid
end

function update_temperatures!(model)
    for pos in positions(model)
        if isempty(pos, model)
            model.temperature[pos...] = calc_temperature(model.surface_albedo, model)
        else
            daisy = model[id_in_position(pos, model)]
            model.temperature[pos...] = calc_temperature(daisy.albedo, model)
        end
    end
    model.global_temperature = global_temperature(model)
    return model
end

function daisy_step!(agent, model)
    agent.age += 1
    if agent.age >= model.max_age
        old_pos = agent.pos
        remove_agent!(agent, model)
        model.temperature[old_pos...] = calc_temperature(model.surface_albedo, model)
        return
    end

    empty_neighbors = collect(empty_nearby_positions(agent, model, 1))
    isempty(empty_neighbors) && return

    temp = model.temperature[agent.pos...]
    seed_threshold = 0.1457 * temp - 0.0032 * temp^2 - 0.6443
    if seed_threshold > 0 && rand(abmrng(model)) < seed_threshold
        pos = rand(abmrng(model), empty_neighbors)
        add_agent!(pos, model, agent.breed, 0, agent.albedo)
        model.temperature[pos...] = calc_temperature(agent.albedo, model)
    end
end

function model_step!(model)
    if model.scenario == :ramp
        model.solar_luminosity += model.solar_change
        if model.solar_luminosity >= 2.0 || model.solar_luminosity <= 0.5
            model.solar_change = -model.solar_change
        end
    elseif model.scenario == :change
        model.solar_luminosity += model.solar_change
    end
    update_temperatures!(model)
    return model
end

function daisyworld(;
    gridsize = (30, 30),
    init_black = 0.2,
    init_white = 0.2,
    albedo_black = 0.25,
    albedo_white = 0.75,
    surface_albedo = 0.4,
    solar_luminosity = 1.0,
    solar_change = 0.005,
    max_age = 25,
    scenario = :default,
    seed = 165,
)
    rng = MersenneTwister(seed)
    space = GridSpaceSingle(gridsize; periodic = false)
    temperature = zeros(Float64, gridsize...)
    properties = Dict(
        :max_age => max_age,
        :surface_albedo => surface_albedo,
        :solar_luminosity => solar_luminosity,
        :solar_change => solar_change,
        :scenario => scenario,
        :temperature => temperature,
        :global_temperature => 0.0,
    )

    model = StandardABM(
        Daisy,
        space;
        agent_step! = daisy_step!,
        model_step! = model_step!,
        properties,
        rng,
    )

    grid = collect(positions(model))
    total_cells = prod(gridsize)
    white_positions = StatsBase.sample(rng, grid, Int(init_white * total_cells); replace = false)
    for pos in white_positions
        add_agent!(pos, model, :white, rand(rng, 0:max_age), albedo_white)
    end

    remaining = setdiff(grid, white_positions)
    black_positions = StatsBase.sample(rng, remaining, Int(init_black * total_cells); replace = false)
    for pos in black_positions
        add_agent!(pos, model, :black, rand(rng, 0:max_age), albedo_black)
    end

    update_temperatures!(model)
    return model
end

function plot_daisyworld(model; title = nothing)
    fig = Figure(size = (700, 700))
    ax = Axis(fig[1, 1]; title, xlabel = "x", ylabel = "y", aspect = DataAspect())
    data = occupancy_matrix(model)
    heatmap!(ax, data; colormap = [:black, :gray85, :white], colorrange = (0, 1))
    return fig
end

function full_dynamics_figure(adf, mdf; title = "")
    fig = Figure(size = (900, 900))

    ax1 = Axis(fig[1, 1]; title, ylabel = "Daisy Count")
    lines!(ax1, adf.time, adf.count_black; label = "Black", color = :black, linewidth = 2)
    lines!(ax1, adf.time, adf.count_white; label = "White", color = :orange, linewidth = 2)
    axislegend(ax1; position = :rt)

    ax2 = Axis(fig[2, 1]; ylabel = "Temperature")
    temp_col = hasproperty(mdf, :global_temperature) ? :global_temperature : :temperature
    lines!(ax2, mdf.time, getproperty(mdf, temp_col); color = :firebrick, linewidth = 2)

    ax3 = Axis(fig[3, 1]; xlabel = "Step", ylabel = "Luminosity")
    lines!(ax3, mdf.time, mdf.solar_luminosity; color = :steelblue, linewidth = 2)

    for ax in (ax1, ax2)
        ax.xticklabelsvisible = false
    end

    return fig
end

```

## Скрипт `daisyworld.jl`

**Daisyworld: базовая визуализация.** Построение тепловых карт состояния модели на нескольких шагах симуляции.

```julia
# # Daisyworld: базовая визуализация
# Построение тепловых карт состояния модели на нескольких шагах симуляции.

using DrWatson
@quickactivate "project"

using Agents
using CairoMakie

include(srcdir("daisyworld.jl"))

mkpath(plotsdir())

model = daisyworld()
let current_step = 0
    for target_step in (0, 1, 5, 40)
        delta = target_step - current_step
        if delta > 0
            run!(model, delta)
            current_step = target_step
        end
        fig = plot_daisyworld(model; title = "Daisyworld, step = $target_step")
        fname = "daisy_step$(lpad(target_step, 3, '0')).png"
        save(plotsdir(fname), fig)
        println("saved: ", plotsdir(fname))
    end
end

```

## Скрипт `daisyworld-animate.jl`

**Daisyworld: анимация.** Покадровая запись эволюции модели в MP4.

```julia
# # Daisyworld: анимация
# Покадровая запись эволюции модели в MP4.

using DrWatson
@quickactivate "project"

using Agents
using CairoMakie

include(srcdir("daisyworld.jl"))

mkpath(plotsdir())

model = daisyworld()
outfile = plotsdir("daisyworld_animation.mp4")
frames = 100
state = Observable(occupancy_matrix(model))

fig = Figure(size = (700, 700))
ax = Axis(fig[1, 1]; title = "Daisyworld animation", xlabel = "x", ylabel = "y", aspect = DataAspect())
heatmap!(ax, state; colormap = [:black, :gray85, :white], colorrange = (0, 1))

record(fig, outfile, 1:frames) do _
    run!(model, 1)
    state[] = occupancy_matrix(model)
end

println("saved: ", outfile)

```

## Скрипт `daisyworld-count.jl`

**Daisyworld: динамика численности.** Построение графика количества черных и белых маргариток по времени.

```julia
# # Daisyworld: динамика численности
# Построение графика количества черных и белых маргариток по времени.

using DrWatson
@quickactivate "project"

using Agents
using CairoMakie

include(srcdir("daisyworld.jl"))

mkpath(plotsdir())

model = daisyworld()
adata = [(black, count), (white, count)]
adf, _ = run!(model, 100; adata)

fig = Figure(size = (800, 400))
ax = Axis(fig[1, 1]; xlabel = "Step", ylabel = "Count")
lines!(ax, adf.time, adf.count_black; label = "Black", color = :black, linewidth = 2)
lines!(ax, adf.time, adf.count_white; label = "White", color = :orange, linewidth = 2)
axislegend(ax)

outfile = plotsdir("daisy_count_plot.png")
save(outfile, fig)
println("saved: ", outfile)

```

## Скрипт `daisyworld-luminosity.jl`

**Daisyworld: полная динамика.** Сценарий `ramp` с графиками численности, температуры и светимости.

```julia
# # Daisyworld: полная динамика
# Сценарий `ramp` с графиками численности, температуры и светимости.

using DrWatson
@quickactivate "project"

using Agents
using CairoMakie

include(srcdir("daisyworld.jl"))

mkpath(plotsdir())

model = daisyworld(; scenario = :ramp)
adata = [(black, count), (white, count)]
mdata = [:solar_luminosity, :global_temperature]
adf, mdf = run!(model, 1000; adata, mdata)

fig = full_dynamics_figure(adf, mdf; title = "Daisyworld ramp dynamics")
outfile = plotsdir("daisy_luminosity_plot.png")
save(outfile, fig)
println("saved: ", outfile)

```

## Скрипт `daisyworld__param.jl`

**Daisyworld: параметрическое исследование heatmap.** Варьирование `init_white` и `max_age` для пространственной картины модели.

```julia
# # Daisyworld: параметрическое исследование heatmap
# Варьирование `init_white` и `max_age` для пространственной картины модели.

using DrWatson
@quickactivate "project"

using Agents
using CairoMakie

include(srcdir("daisyworld.jl"))

mkpath(plotsdir())

for init_white in (0.2, 0.8), max_age in (25, 40)
    params = @strdict init_white max_age
    model = daisyworld(; init_white, max_age)
    let current_step = 0
        for target_step in (0, 1, 4, 40)
            delta = target_step - current_step
            if delta > 0
                run!(model, delta)
                current_step = target_step
            end
            fig = plot_daisyworld(
                model;
                title = "init_white=$(init_white), max_age=$(max_age), step=$(target_step)",
            )
            fname = savename("daisyworld", params, "png"; connector = "_")
            fname *= "_step$(lpad(target_step, 2, '0')).png"
            save(plotsdir(fname), fig)
            println("saved: ", plotsdir(fname))
        end
    end
end

```

## Скрипт `daisyworld-count__param.jl`

**Daisyworld: параметрическое исследование численности.** Графики численности для всех комбинаций `init_white` и `max_age`.

```julia
# # Daisyworld: параметрическое исследование численности
# Графики численности для всех комбинаций `init_white` и `max_age`.

using DrWatson
@quickactivate "project"

using Agents
using CairoMakie

include(srcdir("daisyworld.jl"))

mkpath(plotsdir())

for init_white in (0.2, 0.8), max_age in (25, 40)
    params = @strdict init_white max_age
    model = daisyworld(; init_white, max_age)
    adata = [(black, count), (white, count)]
    adf, _ = run!(model, 100; adata)

    fig = Figure(size = (800, 400))
    ax = Axis(
        fig[1, 1];
        title = savename(params),
        xlabel = "Step",
        ylabel = "Count",
    )
    lines!(ax, adf.time, adf.count_black; label = "Black", color = :black, linewidth = 2)
    lines!(ax, adf.time, adf.count_white; label = "White", color = :orange, linewidth = 2)
    axislegend(ax)

    fname = savename("daisy-count", params, "png")
    save(plotsdir(fname), fig)
    println("saved: ", plotsdir(fname))
end

```

## Скрипт `daisyworld-luminosity__param.jl`

**Daisyworld: параметрическое исследование полной динамики.** Трехпанельные графики для сценария `ramp` с разными `init_white` и `max_age`.

```julia
# # Daisyworld: параметрическое исследование полной динамики
# Трехпанельные графики для сценария `ramp` с разными `init_white` и `max_age`.

using DrWatson
@quickactivate "project"

using Agents
using CairoMakie

include(srcdir("daisyworld.jl"))

mkpath(plotsdir())

for init_white in (0.2, 0.8), max_age in (25, 40)
    scenario = :ramp
    params = @strdict init_white max_age scenario
    model = daisyworld(; init_white, max_age, scenario)
    adata = [(black, count), (white, count)]
    mdata = [:solar_luminosity, :global_temperature]
    adf, mdf = run!(model, 1000; adata, mdata)

    fig = full_dynamics_figure(
        adf,
        mdf;
        title = "init_white=$(init_white), max_age=$(max_age), scenario=$(scenario)",
    )
    fname = savename("daisy-luminosity", params, "png")
    save(plotsdir(fname), fig)
    println("saved: ", plotsdir(fname))
end

```

## Скрипт `tangle.jl`

**!/usr/bin/env julia.** Ниже приведён полный текст скрипта.

```julia
#!/usr/bin/env julia

using DrWatson
@quickactivate "project"

using Literate

function main()
    if isempty(ARGS)
        println("Usage: julia --project=. scripts/tangle.jl <script1.jl> [script2.jl ...]")
        return
    end

    for script_path in ARGS
        if !isfile(script_path)
            error("file not found: $script_path")
        end

        script_name = splitext(basename(script_path))[1]
        out_scripts = scriptsdir(script_name)
        out_notebooks = projectdir("notebooks", script_name)
        out_docs = projectdir("docs", script_name)

        mkpath(out_scripts)
        mkpath(out_notebooks)
        mkpath(out_docs)

        Literate.script(script_path, out_scripts; credit = false)
        Literate.notebook(script_path, out_notebooks; name = script_name, execute = false, credit = false)
        Literate.markdown(script_path, out_docs; name = script_name, credit = false)

        println("generated for $script_name")
        println("  script   -> $(joinpath(out_scripts, script_name * ".jl"))")
        println("  notebook -> $(joinpath(out_notebooks, script_name * ".ipynb"))")
        println("  markdown -> $(joinpath(out_docs, script_name * ".md"))")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

```

