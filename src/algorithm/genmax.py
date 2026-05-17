# src/algorithm/genmax.py
from structures import VerticalDatabase

def has_superset(itemset, mfi_list):
    """
    Kiểm tra xem itemset có phải là tập con của bất kỳ tập nào trong mfi_list không.
    mfi_list chứa các tuple: (set, support)
    """
    for m, _ in mfi_list:
        if itemset.issubset(m):
            return True
    return False

def fi_diffset_combine(sup_x, payload_x, P_l_plus_1, min_sup, level):
    """
    Thuật toán FI-diffset-combine (Hình 8).
    - Nhận trực tiếp sup_x từ vòng lặp ngoài để tính đúng công thức:
        σ(y') = σ(x) - |d(y')|
    """
    C_l_plus_1 = []
    
    for y, payload_y, sup_y in P_l_plus_1:
        if level == 0:
            # level 0: d(y') = t(x) - t(y)
            d_y_prime = payload_x & ~payload_y
        else:
            # level > 0: d(y') = d(y) - d(x)
            d_y_prime = payload_y & ~payload_x
            
        # σ(y') = σ(x) - |d(y')|
        sup_y_prime = sup_x - d_y_prime.bit_count()
        
        if sup_y_prime >= min_sup:
            C_l_plus_1.append((y, d_y_prime, sup_y_prime))
            
    # Sắp xếp tăng dần theo support để tối ưu cắt tỉa
    C_l_plus_1.sort(key=lambda item: item[2])
    return C_l_plus_1

def lmfi_backtrack(I_l, C_l, LMFI_l, level, min_sup):
    """
    Thuật toán LMFI-backtrack (Hình 6).
    """
    for i, x_tuple in enumerate(C_l):
        x, payload_x, sup_x = x_tuple
        
        I_l_plus_1_items = I_l + [x]
        P_l_plus_1 = C_l[i+1:]
        
        # Superset Check (Hình 6, dòng 4-5):
        # Dùng return vì C_l được sắp xếp theo thứ tự tăng dần của support,
        # potential_max tại i+1 là tập con của potential_max tại i.
        # Nếu potential_max_i đã bị subsumed thì mọi nhánh sau cũng vậy
        # → return cắt toàn bộ nhánh còn lại, đúng với bài báo.
        potential_max = set(I_l_plus_1_items) | set(y[0] for y in P_l_plus_1)
        if has_superset(potential_max, LMFI_l):
            return
            
        LMFI_l_plus_1 = []
        
        C_l_plus_1 = fi_diffset_combine(sup_x, payload_x, P_l_plus_1, min_sup, level)
        
        if not C_l_plus_1:
            # Nút lá: kiểm tra maximal trước khi thêm vào LMFI
            current_set = set(I_l_plus_1_items)
            if not has_superset(current_set, LMFI_l):
                LMFI_l.append((current_set, sup_x))
        else:
            # Progressive Focusing (Hình 6, dòng 11):
            # Chỉ giữ lại các MFI chứa x để thu hẹp không gian kiểm tra
            LMFI_l_plus_1 = [M for M in LMFI_l if x in M[0]]
            lmfi_backtrack(I_l_plus_1_items, C_l_plus_1, LMFI_l_plus_1, level + 1, min_sup)
            
        # LMFI_l = LMFI_l ∪ LMFI_{l+1} (Hình 6, dòng 13)
        for M in LMFI_l_plus_1:
            if M not in LMFI_l:
                LMFI_l.append(M)

def genmax(data, minsup):
    """
    Thuật toán GenMax chính (Hình 9).
    """
    vdb = VerticalDatabase()
    vdb.build_from_horizontal(data)
    
    if isinstance(minsup, float):
        min_sup_count = int(vdb.num_transactions * minsup)
    else:
        min_sup_count = minsup

    # Bước 1: Tính F1
    F1 = {}
    for item, tidset in vdb.item_tidsets.items():
        sup = tidset.bit_count()
        if sup >= min_sup_count:
            F1[item] = (tidset, sup)
            
    # Bước 2: Tính F2 và IF(x)
    IF_count = {item: 0 for item in F1}
    f1_items = list(F1.keys())
    
    for i in range(len(f1_items)):
        item_i = f1_items[i]
        tidset_i = F1[item_i][0]
        for j in range(i + 1, len(f1_items)):
            item_j = f1_items[j]
            tidset_j = F1[item_j][0]
            
            sup_ij = (tidset_i & tidset_j).bit_count()
            if sup_ij < min_sup_count:
                IF_count[item_i] += 1
                IF_count[item_j] += 1

    # Bước 3: Sắp xếp F1 (IF(x) giảm dần, support tăng dần) — Hình 9, dòng 4
    C_0 = [(item, F1[item][0], F1[item][1]) for item in F1]
    C_0.sort(key=lambda x: (-IF_count[x[0]], x[2]))

    # Bước 4-6: Khởi tạo MFI và gọi LMFI-backtrack
    MFI = []
    lmfi_backtrack([], C_0, MFI, 0, min_sup_count)
    
    # Format kết quả: support đã được lưu sẵn, không cần tính lại
    results = [(sorted(list(mfi_set)), sup) for mfi_set, sup in MFI]
    return results

if __name__ == "__main__":
    # Test Data từ Ví dụ 1 trong bài báo (Hình 1)
    toy_data = [
        ['A', 'C', 'T', 'W'],
        ['C', 'D', 'W'],
        ['A', 'C', 'T', 'W'],
        ['A', 'C', 'D', 'W'],
        ['A', 'C', 'D', 'T', 'W'],
        ['C', 'D', 'T']
    ]
    
    print("Running GenMax...")
    
    results_min3 = genmax(toy_data, 3)
    print("MFI (minsup=3):", results_min3)
    # Kỳ vọng theo Hình 1: [ACTW, CDW]
    
    results_min2 = genmax(toy_data, 2)
    print("MFI (minsup=2):", results_min2)
    # Kỳ vọng theo Hình 1: [ACDW, ACTW, CDT] (hoặc tương đương)