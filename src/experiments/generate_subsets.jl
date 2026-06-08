using Random

include(joinpath(@__DIR__, "..", "utils.jl"))
using .Utils

function generate_subsets(input_file::String, percentages=[10, 25, 50, 75, 100])
    data = read_spmf_file(input_file)
    n = length(data)
    
    base_name = splitext(basename(input_file))[1]
    
    out_dir = joinpath(@__DIR__, "..", "..", "data", "subsets")
    if !isdir(out_dir)
        mkpath(out_dir)
    end
    
    for p in percentages
        size = floor(Int, n * p / 100)
        
        # shuffle nếu muốn ngẫu nhiên, hoặc cắt nếu muốn giữ nguyên thứ tự
        subset = p < 100 ? shuffle(data)[1:size] : data
        
        output_file = joinpath(out_dir, "$(base_name)_$(p)pct.txt")
        open(output_file, "w") do f
            for trans in subset
                println(f, join(trans, " "))
            end
        end
        println("Tạo subset $p%: $size transactions → $output_file")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) >= 1
        generate_subsets(ARGS[1])
    else
        println("Sử dụng: julia generate_subsets.jl <đường_dẫn_tới_file_dữ_liệu>")
    end
end
