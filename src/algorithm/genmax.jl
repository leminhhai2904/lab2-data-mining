# src/algorithm/genmax.jl
module GenMaxAlgo

using ..Structures

export genmax

"""
Checks if itemset is a subset of any set in mfi_list.
"""
function has_superset(itemset::Set{T}, mfi_list::Vector{Tuple{Set{T},Int}}) where T
    for (m, _) in mfi_list
        if issubset(itemset, m)
            return true
        end
    end
    return false
end

"""
FI-diffset-combine (Figure 8 in GenMax paper).
"""
function fi_diffset_combine(sup_x::Int, payload_x::BitSet, P_l_plus_1::Vector{Tuple{T,BitSet,Int}}, min_sup::Int, level::Int) where T
    C_l_plus_1 = Tuple{T,BitSet,Int}[]

    for (y, payload_y, sup_y) in P_l_plus_1
        if level == 0
            # Level 0: d(y') = t(x) - t(y)
            d_y_prime = setdiff(payload_x, payload_y)
        else
            # Level > 0: d(y') = d(y) - d(x)
            d_y_prime = setdiff(payload_y, payload_x)
        end

        sup_y_prime = sup_x - length(d_y_prime)

        if sup_y_prime >= min_sup
            push!(C_l_plus_1, (y, d_y_prime, sup_y_prime))
        end
    end

    # Sort ascending by support to optimize pruning
    sort!(C_l_plus_1, by=x -> x[3])
    return C_l_plus_1
end

"""
LMFI-backtrack (Figure 6 in GenMax paper).
"""
function lmfi_backtrack(I_l::Vector{T}, C_l::Vector{Tuple{T,BitSet,Int}}, LMFI_l::Vector{Tuple{Set{T},Int}}, level::Int, min_sup::Int) where T
    for (i, x_tuple) in enumerate(C_l)
        x, payload_x, sup_x = x_tuple

        I_l_plus_1_items = [I_l; x]
        P_l_plus_1 = C_l[(i+1):end]

        potential_max = union(Set(I_l_plus_1_items), Set(y[1] for y in P_l_plus_1))
        if has_superset(potential_max, LMFI_l)
            return
        end

        LMFI_l_plus_1 = Tuple{Set{T},Int}[]
        C_l_plus_1 = fi_diffset_combine(sup_x, payload_x, P_l_plus_1, min_sup, level)

        if isempty(C_l_plus_1)
            current_set = Set(I_l_plus_1_items)
            if !has_superset(current_set, LMFI_l)
                push!(LMFI_l, (current_set, sup_x))
            end
        else
            # Progressive Focusing: only keep MFIs containing x to narrow check space
            for M in LMFI_l
                if x in M[1]
                    push!(LMFI_l_plus_1, M)
                end
            end
            lmfi_backtrack(I_l_plus_1_items, C_l_plus_1, LMFI_l_plus_1, level + 1, min_sup)
        end

        # LMFI_l = LMFI_l ∪ LMFI_{l+1}
        for M in LMFI_l_plus_1
            if M ∉ LMFI_l
                push!(LMFI_l, M)
            end
        end
    end
end

"""
Main GenMax algorithm (Figure 9 in GenMax paper).
"""
function genmax(data::AbstractVector{<:AbstractVector{T}}, minsup) where T
    vdb = VerticalDatabase{T}()
    build_from_horizontal!(vdb, data)

    min_sup_count = 0
    if minsup isa AbstractFloat
        min_sup_count = max(1, Int(floor(vdb.num_transactions * minsup)))
    else
        min_sup_count = Int(minsup)
    end

    # Step 1: Compute F1
    F1 = Dict{T,Tuple{BitSet,Int}}()
    for (item, tidset) in vdb.item_tidsets
        sup = length(tidset)
        if sup >= min_sup_count
            F1[item] = (tidset, sup)
        end
    end

    # Step 2: Compute F2 and IF(x)
    IF_count = Dict{T,Int}(item => 0 for item in keys(F1))
    f1_items = collect(keys(F1))

    @inbounds for i in 1:length(f1_items)
        item_i = f1_items[i]
        tidset_i = F1[item_i][1]
        @inbounds @simd for j in (i+1):length(f1_items)
            item_j = f1_items[j]
            tidset_j = F1[item_j][1]

            sup_ij = length(intersect(tidset_i, tidset_j))
            if sup_ij < min_sup_count
                IF_count[item_i] += 1
                IF_count[item_j] += 1
            end
        end
    end

    # Step 3: Sort F1 (IF(x) descending, support ascending)
    C_0 = Tuple{T,BitSet,Int}[]
    for item in keys(F1)
        push!(C_0, (item, F1[item][1], F1[item][2]))
    end

    # Sort key: (-IF_count[x[1]], x[3])
    sort!(C_0, by=x -> (-IF_count[x[1]], x[3]))

    # Step 4-6: Init MFI and call LMFI-backtrack
    MFI = Tuple{Set{T},Int}[]
    lmfi_backtrack(T[], C_0, MFI, 0, min_sup_count)

    # Format results: sort items within each MFI for comparison correctness
    results = Tuple{Vector{T},Int}[]
    for (mfi_set, sup) in MFI
        push!(results, (sort(collect(mfi_set)), sup))
    end

    return results
end

end # module
