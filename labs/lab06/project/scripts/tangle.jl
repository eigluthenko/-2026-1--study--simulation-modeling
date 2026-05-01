#!/usr/bin/env julia

using DrWatson
@quickactivate "project"

using Literate

function main()
    scripts = isempty(ARGS) ? [
        scriptsdir("sirpetri_run.jl"),
        scriptsdir("sirpetri_scan_parameters.jl"),
        scriptsdir("sirpetri_animate.jl"),
        scriptsdir("sirpetri_report.jl"),
    ] : ARGS

    for script_path in scripts
        isfile(script_path) || error("file not found: $script_path")
        script_name = splitext(basename(script_path))[1]
        out_scripts = scriptsdir(script_name)
        out_notebooks = projectdir("notebooks", script_name)
        out_docs = projectdir("docs", script_name)

        mkpath(out_scripts)
        mkpath(out_notebooks)
        mkpath(out_docs)

        Literate.script(script_path, out_scripts; credit = false)
        Literate.notebook(script_path, out_notebooks; name = script_name, execute = false, credit = false)
        Literate.markdown(script_path, out_docs; name = script_name, flavor = Literate.QuartoFlavor(), credit = false)

        println("generated for $script_name")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
