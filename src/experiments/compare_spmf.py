import sys
import os
from pathlib import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from utils import read_spmf_file

def parse_spmf_output(filepath):
    """Đọc file output của SPMF hoặc GenMax"""
    results = {}
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '#SUP:' in line:
                parts = line.split('#SUP:')
                itemset_str = parts[0].strip()
                sup = int(parts[1].strip())
                itemset = tuple(sorted(map(int, itemset_str.split())))
                results[itemset] = sup
    return results

def compare_results(our_file, spmf_file):
    our = parse_spmf_output(our_file)
    spmf = parse_spmf_output(spmf_file)
    
    print(f"\n=== SO SÁNH CORRECTNESS ===")
    print(f"Our GenMax   : {len(our)} MFI")
    print(f"SPMF         : {len(spmf)} MFI")
    
    common = set(our.keys()) & set(spmf.keys())
    only_our = set(our.keys()) - set(spmf.keys())
    only_spmf = set(spmf.keys()) - set(our.keys())
    
    print(f"Khớp nhau    : {len(common)}")
    print(f"Chỉ GenMax   : {len(only_our)}")
    print(f"Chỉ SPMF     : {len(only_spmf)}")
    
    if len(our) == len(spmf) and len(only_our) == 0 and len(only_spmf) == 0:
        print("✅ HOÀN HẢO - Kết quả khớp 100% với SPMF!")
    else:
        print("⚠️  Có sai lệch, cần kiểm tra code.")

if __name__ == "__main__":
    # Ví dụ sử dụng:
    compare_results("results/chess_mfi_our.txt", "results/chess_mfi_spmf.txt")