using Test
using JuliaUnixTools

@testset "LS Tests" begin
    @test sort_ext("file.txt") == ".txt"
    @test sort_ext(["file.txt", "notes.log"]) == ".log"
    @testset "Hidden File Removal" begin
        files = [".hidden", "visible.txt"]
        remove_hidden(files)
        @test files == ["visible.txt"]
    end
end