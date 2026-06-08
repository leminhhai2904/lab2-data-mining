# src/utils.jl
module Utils

export read_spmf_file, write_spmf_file, parse_command_line

"""
Đọc file dữ liệu đầu vào định dạng SPMF (.txt)
Mỗi dòng là một giao dịch, các item cách nhau bởi khoảng trắng.
"""
function read_spmf_file(filepath::String)
    data = Vector{Vector{String}}()
    
    open(filepath, "r") do file
        for line in eachline(file)
            line = strip(line)
            if !isempty(line)
                # Tách các item bằng khoảng trắng
                items = split(line)
                push!(data, String.(items))
            end
        end
    end
    return data
end

"""
Ghi kết quả tập phổ biến ra file định dạng SPMF (.txt)
Mỗi dòng 1 Itemset (như: 1 2 3 #SUP: 4)
"""
function write_spmf_file(results::Vector{Tuple{Vector{T}, Int}}, filepath::String) where T
    open(filepath, "w") do file
        for (itemset, sup) in results
            line = join(itemset, " ") * " #SUP: " * string(sup)
            println(file, line)
        end
    end
end

"""
Xử lý tham số dòng lệnh để truyền minsup.
Ví dụ: julia main.jl data.txt 0.1
"""
function parse_command_line(args::Vector{String})
    if length(args) < 2
        println("Sử dụng: julia <script_name.jl> <đường_dẫn_file_data> <minsup>")
        println("Ví dụ: \n  julia script.jl data/benchmark/chess.dat 0.8  (Tuyệt đối)\n  julia script.jl data/benchmark/chess.dat 1000 (Tương đối)")
        exit(1)
    end
    
    filepath = args[1]
    
    minsup_str = args[2]
    minsup::Union{Float64, Int} = 0
    if occursin(".", minsup_str)
        minsup = parse(Float64, minsup_str)
    else
        minsup = parse(Int, minsup_str)
    end
    
    return filepath, minsup
end

end # module
