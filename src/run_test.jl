# src/run_test.jl
# Include source files (relative to this script's directory)
include("structures.jl")
include("algorithm/genmax.jl")

using .Structures
using .GenMaxAlgo

# Test data from Figure 1 of the GenMax paper
toy_data = [
    ["A", "C", "T", "W"],
    ["C", "D", "W"],
    ["A", "C", "T", "W"],
    ["A", "C", "D", "W"],
    ["A", "C", "D", "T", "W"],
    ["C", "D", "T"]
]

println("=========================================")
println("        GENMAX IN JULIA TEST")
println("=========================================")

println("\n--- Running with minsup = 3 (Absolute) ---")
results_min3 = genmax(toy_data, 3)
println("Found ", length(results_min3), " MFIs:")
for (itemset, sup) in results_min3
    println("  {", join(itemset, ", "), "} #SUP: ", sup)
end

println("\n--- Running with minsup = 2 (Absolute) ---")
results_min2 = genmax(toy_data, 2)
println("Found ", length(results_min2), " MFIs:")
for (itemset, sup) in results_min2
    println("  {", join(itemset, ", "), "} #SUP: ", sup)
end
println("=========================================")
