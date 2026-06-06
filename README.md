# Lab 2 - Data Mining: Thuật toán GenMax

Dự án triển khai thuật toán khai thác tập phổ biến tối đại (Maximal Frequent Itemsets - MFI) GenMax bằng hai ngôn ngữ: **Python** và **Julia**.

---

## 1. Hướng dẫn chạy phiên bản Julia (Khuyên dùng)

Để chạy phiên bản Julia mới nhất, hãy hướng dẫn bạn của bạn thực hiện theo các bước sau:

### Bước 1: Cập nhật mã nguồn mới nhất
Chạy lệnh pull để cập nhật code và script cài đặt mới nhất:
```bash
git pull origin main
```

### Bước 2: Thiết lập môi trường Julia
*   **Trường hợp 1 (Máy đã cài sẵn Julia hệ thống):** Không cần cài đặt gì thêm, đi thẳng đến Bước 3.
*   **Trường hợp 2 (Máy chưa cài Julia - Dành cho Windows):**
    Chạy script tự động để tải và thiết lập môi trường Julia Portable (dạng nén cục bộ trong thư mục dự án):
    ```powershell
    powershell .\setup_julia.ps1
    ```

### Bước 3: Chạy kiểm thử (Run Test)
*   Nếu sử dụng **Julia hệ thống (Trường hợp 1)**:
    ```bash
    julia src/run_test.jl
    ```
*   Nếu sử dụng **Julia Portable cục bộ (Trường hợp 2)**:
    ```powershell
    .\julia\bin\julia.exe src/run_test.jl
    ```

---

## 2. Cấu trúc thư mục liên quan tới Julia

*   `src/structures.jl`: Cấu trúc dữ liệu dọc [VerticalDatabase](file:///c:/Users/Genmax/lab2-data-mining/src/structures.jl) tối ưu bằng `BitSet` của Julia.
*   `src/algorithm/genmax.jl`: Thuật toán lõi [genmax](file:///c:/Users/Genmax/lab2-data-mining/src/algorithm/genmax.jl) đệ quy nhánh cận kết hợp cấu trúc Diffset.
*   `src/run_test.jl`: Tập tin chạy kiểm thử [run_test.jl](file:///c:/Users/Genmax/lab2-data-mining/src/run_test.jl) với dữ liệu mẫu.
*   `setup_julia.ps1`: Script PowerShell [setup_julia.ps1](file:///c:/Users/Genmax/lab2-data-mining/setup_julia.ps1) tự động tải và giải nén môi trường.