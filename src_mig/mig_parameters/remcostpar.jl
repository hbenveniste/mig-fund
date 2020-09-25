using CSV, DataFrames, ExcelFiles, Query, Statistics

# Calculating the cost of sending remittances, as share of money sent, phi

# Reading remittances price data by World Bank: Remittance Prices Worldwide (2018).
# We aggregate data at the country * country level for 2017. 
rpw = load(joinpath(@__DIR__, "../input_data/WB_rpw.xlsx"), "WB_rpw!A1:AO36689") |> DataFrame
select!(rpw, Not(vcat(names(rpw)[1], names(rpw)[4:8], names(rpw)[10:22], names(rpw)[27:29], names(rpw)[34:end])))
rename!(rpw, Symbol("cc1 total cost %") => :cc1, Symbol("cc2 total cost %") => :cc2, :source_code => :source, :destination_code => :destination)
rpw[!,:period] = map(x -> parse(Int, SubString(x,1:4)), rpw[!,:period])
indnot2017 = findall(rpw[!,:period] .!= 2017)
deleterows!(rpw, indnot2017)
rpw[!,:meancost] = [(typeof(rpw[i,:cc1]) == Float64 && rpw[i,:cc1]>=0) ? ((typeof(rpw[i,:cc2]) == Float64 && rpw[i,:cc2]>=0) ? mean([rpw[!,:cc1][i], rpw[!,:cc2][i]]) : max(0,rpw[i,:cc1])) : max(0,rpw[i,:cc2]) for i in 1:size(rpw, 1)]
phi = by(rpw, [:source, :destination], df -> mean(df[!,:meancost]) ./ 100)        # We average over surveys and firms per corridor.
rename!(phi, :x1 => :remcost)

# Reading remittances flows at country * country level; data for 2017 from World Bank.
remittances_flow = load(joinpath(@__DIR__, "../input_data/WB_Bilateral_Remittance_Estimates_2017.xlsx"), "Bilateral_Remittances_2017!A1:HH217") |> DataFrame
header = 2
countries = remittances_flow[(header ):(length(remittances_flow[:,1]) - 1), 1]
remflow = DataFrame(sourcecountry = repeat(countries, inner = length(countries)), destinationcountry = repeat(countries, outer = length(countries)))
flow = []
for o in (header):(length(countries) + 1)
    oflow = remittances_flow[o, 2:(end - 1)]
    append!(flow, oflow)
end
remflow[:remittanceflows] = flow
indmissing = findall([typeof(remflow[!,:remittanceflows][i]) != Float64 for i in 1:size(remflow, 1)])
for i in indmissing
    remflow[:remittanceflows][i] = 0.0
end    

# Matching country codes.
country_iso3c = CSV.read("../input_data/country_iso3c.csv")
matching = join(DataFrame(country = countries), country_iso3c, on = :country, kind = :left)
misspelled = findall([ismissing(matching[i,:iso3c]) for i in 1:size(matching, 1)])
for i in misspelled
    ind = findfirst([occursin(j, split(matching[i,:country], ",")[1]) for j in country_iso3c[!,:country]] .== true)
    if typeof(ind) == Int64 ; matching[!,:iso3c][i] = country_iso3c[:iso3c][ind] end
end
matching[:iso3c][44] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Congo Democratic Republic")]    # Corrections
matching[:iso3c][101] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "North Korea")]    
matching[:iso3c][102] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "South Korea")]    
matching[:iso3c][105] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Kyrgyzstan")]    
matching[:iso3c][106] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Laos")]    
matching[:iso3c][204] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "United States of America")]    
matching[:iso3c][210] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Virgin Islands US")]          # Corrections
matching[:iso3c][64] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Faroe Islands")]    
matching[:iso3c][170] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Slovakia")]    
matching[:iso3c][178] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Saint Kitts and Nevis")]    
matching[:iso3c][179] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Saint Lucia")]    
matching[:iso3c][181] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Saint Vincent and the Grenadines")]    
matching[:iso3c][209] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Viet Nam")]    
matching[:iso3c][169] = "SXM"        
matching[:iso3c][180] = "MAF"    
matching[:iso3c][39] = "CHI"                     
matching[:iso3c][103] = "XKX"

rename!(matching, :country => :sourcecountry)
remflow = join(remflow, matching, on = :sourcecountry, kind = :left)
rename!(remflow, :iso3c => :source)
rename!(matching, :sourcecountry => :destinationcountry)
remflow = join(remflow, matching, on = :destinationcountry, kind = :left)
rename!(remflow, :iso3c => :destination)

# Joining the data.
phi = join(phi, remflow, on = [:source, :destination], kind = :left)

# Transposing to FUND region * region level. We weight corridors by remittances flows.
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
phiweight = DataFrame(source = phi[:source], destination = phi[:destination], remittanceflows = phi[:remittanceflows], remcost = phi[:remcost])
rename!(iso3c_fundregion, :iso3c => :source)
phiweight = join(phiweight, iso3c_fundregion, on = :source, kind = :left)
rename!(phiweight, :fundregion => :sourceregion)
mis3c = Dict("SXM" => "SIS", "MAF" => "SIS", "CHI" => "WEU", "KSV" => "EEU")
for c in ["SXM", "MAF", "CHI", "KSV"] 
    indmissing = findall(phiweight[:source] .== c)
    for i in indmissing
        phiweight[:sourceregion][i] = mis3c[c]
    end
end
rename!(iso3c_fundregion, :source => :destination)
phiweight = join(phiweight, iso3c_fundregion, on = :destination, kind = :left)
rename!(phiweight, :fundregion => :destinationregion)
for c in ["SXM", "MAF", "CHI", "KSV"] 
    indmissing = findall(phiweight[:destination] .== c)
    for i in indmissing
        phiweight[:destinationregion][i] = mis3c[c]
    end
end

weight = by(phiweight, [:sourceregion, :destinationregion], df -> sum(df[:remittanceflows]))
phiweight = join(phiweight, weight, on = [:sourceregion, :destinationregion], kind = :left)
phiweight[!,:x1] = coalesce.(phiweight[!,:x1], 0)
phiweight[:w1] = [phiweight[:x1][i] != 0.0 ? phiweight[:remittanceflows][i] / phiweight[:x1][i] : 0.0 for i in 1:size(phiweight, 1)]
phiweight = by(phiweight, [:sourceregion, :destinationregion], df -> sum(df[:w1] .* df[:remcost]))
rename!(phiweight, :x1 => :phi)

# Sorting the data
rename!(phiweight, :destinationregion => :originregion, :sourceregion => :destinationregion)        # !!! Source is the sending region, i.e. the migrant destination
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
phiweight = join(phiweight, regionsdf, on = [:originregion, :destinationregion], kind = :outer)
sort!(phiweight, (:indexo, :indexd))
delete!(phiweight, [:indexo, :indexd])
permutecols!(phiweight, [2,1,3])

# Dealing with missing values. 
# We attribute to missing corridors the mean of costs for all corridors with the same source region. If all source regions are missing, we attribute the mean of all corridors.
totmean = mean(skipmissing(phiweight[:phi]))
for r in regions
    nophi = [] ; indnophi = [] ; indphi = []
    for i in findall(phiweight[:originregion] .== r)
        append!(nophi, ismissing(phiweight[:phi][i]))
        if ismissing(phiweight[:phi][i]) == true ; append!(indnophi, i) ; else ; append!(indphi, i) end
    end
    for i in indnophi
        phiweight[:phi][i] = (indphi != []) ? mean([phiweight[:phi][j] for j in indphi]) : totmean
    end
end

CSV.write("../data_mig/remcost.csv", phiweight; writeheader=false)

# Stress test: make remittance costs 100%
stresstestpar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    remcost = ones(length(regions)*length(regions))
)
CSV.write(joinpath(@__DIR__,"../data_borderpolicy/remcost_stresstest.csv"), stresstestpar; writeheader=false)