import time
import psutil
import os
import gc
import pandas as pd
import sys
from pathlib import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from utils import read_spmf_file, parse_minsup
from genmax import genmax


def get_memory_mb():
    return psutil.Process(os.getpid()).memory_info().rss / (1024 * 1024)


def run_experiment(dataset_path: str, minsup_list: list, output_dir="results"):
    os.makedirs(output_dir, exist_ok=True)
    dataset_name = Path(dataset_path).stem
    
    print(f"\n{'='*80}")
    print(f"ĐANG CHẠY THỰC NGHIỆM TRÊN: {dataset_name.upper()}")
    print(f"{'='*80}")
    
    data = read_spmf_file(dataset_path)
    n_trans = len(data)
    records = []
    
    for minsup_str in minsup_list:
        gc.collect()
        mem_before = get_memory_mb()
        start_time = time.perf_counter()
        
        try:
            minsup_abs = parse_minsup(minsup_str, n_trans)
            results = genmax(data, minsup_abs)
            elapsed = time.perf_counter() - start_time
            mem_peak = get_memory_mb() - mem_before
            
            record = {
                "dataset": dataset_name,
                "minsup": minsup_str,
                "minsup_abs": minsup_abs,
                "num_mfi": len(results),
                "time_ms": round(elapsed * 1000, 2),
                "peak_mem_mb": round(mem_peak, 2)
            }
            records.append(record)
            
            print(f"✓ {minsup_str:6} | MFI: {len(results):4} | "
                  f"Time: {elapsed*1000:8.1f} ms | Mem: {mem_peak:6.1f} MB")
            
        except Exception as e:
            print(f"✗ Lỗi {minsup_str}: {e}")
            continue
    
    df = pd.DataFrame(records)
    csv_path = f"{output_dir}/{dataset_name}_experiment.csv"
    df.to_csv(csv_path, index=False)
    print(f"✅ Hoàn thành {dataset_name} → {csv_path}")
    return df


if __name__ == "__main__":
    # ================== CẤU HÌNH ==================
    minsup_values = ["50%", "30%", "20%", "10%", "5%"]   # Giảm bớt cho nhanh
    
    datasets = [
        "data/benchmark/chess.dat",
        "data/benchmark/mushroom.dat",
        # "data/benchmark/retail.dat",      # Chạy sau, dataset lớn
        # "data/benchmark/accidents.dat",   # Rất lớn, chạy cuối
    ]
    
    for ds in datasets:
        run_experiment(ds, minsup_values)