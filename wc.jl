using Pkg
Pkg.activate("."; io=devnull)
using ArgParse
using Printf

"""
    setup_args()

    Sets table of arguments that can be processed
"""
function setup_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "filePath"
            help = "Path(s) to list"
            nargs = '+'
            arg_type = String
            required = true

        "--lineNum", "-l"
            help = "Number the lines in each input file"
            action = :store_true
        
        "--countBytes", "-c"
            help = "Number the bytes in each input file"
            action = :store_true

        "--characterNum", "-m"
            help = "Number the characters in each input file"
            action = :store_true

        "--wordNum", "-w"
            help = "Number the words in each input file"
            action = :store_true
    end
end

"""
    wc(args::Dict{String,Any})

    Processes word counts for multiple files and prints the results.
    If more than one file is provided, adds a total summary at the end.

    # Arguments 
    - `args::Dict{String,Any}`: Dictionary provided by arguments
"""
function wc(args::Dict{String,Any})
    wcValues = fileStats = Vector{NamedTuple}()
    for file in args["filePath"]
        push!(wcValues, process_wc(file))
    end

    if length(args["filePath"]) > 1
        push!(wcValues, process_total(wcValues))
    end

    print_wc(wcValues, args)
end

"""
    process_wc(filePath::String)

    Gets the wcValues for a file specified at filePath

    # Arguments
    - `filePath::String`: String containing file path to file needing wcValues extracted from
"""
function process_wc(filePath::String)
    open(filePath, "r") do f
        content = read(f, String)
        num_lines = count(c -> c == '\n', content) + 1
        num_words = length(split(content))
        num_chars = length(content)
        num_bytes = filesize(filePath)
        return (
            lines = num_lines, 
            words = num_words, 
            chars = num_chars, 
            bytes = num_bytes, 
            filename = filePath
        )
    end
end

"""
    process_total(wcValues::Vector{NamedTuple})

    Used in getting total row for wc with multiple files

    # Arguments
    - `wcValues::Vector{NamedTuple}`: Contains wcValues for all files provided in arguments
"""
function process_total(wcValues::Vector{NamedTuple})
    total_lines = sum(wc -> wc.lines, wcValues)
    total_words = sum(wc -> wc.words, wcValues)
    total_chars = sum(wc -> wc.chars, wcValues)
    total_bytes = sum(wc -> wc.bytes, wcValues)

    return (
        lines = total_lines, 
        words = total_words, 
        chars = total_chars, 
        bytes = total_bytes, 
        filename = "total"
    )
end    

"""
    print_wc(wcValues::Vector{NamedTuple}, args::Dict{String, Any})

    Printing function that works with all argument types and number of files

    # Arguments
    - `wcValues::Vector{NamedTuple}`: Contains named tuple with wcvalues for all files and total
    - `args::Dict{String, Any}`: Arguments dictionary used in determining which wcvalues to print
"""
function print_wc(wcValues::Vector{NamedTuple}, args::Dict{String, Any})
    for line in wcValues
        output = ""

        noArgs = !args["lineNum"] && !args["countBytes"] && !args["characterNum"] && !args["wordNum"]

        if args["lineNum"] || noArgs
            output *= "\t$(line.lines)"
        end

        if args["wordNum"] || noArgs
            output *= "\t$(line.words)"
        end

        if args["countBytes"] || noArgs
            output *= "\t$(line.bytes)"
        end

        if args["characterNum"]
            output *= "\t$(line.chars)"
        end

        output *= " $(line.filename)"

        println(output)
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

    wc(args)
end

main()