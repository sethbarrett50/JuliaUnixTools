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
            help = "Number the lines printed"
            action = :store_true
    end
end

"""
    print_file(args::Dict{String,Any})

    Applys functions appropriate for arguments provided.
""" 
function print_file(args::Dict{String,Any})
    filePath = args["filePath"]

    for file in filePath
        if isdir(file)
            return @printf "cat: %s: Is a directory\n" file
        end

        if args["numLines"]
            lineNum_print(file)
        else
            basic_print(file)
        end
    end
end

"""
    basic_print(filePath::String)

    Function for basic printing of file
"""
function basic_print(filePath::String)
    open(filePath, "r") do f
        for line in readlines(f)
            println(line)
        end
    end
end

"""
    lineNum_print(filePath::String)

    Function for printing of file with line numbers
"""
function lineNum_print(filePath::String)
    open(filePath, "r") do f
        for (i, line) in enumerate(readlines(f))
            @printf "\t%i %s\n" i line
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