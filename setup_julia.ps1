# setup_julia.ps1
# Tự động thiết lập môi trường Julia Portable cho dự án trên Windows

$ProgressPreference = 'SilentlyContinue'
$JuliaDir = Join-Path $PSScriptRoot "julia"

if (Test-Path $JuliaDir) {
    Write-Host "[THÔNG BÁO] Thư mục 'julia' đã tồn tại. Bỏ qua bước cài đặt." -ForegroundColor Yellow
    Write-Host "Bạn có thể chạy thử nghiệm ngay bằng lệnh:"
    Write-Host "  .\julia\bin\julia.exe src/run_test.jl" -ForegroundColor Cyan
    exit 0
}

$Url = "https://julialang-s3.julialang.org/bin/winnt/x64/1.10/julia-1.10.4-win64.zip"
$ZipFile = Join-Path $PSScriptRoot "julia.zip"
$ExtractDir = Join-Path $PSScriptRoot "julia_extracted"

Write-Host "Đang tải Julia 1.10.4 từ $Url..." -ForegroundColor Green
try {
    Invoke-WebRequest -Uri $Url -OutFile $ZipFile
} catch {
    Write-Error "Không thể tải file Julia. Vui lòng kiểm tra kết nối mạng của bạn."
    exit 1
}

Write-Host "Đang giải nén..." -ForegroundColor Green
try {
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractDir
    # Di chuyển thư mục đã giải nén về vị trí 'julia' trong dự án
    Move-Item -Path "$ExtractDir\julia-1.10.4" -Destination $JuliaDir
    # Dọn dẹp các thư mục/file tạm
    Remove-Item -Path $ExtractDir -Recurse -Force
    Remove-Item -Path $ZipFile -Force
    
    Write-Host "`n[THÀNH CÔNG] Cài đặt thành công môi trường Julia cục bộ!" -ForegroundColor Green
    Write-Host "Bạn có thể chạy thử nghiệm bằng lệnh:" -ForegroundColor Green
    Write-Host "  .\julia\bin\julia.exe src/run_test.jl" -ForegroundColor Cyan
} catch {
    Write-Error "Có lỗi xảy ra khi giải nén hoặc di chuyển thư mục."
    exit 1
}
