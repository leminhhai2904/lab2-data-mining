import argparse
import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "algorithm"))

# pyrefly: ignore [missing-import]
from genmax import genmax

# 1. ĐỌC FILE ĐỊNH DẠNG SPMF

def read_spmf_file(filepath: str) -> list[list[int]]:
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Không tìm thấy file: {filepath}")

    data = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, start=1):
            line = line.strip()

            if not line or line.startswith("#"):
                continue

            try:
                transaction = list(map(int, line.split()))
            except ValueError:
                raise ValueError(
                    f"Dòng {line_no} chứa giá trị không hợp lệ: '{line}'. "
                    "Các item phải là số nguyên."
                )

            if transaction:
                data.append(transaction)

    if not data:
        raise ValueError(f"File '{filepath}' không chứa giao dịch nào hợp lệ.")

    return data


# 2. GHI KẾT QUẢ ĐỊNH DẠNG SPMF

def write_spmf_output(results: list[tuple], filepath: str) -> None:
    dirpath = os.path.dirname(filepath)
    if dirpath:
        os.makedirs(dirpath, exist_ok=True)

    with open(filepath, "w", encoding="utf-8") as f:
        for itemset, support in results:
            items_str = " ".join(map(str, itemset))
            f.write(f"{items_str} #SUP: {support}\n")


# 3. PARSE THAM SỐ MINSUP

def parse_minsup(minsup_str: str, num_transactions: int) -> int:
    minsup_str = minsup_str.strip()

    try:
        if minsup_str.endswith("%"):
            ratio = float(minsup_str[:-1]) / 100.0
            if not (0 < ratio <= 1):
                raise ValueError("Phần trăm minsup phải nằm trong khoảng (0%, 100%].")
            return max(1, int(ratio * num_transactions))

        value = float(minsup_str)
        if 0 < value < 1:
            # Dạng tỉ lệ thập phân
            return max(1, int(value * num_transactions))
        elif value >= 1:
            # Dạng số nguyên tuyệt đối
            return int(value)
        else:
            raise ValueError("minsup phải > 0.")

    except ValueError as e:
        raise ValueError(f"Giá trị minsup không hợp lệ: '{minsup_str}'. {e}")


# 4. IN KẾT QUẢ RA CONSOLE

def print_results(results: list[tuple], minsup_abs: int, elapsed: float) -> None:
    print(f"\n{'─' * 45}")
    print(f"  Kết quả GenMax")
    print(f"{'─' * 45}")
    print(f"  minsup (tuyệt đối) : {minsup_abs}")
    print(f"  Số MFI tìm được    : {len(results)}")
    print(f"  Thời gian chạy     : {elapsed * 1000:.2f} ms")
    print(f"{'─' * 45}")

    if results:
        print("  Maximal Frequent Itemsets:")
        for itemset, sup in sorted(results, key=lambda x: (len(x[0]), x[0])):
            items_str = " ".join(map(str, itemset))
            print(f"    {{{items_str}}}  #SUP: {sup}")
    else:
        print("  (Không tìm được MFI nào với minsup này.)")

    print(f"{'─' * 45}\n")


# 5. ENTRY POINT — THAM SỐ DÒNG LỆNH

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="genmax",
        description="Khai thác Maximal Frequent Itemsets bằng thuật toán GenMax.",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=(
            "Ví dụ:\n"
            "  python utils.py --input data/retail.txt --minsup 1%  --output out/retail_mfi.txt\n"
            "  python utils.py --input data/chess.txt  --minsup 50% --output out/chess_mfi.txt\n"
            "  python utils.py --input data/toy.txt    --minsup 3   --output out/toy_mfi.txt\n"
        ),
    )

    parser.add_argument(
        "--input", "-i",
        required=True,
        metavar="FILE",
        help="Đường dẫn tới file input định dạng SPMF (.txt).",
    )
    parser.add_argument(
        "--minsup", "-m",
        required=True,
        metavar="MINSUP",
        help=(
            "Ngưỡng support tối thiểu.\n"
            "  Dạng phần trăm  : '50%%' hoặc '0.5'\n"
            "  Dạng tuyệt đối  : '3' (số giao dịch)\n"
        ),
    )
    parser.add_argument(
        "--output", "-o",
        required=True,
        metavar="FILE",
        help="Đường dẫn tới file output để ghi kết quả.",
    )
    parser.add_argument(
        "--quiet", "-q",
        action="store_true",
        help="Không in kết quả ra console, chỉ ghi file.",
    )

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()

    print(f"Đọc dữ liệu từ: {args.input}")
    try:
        data = read_spmf_file(args.input)
    except (FileNotFoundError, ValueError) as e:
        print(f"[LỖI] {e}", file=sys.stderr)
        sys.exit(1)

    num_transactions = len(data)
    print(f"{num_transactions} giao dịch được nạp.")

    try:
        minsup_abs = parse_minsup(args.minsup, num_transactions)
    except ValueError as e:
        print(f"[LỖI] {e}", file=sys.stderr)
        sys.exit(1)

    print(f"Chạy GenMax  (minsup = {args.minsup} = {minsup_abs} giao dịch)...")

    start = time.perf_counter()
    results = genmax(data, minsup_abs)
    elapsed = time.perf_counter() - start

    print(f"Ghi kết quả ra: {args.output}")
    try:
        write_spmf_output(results, args.output)
    except OSError as e:
        print(f"[LỖI] Không thể ghi file: {e}", file=sys.stderr)
        sys.exit(1)

    if not args.quiet:
        print_results(results, minsup_abs, elapsed)
    else:
        print(f"Tìm được {len(results)} MFI trong {elapsed * 1000:.2f} ms.")

    print("Hoàn thành.")


if __name__ == "__main__":
    main()