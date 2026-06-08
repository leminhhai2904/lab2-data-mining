using DataFrames
using CSV
using Plots

function plot_results(results_dir="results")
    if !isdir(results_dir)
        println("Thư mục $results_dir không tồn tại!")
        return
    end

    files = filter(f -> endswith(f, "_experiment.csv"), readdir(results_dir))
    
    for file in files
        df = CSV.read(joinpath(results_dir, file), DataFrame)
        if nrow(df) == 0
            continue
        end
        dataset = df.dataset[1]
        
        # Biểu đồ Time (Thời gian chạy)
        p1 = plot(df.minsup_abs, df.time_ms, marker=:circle, title="Thời gian chạy - $dataset",
             xlabel="Minsup (Tuyệt đối)", ylabel="Thời gian (ms)", legend=false, linewidth=2)
        savefig(p1, joinpath(results_dir, "$(dataset)_time.png"))
        
        # Biểu đồ Num MFI (Số lượng MFI)
        p2 = plot(df.minsup_abs, df.num_mfi, marker=:square, color=:green, title="Số lượng MFI - $dataset",
             xlabel="Minsup (Tuyệt đối)", ylabel="Số MFI sinh ra", legend=false, linewidth=2)
        savefig(p2, joinpath(results_dir, "$(dataset)_mfi_count.png"))
    end
    println("Đã tạo tất cả biểu đồ dưới dạng .png trong thư mục $results_dir/")
end

if abspath(PROGRAM_FILE) == @__FILE__
    plot_results("results")
end
