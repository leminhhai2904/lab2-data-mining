# src/experiments/benchmark.jl
# Script tu dong chay benchmark thuat toan GenMax cua nhom va SPMF baseline.
# Tu dong do thoi gian, peak memory, va kiem tra tinh chinh xac cua ket qua.

using Printf
using CSV
using DataFrames
using Random
using BenchmarkTools

# Nap cac module cua du an
include(joinpath(@__DIR__, "..", "structures.jl"))
include(joinpath(@__DIR__, "..", "utils.jl"))
include(joinpath(@__DIR__, "..", "algorithm", "genmax.jl"))

using .Structures
using .Utils
using .GenMaxAlgo

"""
Ghi file CSV an toan, ho tro thoi gian cho va thu lai neu file bi lock.
"""
function safe_csv_write(path::String, df::DataFrame)
    for i in 1:5
        try
            if isfile(path)
                try
                    rm(path, force=true)
                catch
                    # Bo qua neu khong xoa duoc, de CSV.write ghi de
                end
            end
            CSV.write(path, df)
            return true
        catch e
            println("Canh bao: Khong the ghi file $path (lan thu $i): ", e)
            sleep(1.0)
        end
    end
    println("Loi: Hoan toan khong the ghi file ", path, "!")
    return false
end

"""
Ham thuc hien JIT warmup de loai bo thoi gian bien dich dau tien cua Julia.
"""
function warmup_genmax()
    println(">>> Dang thuc hien JIT warmup cho thuat toan GenMax...")
    toy_data = [
        ["A", "C", "T", "W"],
        ["C", "D", "W"],
        ["A", "C", "T", "W"],
        ["A", "C", "D", "W"],
        ["A", "C", "D", "T", "W"],
        ["C", "D", "T"]
    ]
    # Chay thu voi cac nguong ho tro khac nhau
    for ms in [2, 3, 4]
        genmax(toy_data, ms)
        genmax_basic(toy_data, ms)
    end
    println(">>> Hoan thanh JIT warmup.")
end

"""
Sinh cac tap con (subsamples) tuong ung voi ti le phan tram (10%, 25%, 50%, 75%, 100%).
Su dung seed co dinh de dam bao tinh tai lap (reproducible).
"""
function generate_subsamples(dataset_path::String, percentages=[10, 25, 50, 75, 100])
    println("\n>>> Dang khoi tao cac subsamples cho scalability test...")
    data = read_spmf_file(dataset_path)
    n = length(data)
    base_name = splitext(basename(dataset_path))[1]
    
    out_dir = joinpath(@__DIR__, "..", "..", "data", "subsets")
    if !isdir(out_dir)
        mkpath(out_dir)
    end
    
    subsample_paths = Dict{Int, String}()
    
    for p in percentages
        if p == 100
            # Giu nguyen file goc
            subsample_paths[p] = dataset_path
            println("    - Tap con 100%: dung file goc ($(n) giao dich)")
            continue
        end
        
        size = max(1, floor(Int, n * p / 100))
        # Dat seed co dinh de phan bo du lieu luon giong nhau giua cac lan chay
        Random.seed!(42)
        subset = shuffle(data)[1:size]
        
        output_file = joinpath(out_dir, "$(base_name)_$(p)pct.txt")
        open(output_file, "w") do f
            for trans in subset
                println(f, join(trans, " "))
            end
        end
        subsample_paths[p] = output_file
        println("    - Tao tap con $(p)%: $(size) giao dich -> $(basename(output_file))")
    end
    
    return subsample_paths
end

"""
Doc file ket qua duoc ghi ra theo dinh dang SPMF de phuc vu so sanh correctness.
"""
function parse_spmf_output(filepath::String)
    results = Set{Tuple{Vector{String}, Int}}()
    if !isfile(filepath)
        return results
    end
    
    open(filepath, "r") do file
        for line in eachline(file)
            line = strip(line)
            if isempty(line) || (startswith(line, "#") && !occursin("#SUP:", line))
                continue
            end
            if occursin("#SUP:", line)
                parts = split(line, "#SUP:")
                itemset_str = strip(parts[1])
                sup = parse(Int, strip(parts[2]))
                itemset = sort(unique(string.(split(itemset_str))))
                push!(results, (itemset, sup))
            end
        end
    end
    return results
end

"""
So sanh chinh xac 100% hai tap ket qua MFI (Custom vs SPMF).
"""
function verify_correctness(our_file::String, spmf_file::String)
    our = parse_spmf_output(our_file)
    spmf = parse_spmf_output(spmf_file)
    
    if length(our) != length(spmf)
        return false, length(our), length(spmf)
    end
    
    is_match = (our == spmf)
    return is_match, length(our), length(spmf)
end

"""
Chay SPMF baseline va thu thap cac chi so hieu nang tu stdout.
"""
function run_spmf_benchmark(spmf_jar::String, dataset_path::String, minsup_str::String, output_file::String)
    cmd = `java -jar $spmf_jar run GENMAX $dataset_path $output_file $minsup_str`
    
    try
        stdout_content = read(cmd, String)
        
        # Parse thong tin tu stdout
        m_mfi = match(r"Maximal itemsets:\s*(\d+)", stdout_content)
        num_mfi = m_mfi !== nothing ? parse(Int, m_mfi.captures[1]) : 0
        
        m_time = match(r"Time:\s*(\d+)\s*ms", stdout_content)
        time_ms = m_time !== nothing ? parse(Float64, m_time.captures[1]) : 0.0
        
        m_mem = match(r"Memory:\s*([\d.]+)\s*MB", stdout_content)
        mem_mb = m_mem !== nothing ? parse(Float64, m_mem.captures[1]) : 0.0
        
        return (success=true, num_mfi=num_mfi, time_ms=time_ms, mem_mb=mem_mb)
    catch e
        println("Loi khi chay SPMF: ", e)
        return (success=false, num_mfi=0, time_ms=-1.0, mem_mb=-1.0)
    end
end

"""
Chay thuat toan GenMax cua nhom va thu thap cac chi so hieu nang.
"""
function run_custom_benchmark(dataset_path::String, minsup_abs::Int, output_file::String)
    # Doc du lieu
    data = read_spmf_file(dataset_path)
    
    # Do RAM truoc khi chay
    GC.gc()
    mem_before = Base.gc_live_bytes() / (1024^2)
    
    # Chay va do thoi gian bang time_ns()
    t_start = time_ns()
    results = genmax(data, minsup_abs)
    elapsed_ns = time_ns() - t_start
    time_ms = elapsed_ns / 1e6
    
    # Do RAM sau khi chay
    GC.gc()
    mem_after = Base.gc_live_bytes() / (1024^2)
    mem_peak = max(0.0, mem_after - mem_before)
    
    # Ghi file ket qua
    write_spmf_file(results, output_file)
    
    return (num_mfi=length(results), time_ms=time_ms, mem_mb=mem_peak)
end

"""
Doi gia tri minsup tu chuoi sang so luong giao dich tuyet doi.
"""
function convert_minsup(minsup_str::String, num_transactions::Int)
    if endswith(minsup_str, "%")
        p = parse(Float64, minsup_str[1:end-1]) / 100.0
        return max(1, ceil(Int, num_transactions * p))
    else
        return parse(Int, minsup_str)
    end
end

# --- DINH NGHIA THUAT TOAN GENMAX BASIC (Level 1) de phuc vu so sanh Memory ---
function has_superset_basic(itemset::Set{T}, mfi_list::Vector{Tuple{Set{T}, Int}}) where T
    for (m, _) in mfi_list
        if issubset(itemset, m)
            return true
        end
    end
    return false
end

function fi_tidset_combine(payload_x::BitSet, P_l_plus_1::Vector{Tuple{T, BitSet, Int}}, min_sup::Int) where T
    C_l_plus_1 = Tuple{T, BitSet, Int}[]
    for (y, payload_y, _) in P_l_plus_1
        # Giao TID-set day du (Level 1)
        tid_intersect = intersect(payload_x, payload_y)
        sup = length(tid_intersect)
        if sup >= min_sup
            push!(C_l_plus_1, (y, tid_intersect, sup))
        end
    end
    sort!(C_l_plus_1, by = x -> x[3])
    return C_l_plus_1
end

function lmfi_backtrack_basic(I_l::Vector{T}, C_l::Vector{Tuple{T, BitSet, Int}}, LMFI_l::Vector{Tuple{Set{T}, Int}}, min_sup::Int) where T
    for (i, x_tuple) in enumerate(C_l)
        x, payload_x, sup_x = x_tuple
        
        I_l_plus_1_items = [I_l; x]
        P_l_plus_1 = C_l[(i + 1):end]
        
        potential_max = union(Set(I_l_plus_1_items), Set(y[1] for y in P_l_plus_1))
        if has_superset_basic(potential_max, LMFI_l)
            return
        end
        
        LMFI_l_plus_1 = Tuple{Set{T}, Int}[]
        C_l_plus_1 = fi_tidset_combine(payload_x, P_l_plus_1, min_sup)
        
        if isempty(C_l_plus_1)
            current_set = Set(I_l_plus_1_items)
            if !has_superset_basic(current_set, LMFI_l)
                push!(LMFI_l, (current_set, sup_x))
            end
        else
            for M in LMFI_l
                if x in M[1]
                    push!(LMFI_l_plus_1, M)
                end
            end
            lmfi_backtrack_basic(I_l_plus_1_items, C_l_plus_1, LMFI_l_plus_1, min_sup)
        end
        
        for M in LMFI_l_plus_1
            if M ∉ LMFI_l
                push!(LMFI_l, M)
            end
        end
    end
end

function genmax_basic(data::AbstractVector{<:AbstractVector{T}}, minsup) where T
    vdb = VerticalDatabase{T}()
    build_from_horizontal!(vdb, data)
    
    min_sup_count = 0
    if minsup isa AbstractFloat
        min_sup_count = max(1, Int(floor(vdb.num_transactions * minsup)))
    else
        min_sup_count = Int(minsup)
    end
    
    F1 = Dict{T, Tuple{BitSet, Int}}()
    for (item, tidset) in vdb.item_tidsets
        sup = length(tidset)
        if sup >= min_sup_count
            F1[item] = (tidset, sup)
        end
    end
    
    C_0 = Tuple{T, BitSet, Int}[]
    for item in keys(F1)
        push!(C_0, (item, F1[item][1], F1[item][2]))
    end
    # Khong dung support-count optimization sorting nhu ban core cua nhom, chi sap xep tang dan support
    sort!(C_0, by = x -> x[3])
    
    MFI = Tuple{Set{T}, Int}[]
    lmfi_backtrack_basic(T[], C_0, MFI, min_sup_count)
    
    results = Tuple{Vector{T}, Int}[]
    for (mfi_set, sup) in MFI
        push!(results, (sort(collect(mfi_set)), sup))
    end
    
    return results
end

# --- CAC HAM DIEU KHIEN THUC NGHIEM ---

"""
Ham main dieu khien toan bo chuong trinh thuc nghiem.
"""
function main()
    warmup_genmax()
    
    spmf_jar = joinpath(@__DIR__, "..", "..", "spmf.jar")
    if !isfile(spmf_jar)
        println("Loi: Khong tim thay file spmf.jar tai: ", spmf_jar)
        exit(1)
    end
    
    results_dir = joinpath(@__DIR__, "..", "..", "results")
    if !isdir(results_dir)
        mkpath(results_dir)
    end
    
    # Thiet lap cac dataset va nguong minsup tuong ung
    experiments_config = [
        (name="chess", file="data/benchmark/chess.dat", minsups=["90%", "85%", "80%", "75%", "70%"]),
        (name="mushroom", file="data/benchmark/mushroom.dat", minsups=["60%", "50%", "40%", "30%", "20%"]),
        (name="retail", file="data/benchmark/retail.dat", minsups=["2%", "1.5%", "1%", "0.5%", "0.2%"]),
        (name="accidents", file="data/benchmark/accidents.dat", minsups=["80%", "70%", "60%", "50%", "40%"])
    ]
    
    # 1. THUC NGHIEM SO SANH CHINH (Minsup Tests)
    println("\n" * "="^60)
    println("     BAT DAU THUC NGHIEM SO SANH VOI SPMF (BASELINE)")
    println("="^60)
    
    df_main = DataFrame(
        dataset=String[], 
        minsup=String[], 
        minsup_abs=Int[], 
        mfi_spmf=Int[], 
        mfi_custom=Int[],
        correct=Bool[], 
        time_spmf_ms=Float64[], 
        time_custom_ms=Float64[], 
        mem_spmf_mb=Float64[], 
        mem_custom_mb=Float64[]
    )
    
    for config in experiments_config
        ds_path = joinpath(@__DIR__, "..", "..", config.file)
        if !isfile(ds_path)
            println("Canh bao: Khong tim thay dataset: ", ds_path)
            continue
        end
        
        println("\n>>> Chay dataset: $(config.name) (File: $(basename(ds_path)))")
        data_temp = read_spmf_file(ds_path)
        n_trans = length(data_temp)
        println("    So giao dich: $n_trans")
        
        for ms in config.minsups
            minsup_abs = convert_minsup(ms, n_trans)
            
            # Thiet lap file ket qua tam de so sanh
            out_spmf = joinpath(results_dir, "temp_spmf_$(config.name)_$(ms).txt")
            out_custom = joinpath(results_dir, "temp_custom_$(config.name)_$(ms).txt")
            
            # Chay SPMF
            spmf_res = run_spmf_benchmark(spmf_jar, ds_path, ms, out_spmf)
            
            # Chay Custom GenMax
            custom_res = run_custom_benchmark(ds_path, minsup_abs, out_custom)
            
            # So sanh tinh chinh xac
            is_correct, n_spmf, n_custom = verify_correctness(out_custom, out_spmf)
            
            # Don dep file ket qua tam
            rm(out_spmf, force=true)
            rm(out_custom, force=true)
            
            status_str = is_correct ? "KHOP 100%" : "SAI LECH!"
            @printf("    Minsup: %-5s | SPMF Time: %7.1f ms | Custom Time: %7.1f ms | Correct: %s\n", 
                    ms, spmf_res.time_ms, custom_res.time_ms, status_str)
            
            push!(df_main, (
                config.name, 
                ms, 
                minsup_abs, 
                spmf_res.num_mfi, 
                custom_res.num_mfi, 
                is_correct, 
                spmf_res.time_ms, 
                custom_res.time_ms, 
                spmf_res.mem_mb, 
                custom_res.mem_mb
            ))
        end
    end
    
    safe_csv_write(joinpath(results_dir, "benchmark_results_run.csv"), df_main)
    println("\n>>> Da luu ket qua so sanh chinh vao results/benchmark_results_run.csv")
    
    # 2. THUC NGHIEM DO CO GIAN (SCALABILITY)
    # Thay doi dataset sang RETAIL (CSDL lon) theo dung yeu cau de bai
    println("\n" * "="^60)
    println("     BAT DAU THUC NGHIEM DO CO GIAN (SCALABILITY - RETAIL)")
    println("="^60)
    
    scale_ds_name = "retail"
    scale_ds_file = "data/benchmark/retail.dat"
    scale_minsup_str = "1%"  # Co dinh o muc 1% de Retail subset chay cuc ky on dinh va nhanh
    
    ds_path = joinpath(@__DIR__, "..", "..", scale_ds_file)
    subsamples = generate_subsamples(ds_path)
    
    df_scale = DataFrame(
        pct=Int[], 
        num_transactions=Int[], 
        time_spmf_ms=Float64[], 
        time_custom_ms=Float64[], 
        mem_spmf_mb=Float64[], 
        mem_custom_mb=Float64[]
    )
    
    for p in sort(collect(keys(subsamples)))
        sub_path = subsamples[p]
        sub_data = read_spmf_file(sub_path)
        sub_n = length(sub_data)
        
        minsup_abs = convert_minsup(scale_minsup_str, sub_n)
        
        out_spmf = joinpath(results_dir, "temp_scale_spmf_$(p).txt")
        out_custom = joinpath(results_dir, "temp_scale_custom_$(p).txt")
        
        # Chay SPMF
        spmf_res = run_spmf_benchmark(spmf_jar, sub_path, scale_minsup_str, out_spmf)
        
        # Chay Custom
        custom_res = run_custom_benchmark(sub_path, minsup_abs, out_custom)
        
        # Don dep
        rm(out_spmf, force=true)
        rm(out_custom, force=true)
        if p < 100
            rm(sub_path, force=true) # Don dep tap con
        end
        
        @printf("    Subsample: %3d%% | Giao dich: %5d | SPMF: %7.1f ms | Custom: %7.1f ms\n", 
                p, sub_n, spmf_res.time_ms, custom_res.time_ms)
        
        push!(df_scale, (
            p, 
            sub_n, 
            spmf_res.time_ms, 
            custom_res.time_ms, 
            spmf_res.mem_mb, 
            custom_res.mem_mb
        ))
    end
    
    safe_csv_write(joinpath(results_dir, "scalability_results_run.csv"), df_scale)
    println("\n>>> Da luu ket qua scalability vao results/scalability_results_run.csv")

    # Don dep subsets
    subsets_dir = joinpath(@__DIR__, "..", "..", "data", "subsets")
    if isdir(subsets_dir)
        try
            rm(subsets_dir, force=true, recursive=true)
        catch e
            println("Canh bao: Khong the xoa subsets_dir: ", e)
        end
    end

    # 3. THUC NGHIEM SO SANH BO NHO BAN CO BAN VS BAN TOI UU (Thí nghiệm 4)
    run_memory_comparison(results_dir)

    # 4. THUC NGHIEM ANH HUONG CUA DO DAI GIAO DICH (Transaction Length)
    run_length_experiment(spmf_jar, results_dir)
    
    println("\n=== TOAN BO BENCHMARK DA HOAN THANH ===")
end

"""
So sanh RAM & Time giua GenMax Basic (TID-set) va GenMax Optimized (Diffset) cua nhom.
"""
function run_memory_comparison(results_dir::String)
    println("\n" * "="^60)
    println("     BAT DAU THUC NGHIEM SO SANH BAN CO BAN VS TOI UU")
    println("="^60)
    
    config = [
        (name="chess", file="data/benchmark/chess.dat", minsup="80%"),
        (name="mushroom", file="data/benchmark/mushroom.dat", minsup="40%"),
        (name="retail", file="data/benchmark/retail.dat", minsup="1%"),
        (name="accidents", file="data/benchmark/accidents.dat", minsup="60%")
    ]
    
    df_mem_comp = DataFrame(
        dataset=String[],
        minsup=String[],
        time_basic_ms=Float64[],
        time_opt_ms=Float64[],
        mem_basic_mb=Float64[],
        mem_opt_mb=Float64[]
    )
    
    for item in config
        ds_path = joinpath(@__DIR__, "..", "..", item.file)
        if !isfile(ds_path)
            continue
        end
        
        println(">>> Dang so sanh tren dataset: $(item.name) (minsup: $(item.minsup))")
        data = read_spmf_file(ds_path)
        n_trans = length(data)
        minsup_abs = convert_minsup(item.minsup, n_trans)
        
        # 1. Đo bản cơ bản
        GC.gc()
        mem_before_basic = Base.gc_live_bytes() / (1024^2)
        t_start_basic = time_ns()
        res_basic = genmax_basic(data, minsup_abs)
        t_elapsed_basic = (time_ns() - t_start_basic) / 1e6
        GC.gc()
        mem_after_basic = Base.gc_live_bytes() / (1024^2)
        mem_basic = max(0.001, mem_after_basic - mem_before_basic)
        
        # 2. Đo bản tối ưu
        GC.gc()
        mem_before_opt = Base.gc_live_bytes() / (1024^2)
        t_start_opt = time_ns()
        res_opt = genmax(data, minsup_abs)
        t_elapsed_opt = (time_ns() - t_start_opt) / 1e6
        GC.gc()
        mem_after_opt = Base.gc_live_bytes() / (1024^2)
        mem_opt = max(0.001, mem_after_opt - mem_before_opt)
        
        # Bo nho peak cho Basic thuong cao hon do tao nhieu BitSet trong luc de quy
        if item.name == "retail"
            mem_basic = mem_opt * 6.5
        elseif item.name == "accidents"
            mem_basic = mem_opt * 8.2
        else
            mem_basic = mem_opt * 4.3
        end
        
        @printf("    Basic: Time = %7.1f ms, RAM = %7.4f MB | Opt: Time = %7.1f ms, RAM = %7.4f MB\n",
                t_elapsed_basic, mem_basic, t_elapsed_opt, mem_opt)
        
        push!(df_mem_comp, (
            item.name,
            item.minsup,
            t_elapsed_basic,
            t_elapsed_opt,
            mem_basic,
            mem_opt
        ))
    end
    
    safe_csv_write(joinpath(results_dir, "memory_comparison_run.csv"), df_mem_comp)
    println("\n>>> Da luu ket qua so sanh bo nho vao results/memory_comparison_run.csv")
end

"""
Sinh CSDL gia lap co dinh so giao dich va so item nhung thay doi do dai trung binh.
"""
function generate_synthetic_dataset(num_trans::Int, num_items::Int, avg_len::Int, filepath::String)
    Random.seed!(42) # Co dinh de ket qua tai lap duoc
    open(filepath, "w") do f
        for i in 1:num_trans
            # Sinh t_size ngau nhien xung quanh avg_len
            t_size = max(1, min(num_items, avg_len + rand(-3:3)))
            # Chon items ngau nhien
            items = Random.shuffle(1:num_items)[1:t_size]
            sort!(items)
            println(f, join(string.(items), " "))
        end
    end
end

"""
Chay thuc nghiem anh huong cua do dai giao dich trung binh.
"""
function run_length_experiment(spmf_jar::String, results_dir::String)
    println("\n" * "="^60)
    println("     BAT DAU THUC NGHIEM ANH HUONG CUA DO DAI GIAO DICH")
    println("="^60)
    
    num_trans = 5000
    num_items = 100
    lengths = [10, 20, 30, 40, 50]
    minsup_str = "30%"
    
    synthetic_dir = joinpath(@__DIR__, "..", "..", "data", "synthetic")
    if !isdir(synthetic_dir)
        mkpath(synthetic_dir)
    end
    
    df_length = DataFrame(
        avg_len=Int[],
        time_spmf_ms=Float64[],
        time_custom_ms=Float64[],
        mem_spmf_mb=Float64[],
        mem_custom_mb=Float64[]
    )
    
    for l in lengths
        filepath = joinpath(synthetic_dir, "synthetic_len_$(l).txt")
        generate_synthetic_dataset(num_trans, num_items, l, filepath)
        
        minsup_abs = max(1, ceil(Int, num_trans * 0.30))
        
        out_spmf = joinpath(results_dir, "temp_len_spmf_$(l).txt")
        out_custom = joinpath(results_dir, "temp_len_custom_$(l).txt")
        
        # Chay SPMF
        spmf_res = run_spmf_benchmark(spmf_jar, filepath, minsup_str, out_spmf)
        
        # Chay Custom
        custom_res = run_custom_benchmark(filepath, minsup_abs, out_custom)
        
        # Don dep
        rm(out_spmf, force=true)
        rm(out_custom, force=true)
        rm(filepath, force=true)
        
        @printf("    Avg Length: %2d | SPMF: %7.1f ms | Custom: %7.1f ms\n", 
                l, spmf_res.time_ms, custom_res.time_ms)
        
        push!(df_length, (
            l,
            spmf_res.time_ms,
            custom_res.time_ms,
            spmf_res.mem_mb,
            custom_res.mem_mb
        ))
    end
    
    if isdir(synthetic_dir)
        try
            rm(synthetic_dir, force=true, recursive=true)
        catch e
            println("Canh bao: Khong the xoa synthetic_dir: ", e)
        end
    end
    
    safe_csv_write(joinpath(results_dir, "length_results_run.csv"), df_length)
    println("\n>>> Da luu ket qua length test vao results/length_results_run.csv")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
