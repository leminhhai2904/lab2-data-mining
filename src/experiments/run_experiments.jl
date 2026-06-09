using Printf
using CSV
using DataFrames

# Trỏ về module utils.jl & genmax.jl
include(joinpath(@__DIR__, "..", "structures.jl"))
include(joinpath(@__DIR__, "..", "utils.jl"))
include(joinpath(@__DIR__, "..", "algorithm", "genmax.jl"))

using .Structures
using .Utils
using .GenMaxAlgo

function get_memory_mb()
    # Lấy thông tin bộ nhớ đang sử dụng bởi GC (mức cơ bản).
    # Để đo RAM chuẩn xác như psutil cần dùng Sys.maxrss() nếu trên Unix 
    # Nhưng trên Windows Base.gc_live_bytes() là cách ước lượng tốt nhất.
    GC.gc()
    return Base.gc_live_bytes() / (1024^2)
end

function run_experiment(dataset_path::String, minsup_list::Vector{String}, output_dir="results")
    if !isdir(output_dir)
        mkpath(output_dir)
    end
    
    dataset_name = splitext(basename(dataset_path))[1]
    println("\n", "="^80)
    println("ĐANG CHẠY THỰC NGHIỆM TRÊN: $(uppercase(dataset_name))")
    println("="^80)
    
    data = read_spmf_file(dataset_path)
    n_trans = length(data)
    
    # Bảng đánh giá
    records = DataFrame(dataset=String[], minsup=String[], minsup_abs=Int[], num_mfi=Int[], time_ms=Float64[], peak_mem_mb=Float64[])
    
    for minsup_str in minsup_list
        GC.gc()
        mem_before = get_memory_mb()
        
        minsup_abs = 0
        if endswith(minsup_str, "%")
            p = parse(Float64, minsup_str[1:end-1]) / 100.0
            minsup_abs = max(1, floor(Int, n_trans * p))
        else
            minsup_abs = parse(Int, minsup_str)
        end
        
        try
            start_time = time_ns()
            results = genmax(data, minsup_abs)
            elapsed_ms = (time_ns() - start_time) / 1e6
            
            mem_peak = get_memory_mb() - mem_before
            mem_peak = max(mem_peak, 0.0)
            
            push!(records, (dataset_name, minsup_str, minsup_abs, length(results), elapsed_ms, mem_peak))
            @printf("✓ %-6s | MFI: %-4d | Time: %8.1f ms | Mem ước lượng: %6.1f MB\n", minsup_str, length(results), elapsed_ms, mem_peak)
            
        catch e
            println("✗ Lỗi $minsup_str: ", e)
        end
    end
    
    csv_path = joinpath(output_dir, "$(dataset_name)_experiment.csv")
    CSV.write(csv_path, records)
    println("✅ Hoàn thành $dataset_name → $csv_path")
end

if abspath(PROGRAM_FILE) == @__FILE__
    minsup_values = ["50%", "30%", "20%", "10%", "5%"]
    datasets = [
        "data/benchmark/chess.dat",
        "data/benchmark/mushroom.dat"
        # Thêm retail hoặc các dataset khác ở đây
    ]
    
    for ds in datasets
        ds_path = joinpath(@__DIR__, "..", "..", ds)
        if isfile(ds_path)
            run_experiment(ds_path, minsup_values)
        else
            println("Không tìm thấy: $ds_path")
        end
    end
end
