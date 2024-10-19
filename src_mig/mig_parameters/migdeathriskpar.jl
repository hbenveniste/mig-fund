using CSV, DataFrames, ExcelFiles, XLSX


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
ind = Dict(regions[i] => i for i in eachindex(regions))


# Calculating the risk of dying while attempting to migrate across borders: 
# We use data on migration flows between regions in period 2010-2015 from Azose and Raftery (2018) as processed in Abel and Cohen (2019)
# And data on missing migrants in period 2014-2018 from IOM (http://missingmigrants.iom.int/). Retrieved on 10/3/2018.

# Calculating migrant flows at FUND regions level 
migflow_alldata = CSV.read(joinpath(@__DIR__, "../input_data/ac19.csv"), DataFrame)          # Use Abel and Cohen (2019)
# From Abel and Cohen's paper, I choose Azose and Raftery's data for 1990-2015, on Guy Abel's suggestion (based a demographic accounting, pseudo-Bayesian method, which performs the best)
migflow = migflow_alldata[(migflow_alldata[:,:year0].==2010),[:orig, :dest, :da_pb_closed]]
rename!(migflow, :da_pb_closed => :flow)

iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv", DataFrame)
rename!(iso3c_fundregion, :iso3c => :orig)
migflow = innerjoin(migflow, iso3c_fundregion, on = :orig)
rename!(migflow, :fundregion => :originregion)
rename!(iso3c_fundregion, :orig => :dest)
migflow = innerjoin(migflow, iso3c_fundregion, on = :dest)
rename!(migflow, :fundregion => :destinationregion)

migflow_reg = combine(groupby(migflow, [:originregion, :destinationregion]), df -> sum(df.flow))
rename!(migflow_reg, :originregion => :origin, :destinationregion => :destination, :x1 => :flows)
regionsdf = DataFrame(origin = repeat(regions, inner = length(regions)), destination = repeat(regions, outer = length(regions)), index = 1:16^2)
migflow_reg = innerjoin(migflow_reg, regionsdf, on = [:origin, :destination])
sort!(migflow_reg, :index)
select!(migflow_reg, Not(:index))

migflows = combine(groupby(migflow_reg, [:origin, :destination]), df -> df.flows ./ 5)  # Get yearly estimates
rename!(migflows, :x1 => :flows)
CSV.write("../input_data/migflows.csv", migflows)     

flows = transpose(migflows[eachindex(regions),:flows])
# Error with vcat
for i in 1:(length(regions) - 1)
    flows = vcat(flows, transpose(migflows[(i*length(regions)+1):(i*length(regions)+length(regions)),:flows]))
end


# NOTE: we assume that migrants died in their destination region. E.g. if a Central American dies in Central America on its way to the USA, we attribute it to a CAM-CAM journey.
# The only exception is for migrants dead in the Mediterranean, which we attribute to journeys to WEU.

migdeath = XLSX.readdata(joinpath(@__DIR__, "../../input_data/migrant-deaths-by-origin-region.xlsx"), "migrant-deaths-by-origin-region!A1:CC22")
header = 4
origin_regions = migdeath[header:(length(migdeath[:,1]) - 1), 1]
ind_dr = [2 + length(2014:2018) * i for i in 0:(round(Int, length(migdeath[1, :]) / length(2014:2018)) - 1)]
deaths_regions = [] ; deaths_regions = append!(deaths_regions, migdeath[2, ind_dr[i]] for i in eachindex(ind_dr))

death_journey = DataFrame(origin = repeat(origin_regions, inner = length(2014:2018) * length(deaths_regions)), 
                                    deathloc = repeat(deaths_regions, inner = length(2014:2018), outer = length(origin_regions)),
                                    year = repeat(2014:2018, outer = length(origin_regions) * length(deaths_regions)))
missingmigrants = []
for o in header:(length(origin_regions) + header - 1)
    omm = migdeath[o, 2:end]
    for i in eachindex(omm)
        if ismissing(omm[i]) ; omm[i] = 0 end      
    end
    append!(missingmigrants, omm)
end
death_journey[!,:missing] = missingmigrants

# Sum migrant deaths over the period 2014-2018
death_journey = combine(groupby(death_journey, [:origin, :deathloc]), df -> sum(df.missing))
rename!(death_journey, :x1 => :missing)

# Corresponding regions in the data on missing migrants with FUND regions

# Origin: no category for USA, CAN and ANZ. Assume other countries in FSU not in Central Asia are not relevant. Assume migrant deaths of SIS happen in the Caribbean. 
# We affect Europe to WEU and East Asia to CHI. No dead migrant from East Asia. We deal with EEU below.
origin_fund = DataFrame(
    fund = regions, 
    origin = ["","",origin_regions[1],"","","",origin_regions[9],origin_regions[6],origin_regions[16],origin_regions[17],origin_regions[10],origin_regions[11],origin_regions[12],origin_regions[2],origin_regions[5],origin_regions[15]]
)

# Place of death: no category for ANZ. Based on detailed IOM data, the dead migrant in North America died in the USA.
# We affect Europe to WEU and East Asia to CHI. Based on detailed IOM data, migrant deaths to East Asia all happened in CHI region. We deal with EEU below.
death_fund = DataFrame(
    fund = regions, 
    deathloc = [deaths_regions[4],"",deaths_regions[13],"","","",deaths_regions[9],deaths_regions[16],deaths_regions[6],deaths_regions[8],deaths_regions[12],deaths_regions[11],deaths_regions[10],deaths_regions[1],deaths_regions[3],deaths_regions[7]]
)

death_journey = leftjoin(death_journey, origin_fund, on = :origin)
rename!(death_journey, :fund => :origin_f)
death_journey = leftjoin(death_journey, death_fund, on = :deathloc)
rename!(death_journey, :fund => :deathloc_f)

for i in eachindex(death_journey[:,1])
    if ismissing(death_journey[i,:origin_f]) == true
        death_journey[i,:origin_f] = ""
    end
    if ismissing(death_journey[i,:deathloc_f]) == true
        death_journey[i,:deathloc_f] = ""
    end
end

# Convert migrant deaths to FUND regions level 
deaths = zeros(16, 16)

for i in eachindex(death_journey[:,1])
    if death_journey[i,:origin_f] != "" && death_journey[i,:deathloc_f] != ""
        o = death_journey[i,:origin_f] ; d = death_journey[i,:deathloc_f]
        deaths[ind[o], ind[d]] = death_journey[i,:missing]
    end
end

# Assume the dead migrant from Europe died on EEU-WEU journey. 
deaths[ind["EEU"], ind["WEU"]] = deaths[ind["WEU"], ind["WEU"]]
deaths[ind["WEU"], ind["WEU"]] = 0.0

# Attributing migrants by origin not directly corresponding to FUND regions
for d in intersect(unique(death_journey[!,:deathloc_f]),regions)
    for (o1, o2) in [("SSA", "Horn of Africa"), ("SSA", "Horn of Africa (P)"), ("CHI", "East Asia (P)")]
        deaths[ind[o1], ind[d]] += death_journey[findfirst([death_journey[i,:origin] == o2 && death_journey[i,:deathloc_f] == d for i in eachindex(death_journey[:,1])]),:missing]
    end
    dmde = deaths[ind["MDE"], ind[d]] ; dsas = deaths[ind["SAS"], ind[d]]
    for (o1, o2) in [(i, j) for i in ["MDE", "SAS"], j in ["Middle East and South Asia", "Middle East and South Asia (P)"]]
        deaths[ind[o1], ind[d]] += iszero(dmde + dsas) != true ? death_journey[findfirst([death_journey[i,:origin] == o2 && death_journey[i,:deathloc_f] == d for i in eachindex(death_journey[:,1])]),:missing] * (o1 == "MDE" ? dmde : dsas) / (dmde + dsas) : 0.0
    end
    dcam = deaths[ind["CAM"], ind[d]] ; dlam = deaths[ind["LAM"], ind[d]] ; dsis = deaths[ind["SIS"], ind[d]]
    for (o1, o2) in [(i, j) for i in ["CAM", "LAM", "SIS"], j in ["Latin America and the Caribbean (P)"]] 
        deaths[ind[o1], ind[d]] += iszero(dcam + dlam + dsis) != true ? death_journey[findfirst([death_journey[i,:origin] == o2 && death_journey[i,:deathloc_f] == d for i in eachindex(death_journey[:,1])]),:missing] * (o1 == "CAM" ? dcam : (o1 == "LAM" ? dlam : dsis)) / (dcam + dlam + dsis) : 0.0
    end
end

# We attribute missing migrants of unknown origin proportionally to origins of known missing migrants in the region
for d in intersect(unique(death_journey[!,:deathloc_f]),regions)
    dd = Dict(regions[i] => deaths[i, ind[d]] for i in eachindex(regions))
    for o in regions
        deaths[ind[o], ind[d]] += iszero(sum([dd[regions[i]] for i in eachindex(regions)])) != true ? death_journey[findfirst([death_journey[i,:origin] == "Unknown" && death_journey[i,:deathloc_f] == d for i in eachindex(death_journey[:,1])]),:missing]  * dd[o] / sum([dd[regions[i]] for i in eachindex(regions)]) : 0.0
    end
end

# Attributing migrants by death location not directly corresponding to FUND regions
for o in intersect(unique(death_journey[!,:origin_f]),regions)
    deaths[ind[o], ind["SSA"]] += death_journey[findfirst([death_journey[i,:origin_f] == o && death_journey[i,:deathloc] == "Horn of Africa" for i in eachindex(death_journey[:,1])]),:missing]
    # Assume migrants dead at US-Mexico border were trying to enter the USA
    deaths[ind[o], ind["USA"]] += death_journey[findfirst([death_journey[i,:origin_f] == o && death_journey[i,:deathloc] == "US-Mexico border" for i in eachindex(death_journey[:,1])]),:missing]
    if o != "EEU" && o != "WEU"
        deaths[ind[o], ind["EEU"]] = deaths[ind[o], ind["WEU"]] * (1 / (1 + flows[ind[o], ind["WEU"]] / flows[ind[o], ind["EEU"]]))
        deaths[ind[o], ind["WEU"]] *= (1 / (1 + flows[ind[o], ind["EEU"]] / flows[ind[o], ind["WEU"]]))
    end
    # Based on IOM data,migrants dead in Eastern Mediterranean were generally attempting to enter EEU
    deaths[ind[o], ind["EEU"]] += death_journey[findfirst([death_journey[i,:origin_f] == o && death_journey[i,:deathloc] == "Eastern Mediterranean" for i in eachindex(death_journey[:,1])]),:missing]
    # Based on IOM data,migrants dead in Western and Central Mediterranean were generally attempting to enter WEU
    deaths[ind[o], ind["WEU"]] += death_journey[findfirst([death_journey[i,:origin_f] == o && death_journey[i,:deathloc] == "Western + Central Mediterranean" for i in eachindex(death_journey[:,1])]),:missing]
end

# Attributing migrants for which neither origin nor death location directly correspond to FUND regions
for (d1, d2) in [("SSA", "Horn of Africa"), ("USA", "US-Mexico border"), ("EEU", "Eastern Mediterranean"), ("WEU", "Western + Central Mediterranean")]
    for (o1, o2) in [("SSA", "Horn of Africa"), ("SSA", "Horn of Africa (P)"), ("CHI", "East Asia (P)")]
        deaths[ind[o1], ind[d1]] += death_journey[findfirst([death_journey[i,:origin] == o2 && death_journey[i,:deathloc] == d2 for i in eachindex(death_journey[:,1])]),:missing]
    end    
    dmde = deaths[ind["MDE"], ind[d1]] ; dsas = deaths[ind["SAS"], ind[d1]]
    for (o1, o2) in [(i, j) for i in ["MDE", "SAS"], j in ["Middle East and South Asia", "Middle East and South Asia (P)"]]
        deaths[ind[o1], ind[d1]] += iszero(dmde + dsas) != true ? death_journey[findfirst([death_journey[i,:origin] == o2 && death_journey[i,:deathloc] == d2 for i in eachindex(death_journey[:,1])]),:missing] * (o1 == "MDE" ? dmde : dsas) / (dmde + dsas) : 0.0
    end
    dcam = deaths[ind["CAM"], ind[d1]] ; dlam = deaths[ind["LAM"], ind[d1]] ; dsis = deaths[ind["SIS"], ind[d1]]
    for (o1, o2) in [(i, j) for i in ["CAM", "LAM", "SIS"], j in ["Latin America and the Caribbean (P)"]] 
        deaths[ind[o1], ind[d1]] += iszero(dcam + dlam + dsis) != true ? death_journey[findfirst([death_journey[i,:origin] == o2 && death_journey[i,:deathloc] == d2 for i in eachindex(death_journey[:,1])]),:missing] * (o1 == "CAM" ? dcam : (o1 == "LAM" ? dlam : dsis)) / (dcam + dlam + dsis) : 0.0
    end 
    dd = Dict(regions[i] => deaths[i, ind[d1]] for i in eachindex(regions))
    for o in regions
        deaths[ind[o], ind[d1]] += iszero(sum([dd[regions[i]] for i in eachindex(regions)])) != true ? death_journey[findfirst([death_journey[i,:origin] == "Unknown" && death_journey[i,:deathloc] == d2 for i in eachindex(death_journey[:,1])]),:missing] * dd[o] / sum([dd[regions[i]] for i in eachindex(regions)]) : 0.0
    end
end


# Calculating the risk of dying on a journey as the ratio of missing migrants and migrants flows on that journey
migdeathrisk = DataFrame(origin = repeat(regions, inner = length(regions)), deathloc = repeat(regions, outer = length(regions)))
deathrisk = []
for o in eachindex(regions)
    orisk = [iszero(flows[o, j]) ? 0.0 : deaths[o, j] / flows[o, j] for j in eachindex(regions)]
    append!(deathrisk, orisk)
end
migdeathrisk[!,:deathrisk] = deathrisk

CSV.write("../data_mig/migdeathrisk.csv", migdeathrisk; writeheader=false)     
