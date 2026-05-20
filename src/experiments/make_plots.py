import pandas as pd
import matplotlib.pyplot as plt
import os

def plot_results(results_dir="results"):
    plt.rcParams['figure.figsize'] = (12, 8)
    files = [f for f in os.listdir(results_dir) if f.endswith("_experiment.csv")]
    
    for file in files:
        df = pd.read_csv(f"{results_dir}/{file}")
        dataset = df['dataset'].iloc[0]
        
        # Plot 1: Time vs Minsup
        plt.figure()
        plt.plot(df['minsup'], df['time_ms'], marker='o', label='GenMax')
        plt.title(f'Thời gian chạy theo minsup - {dataset}')
        plt.xlabel('Minsup')
        plt.ylabel('Thời gian (ms)')
        plt.grid(True)
        plt.legend()
        plt.savefig(f"{results_dir}/{dataset}_time.png")
        plt.close()
        
        # Plot 2: Num MFI vs Minsup
        plt.figure()
        plt.plot(df['minsup'], df['num_mfi'], marker='s', color='green')
        plt.title(f'Số lượng MFI theo minsup - {dataset}')
        plt.xlabel('Minsup')
        plt.ylabel('Số MFI')
        plt.grid(True)
        plt.savefig(f"{results_dir}/{dataset}_mfi_count.png")
        plt.close()
    
    print("Đã tạo tất cả biểu đồ trong thư mục results/")

if __name__ == "__main__":
    plot_results()