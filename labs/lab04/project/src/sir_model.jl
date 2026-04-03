using Agents
using DataFrames
using Graphs
using Random
using Statistics

@agent struct Person(GraphAgent)
    status::Symbol
    infected_for::Int
end

susceptible(a) = a.status == :S
infected(a) = a.status == :I
recovered(a) = a.status == :R

function city_parameter(param, city)
    return param isa AbstractVector ? param[city] : param
end

function count_susceptible(model)
    return sum(model.city_S)
end

function count_infected(model)
    return sum(model.city_I)
end

function count_recovered(model)
    return sum(model.city_R)
end

count_total(model) = nagents(model)
deaths_total(model) = model.deaths

city_s(model, city) = model.city_S[city]
city_i(model, city) = model.city_I[city]
city_r(model, city) = model.city_R[city]
city_total(model, city) = model.city_total[city]
city_closed(model, city) = Int(model.closed_cities[city])

city1_s(model) = city_s(model, 1)
city2_s(model) = city_s(model, 2)
city3_s(model) = city_s(model, 3)
city1_i(model) = city_i(model, 1)
city2_i(model) = city_i(model, 2)
city3_i(model) = city_i(model, 3)
city1_r(model) = city_r(model, 1)
city2_r(model) = city_r(model, 2)
city3_r(model) = city_r(model, 3)
city1_closed(model) = city_closed(model, 1)
city2_closed(model) = city_closed(model, 2)
city3_closed(model) = city_closed(model, 3)

function refresh_city_statistics!(model)
    fill!(model.city_S, 0)
    fill!(model.city_I, 0)
    fill!(model.city_R, 0)
    fill!(model.city_total, 0)
    fill!(model.city_force, 0.0)

    for agent in allagents(model)
        city = agent.pos
        model.city_total[city] += 1
        if susceptible(agent)
            model.city_S[city] += 1
        elseif infected(agent)
            model.city_I[city] += 1
            β = agent.infected_for < model.detection_time ?
                city_parameter(model.beta_und, city) :
                city_parameter(model.beta_det, city)
            model.city_force[city] += β
        else
            model.city_R[city] += 1
        end
    end

    for city in 1:model.C
        total = model.city_total[city]
        model.city_lambda[city] = total > 0 ? 1 - exp(-model.city_force[city] / total) : 0.0
    end

    if model.quarantine_enabled
        for city in 1:model.C
            if !model.closed_cities[city] && model.city_total[city] > 0
                inf_fraction = model.city_I[city] / model.city_total[city]
                if inf_fraction >= model.quarantine_threshold
                    model.closed_cities[city] = true
                    model.closure_times[city] = model.step
                end
            end
        end
    end
    return model
end

function migration_destinations(agent, model)
    current = agent.pos
    candidates = Int[]
    for city in 1:model.C
        city == current && continue
        if model.quarantine_enabled && (model.closed_cities[current] || model.closed_cities[city])
            continue
        end
        push!(candidates, city)
    end
    return candidates
end

function attempt_migration!(agent, model)
    rand(abmrng(model)) >= model.migration_intensity && return
    destinations = migration_destinations(agent, model)
    isempty(destinations) && return
    move_agent!(agent, rand(abmrng(model), destinations), model)
end

function attempt_infection!(agent, model)
    p = model.city_lambda[agent.pos]
    if susceptible(agent)
        if rand(abmrng(model)) < p
            agent.status = :I
            agent.infected_for = 0
        end
    elseif recovered(agent)
        if rand(abmrng(model)) < model.reinfection_probability * p
            agent.status = :I
            agent.infected_for = 0
        end
    end
end

function resolve_infection!(agent, model)
    infected(agent) || return
    agent.infected_for += 1
    if agent.infected_for >= model.infection_period
        if rand(abmrng(model)) < model.death_rate
            model.deaths += 1
            remove_agent!(agent, model)
        else
            agent.status = :R
            agent.infected_for = 0
        end
    end
end

function sir_agent_step!(agent, model)
    attempt_migration!(agent, model)
    attempt_infection!(agent, model)
    resolve_infection!(agent, model)
end

function sir_model_step!(model)
    model.step += 1
    refresh_city_statistics!(model)
    return model
end

function initialize_sir(;
    Ns = [1000, 1000, 1000],
    Is = [1, 0, 0],
    beta_und = 0.5,
    beta_det = 0.05,
    infection_period = 14,
    detection_time = 7,
    death_rate = 0.02,
    reinfection_probability = 0.1,
    migration_intensity = 0.0,
    quarantine_enabled = false,
    quarantine_threshold = 0.05,
    seed = 2026,
)
    C = length(Ns)
    @assert length(Is) == C "Is must match number of cities"

    rng = MersenneTwister(seed)
    graph = complete_graph(C)
    space = GraphSpace(graph)
    properties = Dict(
        :beta_und => beta_und,
        :beta_det => beta_det,
        :infection_period => infection_period,
        :detection_time => detection_time,
        :death_rate => death_rate,
        :reinfection_probability => reinfection_probability,
        :migration_intensity => migration_intensity,
        :quarantine_enabled => quarantine_enabled,
        :quarantine_threshold => quarantine_threshold,
        :deaths => 0,
        :step => 0,
        :C => C,
        :city_S => zeros(Int, C),
        :city_I => zeros(Int, C),
        :city_R => zeros(Int, C),
        :city_total => zeros(Int, C),
        :city_force => zeros(Float64, C),
        :city_lambda => zeros(Float64, C),
        :closed_cities => falses(C),
        :closure_times => zeros(Int, C),
        :initial_city_pop => copy(Ns),
        :initial_total => sum(Ns),
    )

    model = StandardABM(
        Person,
        space;
        agent_step! = sir_agent_step!,
        model_step! = sir_model_step!,
        properties,
        rng,
        scheduler = Schedulers.Randomly(),
    )

    for city in 1:C
        infected_left = Is[city]
        for _ in 1:Ns[city]
            status = infected_left > 0 ? :I : :S
            infected_for = status == :I ? rand(rng, 0:max(detection_time - 1, 0)) : 0
            add_agent!(city, model, status, infected_for)
            infected_left -= status == :I ? 1 : 0
        end
    end

    refresh_city_statistics!(model)
    return model
end

function collect_row(model; by_city = false, include_closure = false)
    pairs = Pair{Symbol, Any}[
        :time => model.step,
        :susceptible => count_susceptible(model),
        :infected => count_infected(model),
        :recovered => count_recovered(model),
        :total => count_total(model),
        :deaths => deaths_total(model),
    ]

    if by_city
        for city in 1:model.C
            push!(pairs, Symbol("S_city$(city)") => model.city_S[city])
            push!(pairs, Symbol("I_city$(city)") => model.city_I[city])
            push!(pairs, Symbol("R_city$(city)") => model.city_R[city])
        end
    end

    if include_closure
        for city in 1:model.C
            push!(pairs, Symbol("city$(city)_closed") => Int(model.closed_cities[city]))
        end
    end

    return (; pairs...)
end

function simulate_sir!(model, n_steps; by_city = false, include_closure = false)
    rows = NamedTuple[]
    push!(rows, collect_row(model; by_city, include_closure))
    for _ in 1:n_steps
        step!(model, 1)
        push!(rows, collect_row(model; by_city, include_closure))
    end
    return DataFrame(rows)
end

function summarize_dynamics(df, initial_total)
    infected_share = df.infected ./ initial_total
    recovered_share = df.recovered ./ initial_total
    deaths_share = df.deaths ./ initial_total
    peak_idx = argmax(infected_share)
    return (
        peak = infected_share[peak_idx],
        peak_value = df.infected[peak_idx],
        peak_time = df.time[peak_idx],
        final_inf = infected_share[end],
        final_rec = recovered_share[end],
        death_fraction = deaths_share[end],
        deaths = df.deaths[end],
    )
end
