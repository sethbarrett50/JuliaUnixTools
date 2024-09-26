using Pkg
Pkg.activate("."; io=devnull)
using ArgParse
using Printf

const RED = "\e[31m"
const RESET = "\e[0m"

"""
    setup_args()

    Sets table of arguments that can be processed
"""
function setup_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "pattern"
            help = "Pattern to search for"
            arg_type = String
            required = true

        "filePath"
            help = "Path(s) to list"
            nargs = '+'
            arg_type = String
            required = true

        "-i", "--ignore-case"
            help = "Ignore case distinctions"
            action = :store_true
        
        "-v", "--invert-match"
            help = "Invert match, select non-matching lines"
            action = :store_true

        "-c", "--count"
            help = "Only print a count of matching lines"
            action = :store_true
        
        "-n", "--line-number"
            help = "Print line numbers with output lines"
            action = :store_true

        "-o", "--only-matching"
            help = "Print only the matching part of the line"
            action = :store_true

        "-r", "--recursive"
            help = "Recursively search directories"
            action = :store_true

        "-C", "--color"
            help = "Prints matches in red"
            action = :store_true
    end
end

"""
    grep(args::Dict{String,Any})

    Applys functions appropriate for arguments provided.
""" 
function grep(args::Dict{String, Any})
    pattern = args["ignore-case"] ? Regex(args["pattern"], "i") : Regex(args["pattern"])

    for file in args["filePath"]
        search_dir_or_file(file, pattern, args)
    end
end

"""
    search_dir_or_file(path::String, pattern::Regex, args::Dict{String, Any})

    Searches path and applies differing functionality if its a directory or a file

    # Arguments
    - `path::String`: String of path provided in argument
    - `pattern::Regex`: Regex pattern adjusted if ignore-case or not
    - `args::Dict{String, Any}`: Arguments dictionary
"""
function search_dir_or_file(path::String, pattern::Regex, args::Dict{String, Any})
    if isdir(path)
        if args["recursive"]
            search_dir(path, pattern, args)
        else
            println("Skipping directory $(path). Use --recursive to search directories.")
        end
    elseif isfile(path)
        search_file(path, pattern, args)
    else
        println("Invalid path: $(path)")
    end
end

"""
    search_dir(dir::String, pattern::Regex, args::Dict{String, Any})

    Searches directory to find more files to search

    # Arguments
    - `dir::String`: String of directory path
    - `pattern::Regex`: Regex pattern adjusted if ignore-case or not
    - `args::Dict{String, Any}`: Arguments dictionary
"""
function search_dir(dir::String, pattern::Regex, args::Dict{String, Any})
    for (root, _, files) in walkdir(dir)
        for file in files
            filepath = joinpath(root, file)
            search_file(filepath, pattern, args)
        end
    end
end

"""
    highlight_match(line::String, pattern::Regex)

    Replaces text that matches pattern with red colored text

    # Arguments
    - `line::String`: String of line to search
    - `pattern::Regex`: Regex pattern adjusted if ignore-case or nots
"""
function highlight_match(line::String, pattern::Regex)
    m = match(pattern, line)
    if m !== nothing
        return replace(line, m.match => RED * m.match * RESET)
    end
end

"""
    search_file(fileName::String, pattern::Regex, args::Dict{String, Any})

    Searches file for matches to pattern

    # Arguments
    - `fileName::String`: String of file path
    - `pattern::Regex`: Regex pattern adjusted if ignore-case or not
    - `args::Dict{String, Any}`: Arguments dictionary
"""
function search_file(fileName::String, pattern::Regex, args::Dict{String, Any})
    open(fileName, "r") do file
        count = 0
        for (i, line) in enumerate(eachline(file))
            if match_pattern(line, pattern, args)
                if args["count"]
                    count += 1
                else
                    if args["line-number"]
                        print("$(i): ")
                    end
                    if args["color"]
                        println(highlight_match(line, pattern))
                    else
                        println(line)
                    end
                end
            end
        end
        if args["count"] && count > 0
            println("$(fileName): $count matches")
        end
    end
end

"""
    match_pattern(line::String, pattern::Regex, args::Dict{String, Any})

    Searches line for matches to pattern

    # Arguments
    - `line::String`: String of line to search
    - `pattern::Regex`: Regex pattern adjusted if ignore-case or not
    - `args::Dict{String, Any}`: Arguments dictionary
"""
function match_pattern(line::String, pattern::Regex, args::Dict{String, Any})
    if args["invert-match"]
        return !occursin(pattern, line)
    else
        return occursin(pattern, line)
    end
end

"""
    safe_parse_args(setup_args_function)

    Added in order to catch any issues when trying to parse arguments that ArgParse may have missed.
"""
function safe_parse_args(setup_args_function)
    try
        return parse_args(setup_args_function())
    catch e
        println("Error: Invalid arguments provided: $e")
        return nothing 
    end
end

function main()
    args = safe_parse_args(setup_args)

    grep(args)
end

main()