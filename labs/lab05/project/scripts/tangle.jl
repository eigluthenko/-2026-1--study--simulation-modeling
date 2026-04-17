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
        isfile(script_path) || error("file not found: $script_path")
        script_name = splitext(basename(script_path))[1]
        out_scripts = scriptsdir(script_name)
        out_notebooks = projectdir("notebooks", script_name)
        out_docs = projectdir("docs", script_name)

        mkpath(out_scripts)
        mkpath(out_notebooks)
        mkpath(out_docs)

        Literate.script(script_path, out_scripts; credit = false)
        Literate.notebook(
            script_path,
            out_notebooks;
            name = script_name,
            execute = false,
            credit = false,
        )
        Literate.markdown(
            script_path,
            out_docs;
            name = script_name,
            flavor = Literate.QuartoFlavor(),
            credit = false,
        )

        println("generated for $script_name")
        println("  script   -> $(joinpath(out_scripts, script_name * ".jl"))")
        println("  notebook -> $(joinpath(out_notebooks, script_name * ".ipynb"))")
        println("  quarto   -> $(joinpath(out_docs, script_name * ".qmd"))")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
