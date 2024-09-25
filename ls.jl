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
        
        "--time", "-t"
            help = "Sort files by creation date and time"
            action = :store_true
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

    if args["long"]
        fileStrings = long_formatting(fileStrings, path)

        if args["HumanReadable"]
            fileStrings = h_formatting(fileStrings)
        end

        if args["group"]
            group_removal(fileStrings)
        end

        if args["time"]
            fileStrings = sort(fileStrings, by = sort_time, rev = !args["reverse"])
        end
    end 
    
    if args["extension"]
        fileStrings = sort(fileStrings, by = sort_ext, rev = args["reverse"])

    elseif args["reverse"]
        fileStrings = sort(fileStrings, rev = true)
    end

    output = args["output"]

    if output != "default.txt"
        output_to_file(fileStrings, output)
    else
        print_formatting(fileStrings)
    end
end

"""
    sort_time(fileStrings::Vector{String})

    Sorts the long filestring based on modification time

    # Arguments
    - `fileStrings`: A vector of strings, each representing a file name.
"""
function sort_time(fileString::Vector{String})
    mtime_str = fileString[end-1]
    return parse_mtime(mtime_str)
end

"""
    parse_mtime(mtime_str::String)

    Parses string into DateTime object for proper sorting

    # Arguments:
    - `mtime_str::String`: String to be converted into DateTime Object
"""
function parse_mtime(mtime_str::String)
    now_year = year(now())
    try
        return DateTime("$mtime_str $now_year", "u d HH:MM Y") # Recent mod
    catch e
        try
            return DateTime(mtime_str, "u d Y") # Older mod
        catch e
            println("Error: Could not parse modification time $mtime_str: $e")
            return nothing 
        end
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
    sort_ext(fileString::Union{Vector{String}, String})

    Sorts both long and regular formatted fileString based on file extension

    # Arguments
    - `fileStrings`: Either long or regular formatted fileStrings
"""
function sort_ext(fileString::Union{Vector{String}, String})
    if isa(fileString, Vector{String})
        filename = fileString[end]
    else
        filename = fileString
    end
    return splitext(filename)[2]  
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

        tmpFileStats = safe_stat(filepath)

        mode = get_mode(tmpFileStats.mode, filepath)

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
    get_mode(mode::UInt64, filepath::String)

    Function to get the chmod info about a file in the correct format for long printing.

    # Arguments 
    - `mode::UInt64`: Represents chmod info returned from stat
    - `filepath::String`: Path to file
"""
function get_mode(mode::UInt64, filepath::String)
    file_type = ifelse(isdir(filepath), "d", islink(filepath) ? "l" : "-")
    permissions = [
        (mode & 0o400 != 0 ? "r" : "-"),
        (mode & 0o200 != 0 ? "w" : "-"),
        (mode & 0o100 != 0 ? "x" : "-"),
        (mode & 0o040 != 0 ? "r" : "-"),
        (mode & 0o020 != 0 ? "w" : "-"),
        (mode & 0o010 != 0 ? "x" : "-"),
        (mode & 0o004 != 0 ? "r" : "-"),
        (mode & 0o002 != 0 ? "w" : "-"),
        (mode & 0o001 != 0 ? "x" : "-")
    ]
    return file_type * join(permissions, "")
end

"""
    safe_stat(filepath::String)

    A safe way of getting stats for a file used in long h_formatting.
    Errors may occur if user does not have permission to view a file's stats.

    # Arguments
    - `filepath::String`: String containing path to a file which needs stats extracted
"""
function safe_stat(filepath::String)
    try
        return stat(filepath)
    catch e
        println("Error: Could not get file stats for $filepath: $e")
        return nothing  
    end
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
        file_size = 0
        try
            file_size = parse(Int, fileString[5])
        catch e
            println("Error: Could not parse file size $(fileString[5]): $(e)")
        end
        i = 1

        while file_size >= 1024 && i < length(units)
            file_size /= 1024.0
            i += 1
        end

        fileString[5] = @sprintf("%.0f %s", file_size, units[i])
    end
    return fileStrings
end

"""
    print_formatting(data::Union{Vector{String}, Vector{Vector{String}}})

    Print datas to the standard output, one file per line.
    Works for both regular and long formatting

    # Arguments
    - `data`: Represents either a Vector of Strings or a nested Vector of Strings; works with both.
""" 
function print_formatting(data::Union{Vector{String}, Vector{Vector{String}}})
    for item in data
        if isa(item, Vector)
            println(join(item, "\t"))
        else
            println(item)
        end
    end
end

"""
    output_to_file(data::Union{Vector{String}, Vector{Vector{String}}}, savePath::String)

    File output for data, used for displaying a table of file statistics.
    Works with both long and regular formatted data.
    The data from the fileStrings argument is saved to a file specified with the savePath String.
    Handles exceptions that might occur if permission to write to the file is not available.

    # Arguments
    - `data``: Either a Vector containing Strings or a nested Vector of Strings that need to be written to a file. 
    - `savePath`: A string where the data from fileStrings is saved to
"""
function output_to_file(data::Union{Vector{String}, Vector{Vector{String}}}, savePath::String)
    try
        open(savePath, "w") do file
            for item in data
                if isa(item, Vector)
                    write(file, join(item, "\t"))
                else
                    write(file, item)
                end
                write(file, "\n")
            end
        end
    catch e
        println("Error: Could not write to file $savePath: $e")
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

    print_formatting(args)
end

main()