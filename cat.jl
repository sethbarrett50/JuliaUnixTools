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
            help = "Path to list"
            default = "./default.txt" 

        "--numLines", "-n"
            help = "Number the lines printed"
            action = :store_true
    end
end

"""
    print_file(args::Dict{String,Any})

    Applys functions to input appropriate for arguments provided.
""" 
function print_file(args::Dict{String,Any})
    filePath = args["filePath"]

    if isdir(filePath)
        return @printf "cat: %s: Is a directory\n" filePath
    end

    if args["numLines"]
        lineNum_print(filePath)
    else
        basic_print(filePath)
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

function main()
    args = parse_args(setup_args())

    print_file(args)
end

main()