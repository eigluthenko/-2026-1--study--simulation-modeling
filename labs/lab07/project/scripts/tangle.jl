#!/usr/bin/env julia

using DrWatson
@quickactivate "project"

using Literate

function main()
    scripts = isempty(ARGS) ? [
        scriptsdir("mmc_literate.jl"),
        scriptsdir("mmc_parameters_literate.jl"),
        scriptsdir("ross_literate.jl"),
        scriptsdir("ross_parameters_literate.jl"),
    ] : ARGS

    mkpath(projectdir("scripts"))
    mkpath(projectdir("docs"))
    mkpath(projectdir("notebooks"))

    for script_path in scripts
        isfile(script_path) || error("file not found: $script_path")
        stem = splitext(basename(script_path))[1]
        name = replace(stem, "_literate" => "")
        Literate.script(script_path, scriptsdir(); name = "$(name)_clean", credit = false)
        Literate.notebook(script_path, projectdir("notebooks"); name = name, execute = true, credit = false)
        Literate.markdown(script_path, projectdir("docs"); name = name, credit = false)
        println("generated for $name")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
