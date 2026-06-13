using Combinatorics
using Printf

include(joinpath(@__DIR__, "structures.jl"))
include(joinpath(@__DIR__, "utils.jl"))
include(joinpath(@__DIR__, "algorithm", "genmax.jl"))

using .Structures
using .Utils
using .GenMaxAlgo

"""
Hàm tính support tuyệt đối của một itemset bằng cách quét nhanh CSDL
"""
function compute_support(itemset::Vector{String}, data::Vector{Vector{String}})
    count = 0
    set_item = Set(itemset)
    for transaction in data
        # Kiểm tra xem set_item có phải là tập con của transaction không
        # transaction là Vector nhưng chuyển thành Set một lần nếu cache, 
        # để nhanh ta dùng check thủ công vì itemset thường nhỏ
        if issubset(set_item, transaction)
            count += 1
        end
    end
    return count
end

"""
Market Basket Analysis: Sinh luật từ MFI
"""
function market_basket_analysis(filepath::String, minsup_ratio::Float64, minconf::Float64)
    println("="^80)
    println("MARKET BASKET ANALYSIS (PHÂN TÍCH GIỎ HÀNG)")
    println("Dữ liệu: ", basename(filepath))
    println("Minsup:  ", minsup_ratio)
    println("Minconf: ", minconf)
    println("="^80)

    data = read_spmf_file(filepath)
    n_trans = length(data)
    minsup_abs = max(1, floor(Int, n_trans * minsup_ratio))

    println("[1] Đang chạy GenMax để tìm Maximal Frequent Itemsets (MFI)...")
    mfis = genmax(data, minsup_abs)
    println("    Tìm được $(length(mfis)) MFI.")

    if isempty(mfis)
        println("Không tìm thấy itemset thỏa mãn. Tăng dataset hoặc giảm minsup.")
        return
    end

    println("[2] Đang trích xuất tất cả Frequent Itemsets từ kết quả MFI...")
    # Lấy tất cả subset của các MFI
    all_frequent_sets = Set{Vector{String}}()
    for (mfi, _) in mfis
        # Giới hạn độ dài MFI nếu quá lớn để tránh bùng nổ tổ hợp
        m_len = length(mfi)
        if m_len > 12
            println("    Cảnh báo: MFI quá dài ($m_len items), giới hạn cắt bớt để không tràn RAM.")
            mfi = mfi[1:12]
        end

        for k in 1:length(mfi)
            for comb in combinations(mfi, k)
                push!(all_frequent_sets, sort(comb))
            end
        end
    end

    println("    Tổng số Frequent Itemsets sau khi bung tổ hợp: $(length(all_frequent_sets))")

    println("[3] Đang tính chính xác giá trị support cho từng Frequent Itemset...")
    # Cache lại support để không phải tính nhiều lần
    support_dict = Dict{Vector{String},Int}()
    for itemset in all_frequent_sets
        support_dict[itemset] = compute_support(itemset, data)
    end

    println("[4] Đang sinh luật kết hợp và tính Lift...")
    rules = [] # struct: (X, Y, sup_both, conf, lift)

    # Duyệt các frequent itemset có độ dài >= 2 để sinh luật
    for itemset in keys(support_dict)
        if length(itemset) < 2
            continue
        end

        sup_both = support_dict[itemset]

        # Tạo tất cả các khả năng chia itemset thành 2 tập (X) và (Y)
        # Bằng cách lấy mọi tập con X của itemset, Y = itemset - X
        for k in 1:(length(itemset)-1)
            for X in combinations(itemset, k)
                X_vec = sort(X)
                Y_vec = sort(collect(setdiff(Set(itemset), Set(X))))

                sup_X = support_dict[X_vec]
                sup_Y = support_dict[Y_vec]

                # Confidence: P(Y|X) = sup(X U Y) / sup(X)
                conf = sup_both / sup_X

                if conf >= minconf
                    # Lift: Conf(X -> Y) / P(Y)
                    prob_Y = sup_Y / n_trans
                    lift = conf / prob_Y
                    push!(rules, (X_vec, Y_vec, sup_both, conf, lift))
                end
            end
        end
    end

    println("    Tìm được $(length(rules)) luật thỏa mãn minconf.")

    # Sắp xếp luật theo Lift giảm dần
    sort!(rules, by=x -> x[5], rev=true)

    println("\n=== TOP 10 LUẬT KẾT HỢP (THEO LIFT) ===\n")
    @printf("%-30s => %-30s | %-6s | %-6s | %-6s\n", "Vế Trái (X)", "Vế Phải (Y)", "Sup", "Conf", "Lift")
    println("-"^95)

    top_limit = min(10, length(rules))
    for i in 1:top_limit
        rule = rules[i]
        str_X = string(rule[1])
        str_Y = string(rule[2])
        sup = rule[3]
        conf = round(rule[4], digits=3)
        lift = round(rule[5], digits=3)

        # Rút ngắn nếu chuỗi quá dài
        str_X = length(str_X) > 28 ? str_X[1:25] * "..." : str_X
        str_Y = length(str_Y) > 28 ? str_Y[1:25] * "..." : str_Y

        @printf("%-30s => %-30s | %-6d | %-6.2f | %-6.2f\n", str_X, str_Y, sup, conf, lift)
    end
    println("-"^95)
end

function run_market_basket_demo()
    dataset_path = joinpath(@__DIR__, "..", "data", "application", "retail.dat")

    if isfile(dataset_path)
        # Chạy mẫu trên dataset retail 
        # minsup nhỏ (do file retail MFI rất hiếm items dài), minconf 0.5 
        market_basket_analysis(dataset_path, 0.05, 0.50)
    else
        println("Không tìm thấy file: $dataset_path")
        println("Vui lòng tải hoặc kiểm tra lại retail.dat trong data/application/")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_market_basket_demo()
end
