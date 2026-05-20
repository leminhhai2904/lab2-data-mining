import random
from utils import read_spmf_file
import os

def generate_subsets(input_file: str, percentages=[10, 25, 50, 75, 100]):
    data = read_spmf_file(input_file)
    n = len(data)
    base_name = os.path.basename(input_file).split('.')[0]
    os.makedirs("data/subsets", exist_ok=True)
    
    for p in percentages:
        size = int(n * p / 100)
        subset = random.sample(data, size) if p < 100 else data
        output_file = f"data/subsets/{base_name}_{p}pct.txt"
        
        with open(output_file, "w") as f:
            for trans in subset:
                f.write(" ".join(map(str, trans)) + "\n")
        print(f"Tạo subset {p}%: {len(subset)} transactions → {output_file}")