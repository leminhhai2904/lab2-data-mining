# Đồ Án 2: Khai thác Tập phổ biến (Thuật toán GenMax)

Đây là kho lưu trữ mã nguồn cho Đồ án Khai thác Tập phổ biến. 
Dự án không sử dụng bất kỳ thư viện Khai thác dữ liệu nào có sẵn làm công cụ xử lý lõi, tự xây dựng hệ thống đọc/ghi file chuẩn SPMF, tiến hành benchmark diện rộng và có triển khai bài toán **Phân tích giỏ hàng (Market Basket Analysis)**.

---

## 1. Cấu Trúc Dự Án

```
Group_ID/
├── README.md
├── src/                        # Mã nguồn chính thức (100% Julia)
│   ├── main.jl                 # Entry point chính chạy thuật toán (parse CLI)
│   ├── run_test.jl             # Tool kiểm thử nhanh với Toy Data (trong bài báo)
│   ├── utils.jl                # Module IO xử lý file SPMF (.txt/.dat)
│   ├── structures.jl           # Khai báo cấu trúc Vertical Database (BitSet)
│   ├── algorithm/
│   │   └── genmax.jl           # Thuật toán lõi bằng đệ quy nhánh cận + Diffset
│   └── experiments/
│       ├── run_experiments.jl  # Chạy test đo lường Thời Gian / RAM theo từng Minsup
│       ├── compare_spmf.jl     # So sánh bộ output GenMax với bộ output của SPMF
│       ├── make_plots.jl       # Auto-render biểu đồ
│       ├── generate_subsets.jl # Tự động cắt các subset dữ liệu phục vụ test khả năng mở rộng
│       └── market_basket.jl    # Ứng dụng Phân tích Giỏ hàng (Tính Lift, Confidence)
├── tests/
│   ├── test_correctness.jl     # Unit Test: Kiểm thử tính đúng đắn với dữ liệu đồ chơi
│   └── test_benchmark.jl       # Unit Test: Tự động lặp và Check Error qua 5 CSDL chuẩn
├── data/
│   ├── benchmark/              # Dữ liệu phục vụ đánh giá (chess, mushroom, retail, T1014...)
│   └── application/            # Dữ liệu bán lẻ cho Market Basket Analysis
├── notebooks/
│   └── demo.ipynb              # Jupyter notebook minh hoạ các phép chạy
└── docs/
    └── Report_Template.md      # Khung báo cáo nộp giáo viên
```

---

## 2. Hướng Dẫn Cài Đặt

Mã nguồn được viết hoàn toàn bằng Julia.

**Bước 1:** Tải/Clone project về máy.

**Bước 2:** Cài đặt các Package mở rộng hỗ trợ (Chủ yếu dành cho thực nghiệm, dựng biểu đồ và MBA). Mở Terminal và gõ:
```bash
julia -e 'using Pkg; Pkg.add(["CSV", "DataFrames", "Plots", "Combinatorics"])'
```
*Ghi chú: Nếu hệ thống bạn chưa có sẵn lệnh `julia`, bạn có thể chạy `powershell .\setup_julia.ps1` (trên Windows) để nó tự động thiết lập một phiên bản Julia nén tại chỗ.*

---

## 3. Cách Chạy Cơ Bản & Tham Số Dòng Lệnh

Bạn có thể chạy thử trực tiếp trên Terminal/CMD với cấu trúc lệnh:
```bash
julia src/main.jl <đường_dẫn_file_dữ_liệu> <minsup>
```

**Ví dụ với minsup Tương đối (Dưới dạng Decimal):**
Sẽ tìm tất cả các mục có độ phổ biến từ 80% trở lên.
```bash
julia src/main.jl data/benchmark/chess.dat 0.8
```

**Ví dụ với minsup Tuyệt đối (Dưới dạng Số nguyên):**
Tìm tất cả item có lượt giao dịch tối thiểu là 500.
```bash
julia src/main.jl data/benchmark/mushroom.dat 500
```
> Kết quả MFI sẽ được tự động trích xuất và in vào chung thư mục chứa file data với đuôi `_MFI_output.txt`.

---

## 4. Kiểm Thử Tự Động (Unit Testing)

Chạy bộ Test cơ bản theo ví dụ minh hoạ từ bài báo GenMax:
```bash
julia tests/test_correctness.jl
# (Hoặc gõ nhanh: julia src/run_test.jl)
```

Kiểm tra độ bao phủ (Crash & Pass) khi chạy toàn bộ 5 CSDL theo yêu cầu của đồ án:
```bash
julia tests/test_benchmark.jl
```

---

## 5. Đánh Giá Hiệu Năng và Biểu Đồ

Để phát sinh các file CSV đo lường tốc độ, mức thu hồi bộ nhớ đỉnh (Peak RAM) ứng với nhiều minsup:
```bash
julia src/experiments/run_experiments.jl
```

Chạy rendering vẽ biểu đồ (Thời gian thi hành & Số MFI) từ logs:
```bash
julia src/experiments/make_plots.jl
```

So sánh chéo độ chính xác của Module Julia Genmax với Module SPMF (Java):
```bash
julia src/experiments/compare_spmf.jl PATH_CUSTOM PATH_SPMF
```

---

## 6. Chạy Ứng Dụng: Market Basket Analysis

Để chứng minh tính ứng dụng của MFI, nhóm triển khai script phân tích giỏ mua hàng để sinh bảng luật kết hợp.
```bash
julia src/experiments/market_basket.jl
```
Hệ thống sẽ lấy file `data/application/retail.dat` xử lý thông qua `GenMax` và sinh mọi `subset`, tính sự tự tin `Confidence`, hệ số tương quan `Lift` và xuất ra **TOP-10 luật** hữu ích nhất cho người ra quyết định.