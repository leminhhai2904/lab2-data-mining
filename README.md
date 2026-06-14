# Đồ Án 2: Khai thác Tập phổ biến (Thuật toán GenMax)

Đây là kho lưu trữ mã nguồn cho Đồ án Khai thác Tập phổ biến. 
Dự án không sử dụng bất kỳ thư viện Khai thác dữ liệu nào có sẵn làm công cụ xử lý lõi, tự xây dựng hệ thống đọc/ghi file chuẩn SPMF, tiến hành benchmark diện rộng và có triển khai bài toán **Phân tích giỏ hàng (Market Basket Analysis)**.

---

## 1. Hướng Dẫn Cài Đặt Môi Trường

Dự án được xây dựng toàn vẹn trên ngôn ngữ **Julia** và đã được bao gói tự động để cấu hình cực kỳ dễ dàng trên máy tính cá nhân (đặc biệt là Windows) mà không sợ lỗi xung đột.

### Cài đặt tự động trong 1 click
Bạn không cần tự cài đặt phần mềm hay cấu hình biến môi trường rườm rà.
1. Mở Terminal (PowerShell) tại thư mục gốc của dự án.
2. Quá trình thiết lập Kernel Jupyter và các Package thuộc dự án đã được chuẩn hoá với tệp `Project.toml`. Chạy lệnh sau để tải một bản Julia Portable thu gọn và tự cài đặt thư viện:
   ```powershell
   .\setup_julia.ps1
   ```
3. Sau khi Terminal hiển thị dòng báo `[THÀNH CÔNG]`, quá trình cài đặt hoàn tất. Lúc này trong thư mục sẽ xuất hiện thêm folder `julia/` phục vụ cho việc thực thi code.

---

## 2. Cách Chạy và Trải Nghiệm (Khuyến nghị)

Cách tốt nhất để giảng viên hoặc người dùng trải nghiệm đánh giá dự án là sử dụng **Jupyter Notebook** (nơi nhóm đã viết sẵn cả minh hoạ, code ứng dụng và ghi chú).

1. Bật **VS Code** (hoặc JupyterLab).
2. Mở file `notebooks/demo.ipynb`.
3. Nhìn lên góc trên bên phải, bấm vào mục **Select Kernel** -> Chọn **Jupyter Kernel** -> Nhấn nút mũi tên xoay vòng (Refresh) ở góc nhỏ nếu chưa tải kịp -> Chọn mục **Julia 1.10.x** (được cài đặt từ bước 1).
4. Run từng ô (Run Cell) từ trên xuống dưới. Notebook sẽ chạy các quy trình sau:
   - Sinh file Toy Data để minh hoạ thuật toán cơ sở.
   - Nạp file Benchmark (cỡ lớn) để đo thời gian qua biến `@time`.
   - Sinh và in ra *Top 10 Luật kết hợp (Association Rules)* dựa theo độ tương quan `Lift` lớn nhất.

---

## 3. Cách Chạy Cốt Lõi Qua Dòng Lệnh (CLI)

Nếu bạn muốn test thuật toán xử lý dữ liệu hàng triệu dòng mà không cần mở Notebook, bạn có thể dùng Terminal gọi thẳng vào lõi mã nguồn:

Cấu trúc lệnh chuẩn:
```powershell
.\julia\bin\julia.exe src/main.jl <đường_dẫn_file_dữ_liệu> <minsup>
```

**Ví dụ 1: Truyền thông số file và Minsup Tỉ lệ phần trăm (%)**
Lệnh này sẽ tìm tất cả các mục có độ phổ biến từ 80% trở lên.
```powershell
.\julia\bin\julia.exe src/main.jl data/benchmark/chess.dat 0.8
```

**Ví dụ 2: Truyền thông số file và Minsup Tuyệt đối**
Tìm tất cả các sự kiện giao dịch có lượt xuất hiện tối thiểu ấn định là 500.
```powershell
.\julia\bin\julia.exe src/main.jl data/benchmark/mushroom.dat 500
```
> *(Ghi chú: Kết quả xuất ra sẽ tự động được ghi sang định dạng SPMF cực chuẩn và lưu chung vào thư mục chứa file log ban đầu với đuôi `_MFI_output.txt`)*

## 4. Chạy Ứng Dụng: Market Basket Analysis

Để chứng minh tính ứng dụng của MFI, nhóm triển khai kịch bản phân tích giỏ mua hàng để tính toán và sinh bảng luật kết hợp trực tiếp từ tập dữ liệu bán lẻ `retail.dat`.
```powershell
.\julia\bin\julia.exe src/market_basket.jl
```
Hệ thống sẽ dựa vào tập Maximal Frequent Itemsets tìm được, sinh ra các mảng *Frequent Itemsets* tổ hợp con, sau đó tự tính độ hỗ trợ (Support), sự tự tin (Confidence) và lấy top các luật có hệ số tương quan (Lift) tốt nhất để xuất ra màn hình.

---

## 5. Cấu Trúc Dự Án

```text
Group_ID/
├── README.md                   # File hướng dẫn tổng quan dự án
├── Project.toml                # Cấu hình dependency môi trường (chuẩn Julia)
├── setup_julia.ps1             # Script tự động tải lõi ngôn ngữ Portable và kích hoạt Package
├── Lab_information             # File mô tả yêu cầu đồ án
├── src/                        # Mã nguồn chính thức cốt lõi (100% Julia)
│   ├── main.jl                 # Entry point chính cho luồng chạy Terminal
│   ├── market_basket.jl        # Script trình diễn Ứng dụng Market Basket Analysis
│   ├── utils.jl                # Chức năng hỗ trợ Đọc/Ghi I/O định dạng SPMF chuẩn
│   ├── structures.jl           # Định nghĩa cấu trúc Dataset lưu dọc (Vertical Data + BitSet) 
│   ├── algorithm/              # Thư mục mã nguồn cho lõi thuật toán
│   │   └── genmax.jl           # Triển khai thuật toán GenMax (FI-diffset, backtrack)
│   └── experiments/            # Chứa test batch và plot vẽ biểu đồ cho báo cáo
├── test/                       # Chứa các kịch bản kiểm thử tự động
│   ├── runtests.jl             # Script điều phối luồng kiểm thử chính (chuẩn Julia)
│   ├── test_benchmark.jl       # Script đo lường đánh giá hiệu năng thuật toán
│   └── test_correctness.jl     # Script kiểm tra tính đúng đắn so với output chuẩn
├── data/                       # Thư mục lưu trữ datasets
│   ├── application/            # Dữ liệu ứng dụng thực tế (chứa file retail.dat)
│   ├── benchmark/              # Dữ liệu lớn kiểm định Benchmark (chess.dat, mushroom.dat...)
│   └── toy/                    # File dữ liệu nhỏ giả lập thuật toán cơ bản
├── docs/                       # Thư mục chứa tài liệu báo cáo kỹ thuật
│   └── Report.pdf              # Nội dung báo cáo 
└── notebooks/
    └── demo.ipynb              # File Demo bằng Jupyter notebook trình diễn trực quan
```

---

## 6. Kết quả Kiểm thử (Unit Tests)

Dự án có đi kèm bộ phận test tự động 100% tuân chuẩn thiết kế packages của ngôn ngữ Julia.
Để chạy kiểm thử toàb bộ thuật toán cốt lõi, chạy lệnh sau:
```powershell
julia --project test/runtests.jl
```

**Output mẫu từ phiên chạy cuối cùng:**
```text
Test Summary: | Pass  Total  Time
All Tests     |   15     15  7.5s
```
