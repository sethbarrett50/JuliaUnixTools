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

        "--numLines", "-n"
            help = "Number of lines to be printed"
            default = 10
            arg_type = Int
            action = :store_arg
    end
end

"""
    print_file(args::Dict{String,Any})

    Applys functions to input appropriate for arguments provided.
""" 
function print_file(args::Dict{String,Any})
    filePath = args["filePath"]

    for file in filePath
        if isdir(file)
            return @printf "tail: %s: Is a directory\n" file
        end
        
        lineNum_print(file, args["numLines"])
    end
end

"""
    lineNum_print(filePath::String)

    Function for printing of file for a certain number of lines from bottom
"""
function lineNum_print(filePath::String, numLines::Int)
    open(filePath, "r") do f
        lines = readlines(f)
        start_line = max(1, length(lines) - numLines + 1)  # Calculate the starting point
        for line in lines[start_line:end]
            println(line)
        end
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

    print_file(args)
end

main()