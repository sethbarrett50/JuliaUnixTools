using Test
using JuliaUnixTools

@testset "LS Function Tests" begin
    # Test the sort_ext function
    @test sort_ext("file.txt") == ".txt"
    @test sort_ext(["file.txt", "notes.log"]) == ".log"

    # Test remove_hidden function
    file_list = [".hidden_file", "visible_file.txt", ".hidden_folder", "file.md"]
    remove_hidden(file_list)
    @test file_list == ["visible_file.txt", "file.md"]

    # Test parse_mtime function (with valid and invalid inputs)
    @test parse_mtime("Sep 24 14:32") == DateTime("Sep 24 14:32 2023", "u d HH:MM Y")
    @test parse_mtime("Sep 24 2022") == DateTime("Sep 24 2022", "u d Y")
    @test parse_mtime("Invalid date") === nothing  # Should return nothing on invalid date
end