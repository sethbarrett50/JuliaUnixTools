using Pkg
Pkg.activate("."; io=devnull)
Pkg.instantiate()
using ArgParse
using Printf
using Dates

"""
    setup_args()

    Sets table of arguments that can be processed
"""
function setup_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "path"
            help = "Path to list"
            default = "." 

        "-l", "--long"
            help = "List files in the long format"
            action = :store_true
        
        "--HumanReadable", "-H"
            help = "Returns values in human readable format"
            action = :store_true

        "--output", "-o"
            help = "Output file name"
            action = :store_arg
            default = "default.txt"
        
        "--all", "-a"
            help = "Displays hidden files"
            action = :store_true
        
        "--comma", "-m"
            help = "Displays files separated by commas"
            action = :store_true

        "--group", "-g"
            help = "Ommits group ownership column"
            action = :store_true

        "--reverse", "-r"
            help = "Sort files in reverse"
            action = :store_true
        
        "--extension", "-X"
            help = "Sort files alphabetically by file extension"
            action = :store_true
        
        # "--time", "-t"
        #     help = "Sort files by creation date and time"
    end
end

"""
    print_formatting(args::Dict{String,Any})

    Applys functions to input appropriate for arguments provided.
""" 
function print_formatting(args::Dict{String,Any})
    path = args["path"]
    fileStrings = cd(readdir, path)

    if !args["all"]
        remove_hidden(fileStrings)
    end

    if args["comma"]
        return println(join(fileStrings, ", "))
    end

    output = args["output"]

    if args["long"]
        fileStrings = long_formatting(fileStrings, path)

        if args["HumanReadable"]
            fileStrings = h_formatting(fileStrings)
        end

        if args["group"]
            group_removal(fileStrings)
        end

        if args["reverse"] && args["extension"]
            fileStrings = sort(fileStrings, by = sort_ext, rev = true)
        elseif args["reverse"]
            fileStrings = sort(fileStrings, by = sort_reverse, rev = true)
        elseif args["extension"]
            fileStrings = sort(fileStrings, by = sort_ext)
        end
    else
        if args["reverse"] && args["extension"]
            fileStrings = sort(fileStrings, by = sort_ext, rev = true)
        elseif args["reverse"]
            fileStrings = sort(fileStrings, rev = true)
        elseif args["extension"]
            fileStrings = sort(fileStrings, by = sort_ext)
        end

    end


    if output != "default.txt"
        output_to_file(fileStrings, output)
    else
        print_formatting(fileStrings)
    end
end

"""
    sort_reverse(fileStrings::Vector{String})

    Sorts the long filestring in reverse

    # Arguments
    - `fileStrings`: A vector of strings, each representing a file name.
"""
function sort_reverse(fileString::Vector{String})
    filename = fileString[end]
end   

"""
    sort_ext(fileStrings::Vector{String})

    Sorts the long filestring based on file extension

    # Arguments
    - `fileStrings`: A vector of strings, each representing a file name.
"""
function sort_ext(fileString::Vector{String})
    filename = fileString[end]
    splitext(filename)[2]
end

"""
    sort_ext(fileStrings::Vector{String})

    Sorts the regular filestring based on extension

    # Arguments
    - `fileStrings`: A Strings containing name of one file.
"""
function sort_ext(fileString::String)
    return splitext(fileString)[2]
end

"""
    remove_hidden(fileStrings::Vector{String})

    Removes any hidden files that start with `.`
    This is only applied when the all option is not present

    # Arguments
    - `fileStrings`: A vector of strings, each representing a file name.
"""
function remove_hidden(fileStrings::Vector{String})
    filter!(!startswith("."), fileStrings)
end

"""
    group_removal(fileStrings::Vector{Vector{String}})

    Removes the group column from each file's filestats vector

    # Arguments
    - `fileStats`: A vector of vectors, where each inner vector contains strings representing individual file statistics
"""
function group_removal(fileStrings::Vector{Vector{String}})
    for fileString in fileStrings
        deleteat!(fileString, 4)
    end
end

"""
    long_formatting(fileStrings::Vector{String})

    Obtains information needed for long printing. 
    Function formats and returns this information in a vector of vectors of strings.

    # Arguments
    - `fileStrings`: A vector of strings, each representing a file name.

    # Returns
    - `fileStats`: A vector of vectors, where each inner vector contains strings representing individual file statistics
""" 
function long_formatting(fileStrings::Vector{String}, lsPath::String)
    fileStats = Vector{Vector{String}}()
    for fileString in fileStrings
        if lsPath == ".."
            filepath = lsPath * "/" * fileString
        elseif lsPath != "."
            filepath = lsPath * fileString
        else
            filepath = fileString
        end

        tmpFileStats = stat(filepath)

        mode = tmpFileStats.mode
        file_type = ifelse(isdir(filepath), "d", islink(filepath) ? "l" : "-")
    
        permissions = [
            (mode & 0o400 != 0 ? "r" : "-"),  # Owner read
            (mode & 0o200 != 0 ? "w" : "-"),  # Owner write
            (mode & 0o100 != 0 ? "x" : "-"),  # Owner execute
            (mode & 0o040 != 0 ? "r" : "-"),  # Group read
            (mode & 0o020 != 0 ? "w" : "-"),  # Group write
            (mode & 0o010 != 0 ? "x" : "-"),  # Group execute
            (mode & 0o004 != 0 ? "r" : "-"),  # Others read
            (mode & 0o002 != 0 ? "w" : "-"),  # Others write
            (mode & 0o001 != 0 ? "x" : "-")   # Others execute
        ]
        mode = file_type * join(permissions, "")

        push!(
            fileStats, 
            [
                mode, 
                string(tmpFileStats.nlink), 
                string(tmpFileStats.uid), 
                string(tmpFileStats.gid), 
                string(tmpFileStats.size), 
                string(format_mtime(tmpFileStats.mtime)), 
                fileString
            ]
        )
    end
    return fileStats
end

"""
    format_mtime(mtime::Float64)

    Converts Unix time to datetime.
    Returns value in format of time in ls -l.

    # Arguments
    - `mtime`: A Float64 value representing Unix time.

    # Returns
    -  A vector of vectors, where each inner vector contains strings representing individual file statistics
""" 
function format_mtime(mtime::Float64)
    mtime = unix2datetime(mtime)
    now_time = now()  
    six_months_ago = now_time - Month(6) 
    
    if mtime < six_months_ago
        return Dates.format(mtime, "u d Y")
    else
        return Dates.format(mtime, "u d HH:MM")
    end
end

"""
    h_formatting(fileStrings::Vector{Vector{String}})

    Formats data for nested vectors, used for displaying a table of file statistics.
    Each inner vector represents a row of data, and each element of an inner vector is printed in a tab-separated format on a new line.
    Converts values in the inner vectors into human readable format.

    # Arguments
    - `fileStrings`: A vector of vectors, where each inner vector contains strings representing individual file statistics

    # Returns
    - `fileStrings`: A vector of vectors, where each inner vector contains strings representing individual file statistics, with byte size converted into human readable format
"""
function h_formatting(fileStrings::Vector{Vector{String}})
    units = ["B", "KB", "MB", "GB", "TB", "PB"]
    for fileString in fileStrings
        size = parse(Int, fileString[5])
        i = 1

        while size >= 1024 && i < length(units)
            size /= 1024.0
            i += 1
        end

        fileString[5] = @sprintf("%.0f %s", size, units[i])
    end
    return fileStrings
end

"""
    print_formatting(fileStrings::Vector{String})

    Print each string in the given vector of files to the standard output, one per line. This is the base case for ls without arguments

    # Arguments
    - `fileStrings`: A vector of strings, each representing a file name.
""" 
function print_formatting(fileStrings::Vector{String})
    for fileString in fileStrings
        @printf "%s\t" fileString
    end
    println()
end

"""
    print_formatting(fileStrings::Vector{Vector{String}})

    Print formatted output for nested vectors, used for displaying a table of file statistics.
    Each inner vector represents a row of data, and each element of an inner vector is printed in a tab-separated format on a new line.

    # Arguments
    - `fileStrings`: A vector of vectors, where each inner vector contains strings representing individual file statistics
"""
function print_formatting(fileStrings::Vector{Vector{String}})
    for filestats in fileStrings
        for filestat in filestats
            @printf "%s\t" filestat
        end
        println()
    end
end

"""
    output_to_file(fileStrings::Vector{Vector{String}}, savePath::String)

    File output for nested vectors, used for displaying a table of file statistics.
    Each inner vector represents a row of data, and each element of an inner vector is saved in a tab-separated format on a new line.
    The data from the fileStrings argument is saved to a file specified with the savePath String.

    # Arguments
    - `fileStrings`: A vector of vectors, where each inner vector contains strings representing individual file statistics
    - `savePath`: A string where the data from fileStrings is saved to
"""
function output_to_file(fileStrings::Vector{String}, savePath::String)
    open(savePath, "w") do file
        for fileString in fileStrings
            write(file, fileString)
            write(file, "\n")
        end
    end
end

"""
    output_to_file(fileStrings::Vector{String}, savePath::String)

    File output for vectors, used for displaying a table of file names.
    Each element of the vector is saved on a new line.
    The data from the fileStrings argument is saved to a file specified with the savePath String.

    # Arguments
    - `fileStrings`: A vector containing strings representing individual file statistics
    - `savePath`: A string where the data from fileStrings is saved to
"""
function output_to_file(fileStrings::Vector{Vector{String}}, savePath::String)
    open(savePath, "w") do file
        for fileStats in fileStrings
            for fileStat in fileStats
                write(file, fileStat)
                write(file, "\t")
            end
            write(file, "\n")
        end
    end
end 

function main()
    args = parse_args(setup_args())

    print_formatting(args)
end

main()