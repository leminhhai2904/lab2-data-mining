using Test

include("../src/structures.jl")
include("../src/algorithm/genmax.jl")
include("../src/utils.jl")

using .Structures
using .GenMaxAlgo
using .Utils

@testset "GenMax Benchmark Tests" begin
    # Danh sách 5 CSDL kiểm thử (Bạn phải tải thêm T1014D100K)
    datasets = ["chess.dat", "mushroom.dat", "retail.dat", "accidents.dat", "T1014D100K.dat"]
    
    for ds_name in datasets
        filepath = joinpath(@__DIR__, "..", "data", "benchmark", ds_name)
        
        @testset "Test on $ds_name" begin
            if isfile(filepath)
                # Sử dụng hàm read_spmf_file từ src/utils.jl
                data = read_spmf_file(filepath)
                
                # Chạy thuật toán với threshold tương đối chẳng hạn 0.8 cho thử nghiệm nhỏ
                # (Với dataset lớn, cần chỉnh lại minsup phù hợp tránh tràn RAM)
                res = genmax(data, 0.8) 
                
                # Test kiểm tra mảng kết quả là Vector
                @test typeof(res) <: Vector
                
                # Gọi write mẫu ra thư mục tạm
                tmp_out = joinpath(@__DIR__, "out_$ds_name")
                write_spmf_file(res, tmp_out)
                @test isfile(tmp_out)
                
                # Dọn dẹp
                rm(tmp_out, force=true)
            else
                @warn "Dataset $ds_name không tồn tại, bạn cần tải về thư mục data/benchmark"
                @test_skip true # Báo hiệu bị bỏ qua
            end
        end
    end
end
