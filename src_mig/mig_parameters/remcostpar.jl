using CSV, DataFrames, ExcelFiles, Query, Statistics, XLSX


####################### Calculating the cost of sending remittances, as share of money sent, at the countriy level ###########################
# Reading remittances price data by World Bank: Remittance Prices Worldwide (2018)
# Aggregate data at the country * country level for 2017. 
rpw = XLSX.openxlsx(joinpath(@__DIR__, "../../input_data/WB_rpw.xlsx")) do xf
    DataFrame(XLSX.gettable(xf["WB_rpw"])...)
end
select!(rpw, Not(vcat(names(rpw)[1], names(rpw)[4:8], names(rpw)[10:22], names(rpw)[27:29], names(rpw)[34:end])))
# Source is the sending country, i.e. the migrant's destination
rename!(rpw, Symbol("cc1 total cost %") => :cc1, Symbol("cc2 total cost %") => :cc2, :source_code => :destination, :destination_code => :origin)
rpw[!,:period] = map(x -> parse(Int, SubString(x,1:4)), rpw[!,:period])
indnot2017 = findall(rpw[!,:period] .!= 2017)
deleteat!(rpw, indnot2017)

# Drop rows for which costs are negative
rpw[!,:meancost] = [((typeof(rpw[i,:cc1]) == Float64 || typeof(rpw[i,:cc1]) == Int64) && rpw[i,:cc1]>=0) ? (((typeof(rpw[i,:cc2]) == Float64 || typeof(rpw[i,:cc2]) == Int64) && rpw[i,:cc2]>=0) ? mean([rpw[i,:cc1], rpw[i,:cc2]]) : max(0,rpw[i,:cc1])) : max(0,rpw[i,:cc2]) for i in eachindex(rpw[:,1])]
# Average over surveys and firms per corridor
phi = combine(groupby(rpw, [:origin, :destination]), df -> mean(df[!,:meancost]) ./ 100)      
rename!(phi, :x1 => :phi)


####################### Aggregating the cost of sending remittances, as share of money sent, to the region level ###########################
# Reading remittances flows at country * country level; data for 2017 from World Bank.
remittances_flow = XLSX.readdata(joinpath(@__DIR__, "../../input_data/WB_Bilateral_Remittance_Estimates_2017.xlsx"), "Bilateral_Remittances_2017!A2:HH217")
remittances_flow = DataFrame(remittances_flow, :auto)
rename!(remittances_flow, Symbol.(Vector(remittances_flow[1,:])))
deleteat!(remittances_flow,1) 
countriesr = remittances_flow[1:214,1]
remflow = stack(remittances_flow, 2:215)
select!(remflow, Not([:WORLD]))
rename!(remflow, Symbol("receiving (across) / sending (down) ") => :sourcecountry, :variable => :destinationcountry, :value => :remittanceflows)
indregion = findall(remflow[!,:sourcecountry] .== "WORLD")
delete!(remflow, indregion)
indmissing = findall([typeof(remflow[i,:remittanceflows]) != Float64 for i in eachindex(remflow[:,1])])
for i in indmissing
    remflow[i,:remittanceflows] = 0.0
end    
remflow[!,:remittanceflows] = map(x -> float(x), remflow[!,:remittanceflows])
remflow[!,:sourcecountry] = map(x -> string(x), remflow[!,:sourcecountry])

# Matching country codes.
country_iso3c = CSV.read(joinpath(@__DIR__,"../../input_data/country_iso3c.csv"), DataFrame)
matching = leftjoin(DataFrame(country = countriesr), country_iso3c, on = :country)
misspelled = findall([ismissing(matching[i,:iso3c]) for i in eachindex(matching[:,1])])
for i in misspelled
    ind = findfirst([occursin(j, split(matching[i,:country], ",")[1]) for j in country_iso3c[!,:country]] .== true)
    if typeof(ind) == Int64 ; matching[i,:iso3c] = country_iso3c[ind,:iso3c] end
end
matching[findfirst(matching[!,:country] .== "Congo, Dem. Rep."),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Congo Democratic Republic"),:iso3c]    # Corrections
matching[findfirst(matching[!,:country] .== "Korea, Dem. Rep."),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "North Korea"),:iso3c]    
matching[findfirst(matching[!,:country] .== "Korea, Rep."),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "South Korea"),:iso3c]    
matching[findfirst(matching[!,:country] .== "Kyrgyz Republic"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Kyrgyzstan"),:iso3c]    
matching[findfirst(matching[!,:country] .== "Lao PDR"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Laos"),:iso3c]    
matching[findfirst(matching[!,:country] .== "United States"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "United States of America"),:iso3c]    
matching[findfirst(matching[!,:country] .== "Virgin Islands (U.S.)"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Virgin Islands US"),:iso3c]          # Corrections
matching[findfirst(matching[!,:country] .== "Faeroe Islands"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Faroe Islands"),:iso3c]    
matching[findfirst(matching[!,:country] .== "Slovak Republic"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Slovakia"),:iso3c]    
matching[findfirst(matching[!,:country] .== "St. Kitts and Nevis"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Saint Kitts and Nevis"),:iso3c]    
matching[findfirst(matching[!,:country] .== "St. Lucia"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Saint Lucia"),:iso3c]    
matching[findfirst(matching[!,:country] .== "St. Vincent and the Grenadines"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Saint Vincent and the Grenadines"),:iso3c]    
matching[findfirst(matching[!,:country] .== "Vietnam"),:iso3c] = country_iso3c[findfirst(country_iso3c[!,:country] .== "Viet Nam"),:iso3c]    
matching[findfirst(matching[!,:country] .== "Sint Maarten (Dutch part)"),:iso3c] = "SXM"        
matching[findfirst(matching[!,:country] .== "St. Martin (French part)"),:iso3c] = "MAF"
matching[findfirst(matching[!,:country] .== "Channel Islands"),:iso3c] = "CHI"                     
matching[findfirst(matching[!,:country] .== "Kosovo"),:iso3c] = "XKX"

remflow = leftjoin(remflow, rename(matching, :country => :sourcecountry, :iso3c => :source), on = :sourcecountry)
remflow = leftjoin(remflow, rename(matching, :country => :destinationcountry, :iso3c => :destination), on = :destinationcountry)

# Joining the data
# Source is the sending country, i.e. the migrant's destination
phi = leftjoin(phi, rename(remflow[!,Not([:sourcecountry,:destinationcountry])], :destination => :origin, :source => :destination), on = [:origin, :destination])

# Transposing to FUND region * region level. We weight corridors by remittances flows.
iso3c_fundregion = CSV.File(joinpath(@__DIR__,"../../input_data/iso3c_fundregion.csv")) |> DataFrame
phiweight = leftjoin(phi, rename(iso3c_fundregion, :iso3c => :origin, :fundregion => :originregion), on = :origin)
phiweight = leftjoin(phiweight, rename(iso3c_fundregion, :iso3c => :destination, :fundregion => :destinationregion), on = :destination)
indmissing = findall(phiweight.origin .== "KSV")
for i in indmissing
    phiweight[i,:originregion] = "EEU"
end
phiweight.remittanceflows = coalesce.(phiweight.remittanceflows, 0.0)

weight = combine(groupby(phiweight, [:originregion, :destinationregion]), :remittanceflows => sum)
phiweight = leftjoin(phiweight, weight, on = [:originregion, :destinationregion])
phiweight.w1 = [phiweight[i,:remittanceflows_sum] != 0.0 ? phiweight[i,:remittanceflows] / phiweight[i,:remittanceflows_sum] : 0.0 for i in eachindex(phiweight[:,1])]
phiweight.remcostreg = phiweight.phi .* phiweight.w1
phiweight = combine(groupby(phiweight, [:originregion, :destinationregion]), :remcostreg => sum)
rename!(phiweight, :remcostreg_sum => :phi)

# Sorting the data
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
phiweight = outerjoin(phiweight, regionsdf, on = [:originregion, :destinationregion])
sort!(phiweight, [:indexo, :indexd])
select!(phiweight, [:destinationregion, :originregion,:phi])

# Dealing with missing values. 
# We attribute to missing corridors the mean of costs for all corridors with the same source region. If all source regions are missing, we attribute the mean of all corridors.
totmean = mean(skipmissing(phiweight.phi))
for r in regions
    nophi = [] ; indnophi = [] ; indphi = []
    for i in findall(phiweight.originregion .== r)
        append!(nophi, ismissing(phiweight[i,:phi]))
        if ismissing(phiweight[i,:phi]) == true ; append!(indnophi, i) ; else ; append!(indphi, i) end
    end
    for i in indnophi
        phiweight[i,:phi] = (indphi != []) ? mean([phiweight[j,:phi] for j in indphi]) : totmean
    end
end


CSV.write(joinpath(@__DIR__,"../../data_mig/remcost_update.csv"), phiweight; writeheader=false)


# Stress test: make remittance costs 100%
stresstestpar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    remcost = ones(length(regions)*length(regions))
)


CSV.write(joinpath(@__DIR__,"../../data_borderpolicy/remcost_stresstest.csv"), stresstestpar; writeheader=false)