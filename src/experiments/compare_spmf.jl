function parse_spmf_output(filepath::String)
    results = Dict{Vector{String}, Int}()
    for line in eachline(filepath)
        line = strip(line)
        if isempty(line) || startswith(line, "#") && !occursin("#SUP:", line)
            continue
        end
        if occursin("#SUP:", line)
            parts = split(line, "#SUP:")
            itemset_str = strip(parts[1])
            sup = parse(Int, strip(parts[2]))
            
            # Lưu ý mảng item có thể là dạng số hoặc chữ, lưu ở dạng chuỗi thống nhất
            itemset = sort(string.(split(itemset_str)))
            results[itemset] = sup
        end
    end
    return results
end

function compare_results(our_file::String, spmf_file::String)
    our = parse_spmf_output(our_file)
    spmf = parse_spmf_output(spmf_file)
    
    println("\n=== SO SÁNH CORRECTNESS ===")
    println("Kết quả do GenMax custom sinh : $(length(our)) MFI")
    println("Kết quả do tool SPMF java sinh: $(length(spmf)) MFI")
    
    our_keys = Set(keys(our))
    spmf_keys = Set(keys(spmf))
    
    common = intersect(our_keys, spmf_keys)
    only_our = setdiff(our_keys, spmf_keys)
    only_spmf = setdiff(spmf_keys, our_keys)
    
    println("Khớp nhau hoàn toàn : $(length(common))")
    println("Chỉ có bên GenMax   : $(length(only_our))")
    println("Chỉ có bên SPMF     : $(length(only_spmf))")
    
    if length(our) == length(spmf) && isempty(only_our) && isempty(only_spmf)
        println("HOÀN HẢO - Kết quả code của bạn khớp 100% với SPMF!")
    else
        println("Cảnh báo: Có sự sai lệch, kết quả chưa chuẩn.")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) >= 2
        compare_results(ARGS[1], ARGS[2])
    else
        println("Sử dụng: julia compare_spmf.jl <our_output.txt> <spmf_output.txt>")
    end
end
