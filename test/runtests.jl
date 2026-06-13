using Test

@testset "All Tests" begin
    @eval module TestCorrectness
    include("test_correctness.jl")
    end
    @eval module TestBenchmark
    include("test_benchmark.jl")
    end
end
