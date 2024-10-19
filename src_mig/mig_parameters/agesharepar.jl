using CSV, DataFrames, Query, DelimitedFiles


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]

################## Prepare population data: original SSP ####################
ssp1 = CSV.read("../../Samir_data/SSP1.csv", DataFrame)
ssp2 = CSV.read("../../Samir_data/SSP2.csv", DataFrame)
ssp3 = CSV.read("../../Samir_data/SSP3.csv", DataFrame)
ssp4 = CSV.read("../../Samir_data/SSP4.csv", DataFrame)
ssp5 = CSV.read("../../Samir_data/SSP5.csv", DataFrame)

select!(ssp1, Not(:Column1))
select!(ssp2, Not(:Column1))
select!(ssp3, Not(:Column1))
select!(ssp4, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))
select!(ssp5, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))

ssp4[!,:scen] = repeat(["SSP4"], size(ssp4,1))
ssp5[!,:scen] = repeat(["SSP5"], size(ssp5,1))

select!(ssp4, [2,1,3,4,5,6,7,8,9])
select!(ssp5, [2,1,3,4,5,6,7,8,9])

# Join ssp datasets
ssp = vcat(ssp1, ssp2, ssp3, ssp4, ssp5)

# Replace missing values by zeros
for name in [:inmig, :outmig]
    for i in 1:length(ssp[!,name])
        if ssp[!,name][i] == "NA" 
            ssp[!,name][i] = "0"
        end
    end
    ssp[!,name] = map(x -> parse(Float64, x), ssp[!,name])
end

# Computing age of migrants at time of migration, using Samir's projection data
agegroup_c = combine(groupby(ssp, [:age, :region, :period, :scen]), d -> (inmig = sum(d.inmig), pop = sum(d.pop)))
agegroup_c[!,:region] = map(x -> parse(Int, SubString(x, 3)), agegroup_c[!,:region])

isonum_fundregion = CSV.read("../input_data/isonum_fundregion.csv", DataFrame)
rename!(isonum_fundregion, :isonum => :region)
agegroup_c = leftjoin(agegroup_c, isonum_fundregion, on = :region)

# The Channels Islands do not have a proper ISO code, instead Jersey (832, JEY) and Guernsey (831, GGY) do. 
# Based on census data for 2011, we attribute 60% of the Channels population to Jersey and the rest to Guernsey.
channelsind = findall(agegroup_c[!,:region] .== 830)
for i in channelsind
    push!(agegroup_c, [agegroup_c[!,:age][i], 831, agegroup_c[!,:period][i], agegroup_c[!,:scen][i], agegroup_c[!,:inmig][i]*0.4, agegroup_c[!,:pop][i]*0.4, "WEU"])
    push!(agegroup_c, [agegroup_c[!,:age][i], 832, agegroup_c[!,:period][i], agegroup_c[!,:scen][i], agegroup_c[!,:inmig][i]*0.6, agegroup_c[!,:pop][i]*0.6, "WEU"])
end
deleteat!(agegroup_c, channelsind)
select!(agegroup_c, [4,3,7,2,1,6,5])

agegroup = combine(groupby(agegroup_c, [:scen, :period, :fundregion, :age]), d -> (pop = sum(d.pop), inmig = sum(d.inmig)))

# Computing shares of migrants by age
ageshare = combine(groupby(agegroup, [:scen, :fundregion, :period]), d -> sum(d.inmig))
rename!(ageshare, :x1 => :inmig_sum)
agegroup = innerjoin(agegroup, ageshare, on = [:scen, :fundregion, :period])
agegroup[!,:share] = agegroup[!,:inmig] ./ agegroup[!,:inmig_sum]
for i in eachindex(agegroup[:,1]) ; if agegroup[!,:inmig][i] == 0 && agegroup[!,:inmig_sum][i] == 0 ; agegroup[!,:share][i] = 0 end end

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
agegroup = innerjoin(agegroup, regionsdf, on = :fundregion)
sort!(agegroup, [:scen, :period, :index, :age])

# When testing, we find that every region, for every time period and every scenario, has basically the same age distribution for migrants
# Thus we simplify and provide the agegroup parameter for the USA for SSP2 in 2015 as constant for all regions, time periods and scenarios
agegroup_simple = DataFrame(age=unique(agegroup[!,:age]), share=agegroup[1:length(unique(agegroup[!,:age])),:share])

# Linearizing age groups from 5-age to agely values. Note: a value for age x actually represents age group at the beginning of the five year period                                                
age_all = DataFrame(age = vcat(repeat(0:5:115, inner=5),[120]), ageall = 0:120)
age_all = innerjoin(age_all, agegroup_simple, on = :age)
age_all[:,:share] ./= 5

for i in 3:size(age_all,1)-3
    if mod(age_all[i,:ageall], 5) != 2 
        floor = age_all[i,:share] ; ceiling = age_all[min(i+5,121),:share]
        a = floor + (ceiling - floor) / 5 * (mod(age_all[i,:ageall], 5) - 2)
        age_all[i, :share] = a
    end
end
val1 = age_all[3,:share] * 5
a1 = (val1 - sum(age_all[3:5,:share])) / 2
for i in 1:2 ; age_all[i, :share] = a1 end
val2 = age_all[118,:share] * 5
a2 = (val2 - sum(age_all[118:120,:share])) / 2
for i in size(age_all,1)-2:size(age_all,1) ; age_all[i, :share] = a2 end

CSV.write("../data_mig/ageshare.csv", age_all[:,[:ageall,:share]]; writeheader=false)
CSV.write(joinpath(@__DIR__, "../input_data/agegroup.csv"), agegroup)