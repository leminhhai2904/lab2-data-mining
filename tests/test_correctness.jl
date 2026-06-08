using Test

# Include src components relative to test folder
include("../src/structures.jl")
include("../src/algorithm/genmax.jl")

using .Structures
using .GenMaxAlgo

@testset "GenMax Correctness Tests" begin
    @testset "Toy Data - Fig 1 GenMax Paper" begin
        # Dataset từ bài báo gốc
        toy_data = [
            ["A", "C", "T", "W"],
            ["C", "D", "W"],
            ["A", "C", "T", "W"],
            ["A", "C", "D", "W"],
            ["A", "C", "D", "T", "W"],
            ["C", "D", "T"]
        ]
        
        # Test minsup = 3
        res3 = genmax(toy_data, 3)
        @test typeof(res3) <: Vector
        @test length(res3) > 0
        
        # Chuyển đổi định dạng cho dễ test
        # res3 thường có định dạng Vector{Tuple{Vector{String}, Int}}
        mfi_sets = [Set(r[1]) for r in res3]
        
        # Kiểm tra sự tồn tại của MFI: {A,C,W} có support 3 (gọi trong paper)
        @test Set(["A", "C", "W"]) in mfi_sets
    end
end
