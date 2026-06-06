# src/structures.jl
module Structures

export VerticalDatabase, build_from_horizontal!

mutable struct VerticalDatabase{T}
    item_tidsets::Dict{T, BitSet}
    num_transactions::Int
end

# Constructors
VerticalDatabase{T}() where T = VerticalDatabase{T}(Dict{T, BitSet}(), 0)
VerticalDatabase() = VerticalDatabase{Any}()

"""
Builds a vertical database from horizontal transactions.
Transactions are represented as vectors of items of type T.
"""
function build_from_horizontal!(vdb::VerticalDatabase{T}, data::AbstractVector{<:AbstractVector{T}}) where T
    vdb.num_transactions = length(data)
    for (tid, transaction) in enumerate(data)
        for item in transaction
            if !haskey(vdb.item_tidsets, item)
                vdb.item_tidsets[item] = BitSet()
            end
            push!(vdb.item_tidsets[item], tid)
        end
    end
end

end # module
