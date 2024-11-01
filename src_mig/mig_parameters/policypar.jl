using CSV, DataFrames, DelimitedFiles


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]


# Current border policy
onepar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    borderpol = ones(length(regions) * length(regions))
)
CSV.write(joinpath(@__DIR__,"../../data_mig/policy.csv"), onepar; writeheader=false)
CSV.write(joinpath(@__DIR__,"../../data_borderpolicy/policy_one.csv"), onepar; writeheader=false)


# Closed borders
zeropar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    borderpol = zeros(length(regions) * length(regions))
)
CSV.write(joinpath(@__DIR__,"../../data_borderpolicy/policy_zero.csv"), zeropar; writeheader=false)


# Open borders so that increase of migrants by 100%
twopar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    borderpol = repeat([2], length(regions) * length(regions))
)
CSV.write(joinpath(@__DIR__,"../../data_borderpolicy/policy_2.csv"), twopar; writeheader=false)


# Two-world situation: current policies within Global North and Global South, closed borders between North and South
halfpar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)),
    borderpol = zeros(length(regions) * length(regions))
)
for i in eachindex(halfpar[:,1])
    if ((indexin([halfpar[i,:source]],regions)[1] < 7) && (indexin([halfpar[i,:destination]],regions)[1] < 7)) || ((indexin([halfpar[i,:source]],regions)[1] > 6) && (indexin([halfpar[i,:destination]],regions)[1] > 6))
        halfpar[i,:borderpol] = 1
    else
        halfpar[i,:borderpol] = 0
    end
end
CSV.write(joinpath(@__DIR__,"../../data_borderpolicy/policy_half.csv"), halfpar; writeheader=false)


# Stress test: multiply migration flows by 100
stresstestpar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    borderpol = repeat([100], length(regions) * length(regions))
)
CSV.write(joinpath(@__DIR__,"../../data_borderpolicy/policy_stresstest.csv"), stresstestpar; writeheader=false)