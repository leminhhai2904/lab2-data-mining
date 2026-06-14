using CSV
using DataFrames
using Plots


gr() # Su dung backend GR
default(
    fontfamily="sans-serif",
    titlefontsize=11,
    guidefontsize=9,
    tickfontsize=8,
    legendfontsize=8,
    grid=true,
    linewidth=2,
    markersize=5,
    dpi=300
)

"""
Ve cac do thi lien quan den minsup: thoi gian chay, bo nho, va so luong MFI.
"""
function plot_minsup_experiments(results_dir::String)
    csv_path = joinpath(results_dir, "benchmark_results.csv")
    if !isfile(csv_path)
        println("Loi: Khong tim thay file ket qua $csv_path")
        return
    end
    
    df = CSV.read(csv_path, DataFrame)
    datasets = unique(df.dataset)
    
    for ds in datasets
        df_ds = df[df.dataset .== ds, :]
        
        # Sap xep theo minsup tang dan (vd: tu 20% -> 60%)
        sort!(df_ds, :minsup_abs)
        
        # 1. Bieu do Thoi gian chay (Time vs Minsup)
        p_time = plot(
            df_ds.minsup, df_ds.time_spmf_ms, 
            marker=:circle, color=:red, linestyle=:dash,
            label="SPMF (Baseline)",
            title="Thoi gian chay vs Minsup - $(uppercase(ds))",
            xlabel="Minimum Support (%)",
            ylabel="Thoi gian chay (ms)",
            legend=:topright
        )
        plot!(
            p_time,
            df_ds.minsup, df_ds.time_custom_ms, 
            marker=:square, color=:blue,
            label="GenMax (Nhom)"
        )
        savefig(p_time, joinpath(results_dir, "$(ds)_time_vs_minsup.png"))
        
        # 2. Bieu do Bo nho (Memory vs Minsup)
        p_mem = plot(
            df_ds.minsup, df_ds.mem_spmf_mb, 
            marker=:circle, color=:red, linestyle=:dash,
            label="SPMF (Baseline)",
            title="Bo nho tieu thu vs Minsup - $(uppercase(ds))",
            xlabel="Minimum Support (%)",
            ylabel="RAM su dung (MB)",
            legend=:topright
        )
        plot!(
            p_mem,
            df_ds.minsup, df_ds.mem_custom_mb, 
            marker=:square, color=:blue,
            label="GenMax (Nhom)"
        )
        savefig(p_mem, joinpath(results_dir, "$(ds)_memory_vs_minsup.png"))
        
        # 3. Bieu do So luong MFI sinh ra (MFI Count vs Minsup)
        p_count = plot(
            df_ds.minsup, df_ds.mfi_custom, 
            marker=:diamond, color=:darkgreen,
            label="MFI Count",
            title="So luong MFI sinh ra vs Minsup - $(uppercase(ds))",
            xlabel="Minimum Support (%)",
            ylabel="So luong tap pho bien toi dai",
            legend=:topright
        )
        savefig(p_count, joinpath(results_dir, "$(ds)_mfi_count_vs_minsup.png"))
        
        println(">>> Da ve xong do thi cho dataset: $ds")
    end
end

"""
Ve do thi scalability: thoi gian chay va bo nho theo kich thuoc du lieu.
"""
function plot_scalability_experiments(results_dir::String)
    csv_path = joinpath(results_dir, "scalability_results.csv")
    if !isfile(csv_path)
        println("Loi: Khong tim thay file ket qua $csv_path")
        return
    end
    
    df = CSV.read(csv_path, DataFrame)
    sort!(df, :pct)
    
    # 1. Scalability Time Plot
    p_time = plot(
        df.pct, df.time_spmf_ms, 
        marker=:circle, color=:red, linestyle=:dash,
        label="SPMF (Baseline)",
        title="Kha nang mo rong (Thoi gian) - RETAIL (Minsup 1%)",
        xlabel="Kich thuoc du lieu (%)",
        ylabel="Thoi gian chay (ms)",
        legend=:topleft
    )
    plot!(
        p_time,
        df.pct, df.time_custom_ms, 
        marker=:square, color=:blue,
        label="GenMax (Nhom)"
    )
    savefig(p_time, joinpath(results_dir, "retail_scalability_time.png"))
    
    # 2. Scalability Memory Plot
    p_mem = plot(
        df.pct, df.mem_spmf_mb, 
        marker=:circle, color=:red, linestyle=:dash,
        label="SPMF (Baseline)",
        title="Kha nang mo rong (RAM) - RETAIL (Minsup 1%)",
        xlabel="Kich thuoc du lieu (%)",
        ylabel="RAM su dung (MB)",
        legend=:topleft
    )
    plot!(
        p_mem,
        df.pct, df.mem_custom_mb, 
        marker=:square, color=:blue,
        label="GenMax (Nhom)"
    )
    savefig(p_mem, joinpath(results_dir, "retail_scalability_memory.png"))
    
    println(">>> Da ve xong do thi scalability.")
end

function main()
    results_dir = joinpath(@__DIR__, "..", "..", "results")
    if !isdir(results_dir)
        println("Loi: Thu muc results khong ton tai!")
        return
    end
    
    println("\n" * "="^60)
    println("     Bat dau ve do thi!")
    println("="^60)
    
    plot_minsup_experiments(results_dir)
    plot_scalability_experiments(results_dir)
    plot_length_experiments(results_dir)
    
    println("\nHOAN THANH VE DO THI")
end

"""
Ve do thi anh huong cua do dai giao dich trung binh.
"""
function plot_length_experiments(results_dir::String)
    csv_path = joinpath(results_dir, "length_results.csv")
    if !isfile(csv_path)
        println("Loi: Khong tim thay file ket qua $csv_path")
        return
    end
    
    df = CSV.read(csv_path, DataFrame)
    sort!(df, :avg_len)
    
    # 1. Length Time Plot
    p_time = plot(
        df.avg_len, df.time_spmf_ms, 
        marker=:circle, color=:red, linestyle=:dash,
        label="SPMF (Baseline)",
        title="Anh huong do dai giao dich (Thoi gian) - Minsup 30%",
        xlabel="Do dai giao dich trung binh",
        ylabel="Thoi gian chay (ms)",
        legend=:topleft
    )
    plot!(
        p_time,
        df.avg_len, df.time_custom_ms, 
        marker=:square, color=:blue,
        label="GenMax (Nhom)"
    )
    savefig(p_time, joinpath(results_dir, "length_vs_time.png"))
    
    # 2. Length Memory Plot
    p_mem = plot(
        df.avg_len, df.mem_spmf_mb, 
        marker=:circle, color=:red, linestyle=:dash,
        label="SPMF (Baseline)",
        title="Anh huong do dai giao dich (RAM) - Minsup 30%",
        xlabel="Do dai giao dich trung binh",
        ylabel="RAM su dung (MB)",
        legend=:topleft
    )
    plot!(
        p_mem,
        df.avg_len, df.mem_custom_mb, 
        marker=:square, color=:blue,
        label="GenMax (Nhom)"
    )
    savefig(p_mem, joinpath(results_dir, "length_vs_memory.png"))
    
    println(">>> Da ve xong do thi.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
