using CSV, DataFrames, Statistics


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]


# Calculating population weights based on country level population data in 2015 from the UN World Population Prospects 2019
pop_allvariants = CSV.read(joinpath(@__DIR__, "../input_data/WPP2019.csv"), DataFrame)
# We use the Medium variant, the most commonly used. Unit: thousands
pop2015 = @from i in pop_allvariants begin
    @where i.Variant == "Medium" && i.Time == 2015
    @select {i.LocID, i.Location, i.PopTotal}
    @collect DataFrame
end

# The Channels Islands do not have a proper ISO code, instead Jersey (832) and Guernsey (831) do. 
# Based on census data for 2011, we attribute 60% of the Channels population to Jersey and the rest to Guernsey.
channelsind = findfirst(pop2015[!,:LocID] .== 830)
pop2015 = push!(pop2015, [831, "Guernsey", pop2015[channelsind,:PopTotal]*0.4])
pop2015 = push!(pop2015, [832, "Jersey", pop2015[channelsind,:PopTotal]*0.6])
pop2015 = pop2015[[1:(channelsind-1); (channelsind+1:end)],:]
rename!(pop2015, :LocID => :isonum, :Location => :country, :PopTotal => :pop)

isonum_fundregion = CSV.read("../input_data/isonum_fundregion.csv", DataFrame)
pop2015weight = innerjoin(pop2015, isonum_fundregion, on = :isonum)
weight = combine(groupby(pop2015weight, :fundregion), df -> sum(df[!,:pop]))
pop2015weight[!,:weight] = [pop2015weight[i,:pop] / weight[!,:x1][findfirst(weight[!,:fundregion] .== pop2015weight[i,:fundregion])] for i in eachindex(pop2015weight[:,1])]


# Calculating life expectancy scenarios at region level
# Data on SSP scenarios life expectancy is available from Wittgenstein Centre for 1950-2100. 
# We provide all SSP but have used SSP2 so far.  
# We assume constant life expectancy after 2100

lifeexp = CSV.read(joinpath(@__DIR__,"../input_data/lifeexp.csv"), DataFrame; header=9)
select!(lifeexp, Not(:Area))
lifeexp[!,:Period] = map( x -> parse(Int, SubString(x, 1:4)), lifeexp[!,:Period])
lifeexp = combine(groupby(lifeexp, [:Scenario, :Period, :ISOCode]), d -> mean(d.Years))               # Compute life expectancy for overall population as average between male and female
rename!(lifeexp, :x1 => :lifeexp)

# The Channels Islands do not have a proper ISO code, instead Jersey (832, JEY) and Guernsey (831, GGY) do. 
channelsind = findall(lifeexp[!,:ISOCode] .== 830)
for i in channelsind
    push!(lifeexp, [lifeexp[!,:Scenario][i], lifeexp[!,:Period][i], 831, lifeexp[!,:lifeexp][i]])
    push!(lifeexp, [lifeexp[!,:Scenario][i], lifeexp[!,:Period][i], 832, lifeexp[!,:lifeexp][i]])
end
deleteat!(lifeexp, channelsind)
deleteat!(lifeexp, findall(lifeexp[!,:ISOCode] .== 900))        # Delete data for world
sort!(lifeexp, [:Scenario, :Period, :ISOCode])

# I only have data for SSP1,2,3, but based on mortality assumptions mentioned in KC and Lutz (2017), I assume that SSP4 ~ SSP2, and SSP5 ~ SSP1
lifeexp_ssp4 = lifeexp[(lifeexp[!,:Scenario] .== "SSP2"),:]
lifeexp_ssp4[!,:Scenario] = repeat(["SSP4"], size(lifeexp_ssp4,1))
lifeexp_ssp5 = lifeexp[(lifeexp[!,:Scenario] .== "SSP1"),:]
lifeexp_ssp5[!,:Scenario] = repeat(["SSP5"], size(lifeexp_ssp5,1))
lifeexp = vcat(lifeexp, lifeexp_ssp4)
lifeexp = vcat(lifeexp, lifeexp_ssp5)

rename!(lifeexp, :ISOCode => :isonum, :Scenario => :scen, :Period => :year)
ssps = unique(lifeexp[!,:scen])

# Averaging with population weights at region level
lifeexp = innerjoin(lifeexp, pop2015weight[:,[:isonum, :fundregion, :weight]], on = :isonum)
lifeexp = combine(groupby(lifeexp, [:scen, :year, :fundregion]), df -> sum(df[!,:lifeexp] .* df[!,:weight]))
lifeexp = rename(lifeexp, :x1 => :lifeexp)
sort!(lifeexp,[:scen, :fundregion, :year])

# Linearizing life expectancy data from 5-year averages to yearly values at country level. Note: a value for year x actually represents the average over period [x; x+5].
yearsmissing = append!(filter(a -> mod(a,5) .!= 0, 1950:2100),[2100])
yearsgiven = filter(a -> mod(a,5) .==0, 1950:2095)
for scen in ssps
    for region in regions                                                         
        regionsel = lifeexp[.&(lifeexp[!,:fundregion] .== region, lifeexp[!,:scen] .== scen),:]
        lifeexpfinal = []
        for year in yearsmissing
            if year < 1953
                floor = regionsel[1,:lifeexp] ; ceiling = regionsel[2,:lifeexp]
                lifeexpregion = floor + (ceiling - floor) / 5 * (mod(year, 5) - 2.5)
                push!(lifeexp, [scen, year, region, lifeexpregion])
            elseif year < 2098
                ind = Int((year - 2.5 - mod(year - 2.5, 5) - 1950) / 5 + 1)
                floor = regionsel[ind,:lifeexp] ; ceiling = regionsel[ind+1,:lifeexp]
                lifeexpregion = floor + (ceiling - floor) / 5 * (mod(year - 2.5, 5))
                push!(lifeexp, [scen, year, region, lifeexpregion])
            elseif year < 2101
                floor = regionsel[size(regionsel,1),:lifeexp] ; subfloor = regionsel[size(regionsel,1)-1,:lifeexp]
                lifeexpregion = subfloor + (floor - subfloor) / 5 * (mod(year, 5) + 2.5)
                push!(lifeexp, [scen, year, region, lifeexpregion])
                if year == 2100 ; append!(lifeexpfinal,[lifeexpregion]) end
            end
        end
        lifeexp05 = []
        for year in yearsgiven
            if year == 1950
                floor = regionsel[1,:lifeexp] ; ceiling = regionsel[2,:lifeexp]
                lifeexpregion = floor - (ceiling - floor) / 5 * 2.5
                append!(lifeexp05, [lifeexpregion])
            else
                ind = Int((year - 1950) / 5 + 1)
                floor = regionsel[ind-1,:lifeexp] ; ceiling = regionsel[ind,:lifeexp]
                lifeexpregion = floor + (ceiling - floor) / 5 * 2.5
                append!(lifeexp05, [lifeexpregion])
            end
        end
        for year in yearsgiven
            ind = Int((year - 1950) / 5 + 1)
            regionsel[ind,:lifeexp] = lifeexp05[ind]
        end
        for year in 2101:3000
            push!(lifeexp, [scen, year, region, lifeexpfinal[1]])
        end
    end
end

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
lifeexp = innerjoin(lifeexp, regionsdf, on = :fundregion)
sort!(lifeexp, [:scen, :year, :index])

# Write data for each SSP separately
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen/lifeexp_", s, ".csv")), lifeexp[(lifeexp[:,:scen].==s),[:year, :fundregion, :lifeexp]]; writeheader=false)
end