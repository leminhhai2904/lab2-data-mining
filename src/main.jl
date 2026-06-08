# src/main.jl
# Entry point chính để chạy thuật toán GenMax từ dòng lệnh.
# Cú pháp: julia src/main.jl <đường_dẫn_file_dữ_liệu> <minsup>
# Ví dụ:   julia src/main.jl data/benchmark/chess.dat 0.8
#          julia src/main.jl data/benchmark/mushroom.dat 500

include("structures.jl")
include("algorithm/genmax.jl")
include("utils.jl")

using .Structures
using .GenMaxAlgo
using .Utils

# --- Parse tham số dòng lệnh ---
filepath, minsup = parse_command_line(ARGS)

if !isfile(filepath)
    println("Lỗi: Không tìm thấy file \"$filepath\"")
    exit(1)
end

# --- Đọc dữ liệu ---
println("Đang đọc dữ liệu từ: $filepath")
data = read_spmf_file(filepath)
println("Số giao dịch: $(length(data))")

# --- Chạy thuật toán ---
minsup_label = minsup isa AbstractFloat ? "$(minsup * 100)%" : "$minsup"
println("Đang chạy GenMax với minsup = $minsup_label ...")
t_start = time()
results = genmax(data, minsup)
elapsed = round(time() - t_start, digits=3)
println("Hoàn thành trong $elapsed giây. Tìm được $(length(results)) MFI.")

# --- Ghi kết quả ra file ---
out_path = filepath * "_MFI_output.txt"
write_spmf_file(results, out_path)
println("Kết quả đã được ghi vào: $out_path")
