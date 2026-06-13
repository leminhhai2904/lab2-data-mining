using Test
using Random

# Include src components relative to test folder
include("../src/structures.jl")
include("../src/algorithm/genmax.jl")

using .Structures
using .GenMaxAlgo

@testset "GenMax Correctness Tests" begin
    Random.seed!(42)
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
        mfi_sets = [Set(r[1]) for r in res3]

        # Kiểm tra sự tồn tại của các MFI đã biết cho minsup = 3
        @test Set(["A", "C", "T", "W"]) in mfi_sets
        @test Set(["C", "D", "W"]) in mfi_sets

        # Để test {A, C, W} như comment cũ, ta dùng minsup = 4
        res4 = genmax(toy_data, 4)
        mfi_sets4 = [Set(r[1]) for r in res4]
        @test Set(["A", "C", "W"]) in mfi_sets4
    end
end
