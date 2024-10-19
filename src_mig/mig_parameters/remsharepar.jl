using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics, XLSX

# Calculating the share of income that migrants send to their home region as remittances, rho.

# Reading migrant stocks at country * country level; data for 2017 from World Bank.
migrant_stock = XLSX.readdata(joinpath(@__DIR__, "../../input_data/WB_Bilateral_Estimates_Migrant_Stocks_2017.xlsx"), "Bilateral_Migration_2017!A1:HJ219")
header = 3
countriesm = migrant_stock[(header):(length(migrant_stock[:,1]) - 3), 1]
migstock = DataFrame(origin = repeat(countriesm, inner = length(countriesm)), destination = repeat(countriesm, outer = length(countriesm)))
stocks = []
for o in (header):(length(countriesm) + 1)
    ostock = migrant_stock[o, 2:(end - 3)]
    append!(stocks, ostock)
end
migstock[:migrantstocks] = stocks
indmissing = findall([typeof(migstock[i,:migrantstocks]) != Float64 for i in eachindex(migstock[:,1])])
for i in indmissing
    migstock[:migrantstocks][i] = 0.0
end

# Reading remittances flows at country * country level; data for 2017 from World Bank.
remittances_flow = XLSX.readdata(joinpath(@__DIR__, "../../input_data/WB_Bilateral_Remittance_Estimates_2017.xlsx"), "Bilateral_Remittances_2017!A1:HH217") 
header = 3
countriesr = remittances_flow[(header):(length(remittances_flow[:,1]) - 1), 1]
remflow = DataFrame(sending = repeat(countriesr, inner = length(countriesr)), receiving = repeat(countriesr, outer = length(countriesr)))
flow = []
for o in (header):(length(countriesr) + 1)
    oflow = remittances_flow[o, 2:(end-1)]
    append!(flow, oflow)
end
remflow[:remittanceflows] = flow
indmissing = findall([typeof(remflow[i,:remittanceflows]) != Float64 for i in eachindex(remflow[:,1])])
for i in indmissing
    remflow[:remittanceflows][i] = 0.0
end    

# Reading GDP per capita at country level; data for 2017 from World Bank(WDI), in current USD. 
ypc_2017 = readdlm("../input_data/ypc2017.csv", ';', comments = true)
ypc2017 = DataFrame(iso3c = ypc_2017[2:end,1], ypc = ypc_2017[2:end,2])
for i in eachindex(ypc2017[:,1]) ; if ypc2017[:ypc][i] == ".." ; ypc2017[:ypc][i] = missing end end      # replacing missing values by zeros

# Joining data in one DataFrame
rename!(remflow, :sending => :destination) ; rename!(remflow, :receiving => :origin)                # remittances sending country = destination country
rho = outerjoin(remflow, migstock, on = [:origin, :destination])

# Matching with country codes.
country_iso3c = CSV.read("../input_data/country_iso3c.csv", DataFrame)
matching = leftjoin(DataFrame(country = countriesm), country_iso3c, on = :country)
misspelled = findall([ismissing(matching[i,:iso3c]) for i in eachindex(matching[:,1])])
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

rename!(matching, :country => :origin)
rho = leftjoin(rho, matching, on = :origin)
rename!(rho, :iso3c => :origincountry)
rename!(matching, :origin => :destination)
rho = leftjoin(rho, matching, on = :destination)
rename!(rho, :iso3c => :destinationcountry)

# Adding per capita income
# Try Marc's suggestion: use not just ypc_dest, but instead max((ypc_dest + ypc_or)/2, ypc_or)
rename!(ypc2017, :iso3c => :destinationcountry, :ypc => :ypc_destinationcountry)
rho = innerjoin(rho, ypc2017, on = :destinationcountry)
rename!(ypc2017, :destinationcountry => :origincountry, :ypc_destinationcountry => :ypc_origincountry)
rho = innerjoin(rho, ypc2017, on = :origincountry)
dropmissing!(rho)
rho[!,:ypc] = [max(mean([rho[i,:ypc_origincountry],rho[i,:ypc_destinationcountry]]), rho[i,:ypc_origincountry]) for i in eachindex(rho[:,1])]

# Calculating rho using rho * ypc * migstock = remflow
rhovalue = []
for i in eachindex(rho[:,1])
    v = 0.0
    (rho[i,:migrantstocks] != 0.0 && rho[i,:ypc] != 0.0) ? v += rho[i,:remittanceflows] * 1000000 / rho[i,:migrantstocks] / rho[i,:ypc] : v += 0.0     # Remittances are in million USD 2018
    append!(rhovalue, v)
end
rho[:rho] = rhovalue        

CSV.write("../input_data/rho.csv", sort(rename(rho[:,[:origincountry,:destinationcountry,:rho]], :origincountry => :origin, :destinationcountry => :destination), [:origin,:destination]))


# Transposing to FUND region * region level. We weight corridors by remittances flows.
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv", DataFrame)
rename!(iso3c_fundregion, :iso3c => :origincountry)
rho = leftjoin(rho, iso3c_fundregion, on = :origincountry)
rename!(rho, :fundregion => :originregion)
mis3c = Dict("SXM" => "SIS", "MAF" => "SIS", "CHI" => "WEU", "XKX" => "EEU")
for c in ["SXM", "MAF", "CHI", "XKX"] 
    indmissing = findall(rho[:origincountry] .== c)
    for i in indmissing
        rho[:originregion][i] = mis3c[c]
    end
end
rename!(iso3c_fundregion, :origincountry => :destinationcountry)
rho = leftjoin(rho, iso3c_fundregion, on = :destinationcountry)
rename!(rho, :fundregion => :destinationregion)
for c in ["SXM", "MAF", "CHI", "XKX"] 
    indmissing = findall(rho[:destinationcountry] .== c)
    for i in indmissing
        rho[:destinationregion][i] = mis3c[c]
    end
end

weight = combine(groupby(rho, [:originregion, :destinationregion]), df -> sum(df[:remittanceflows]))
rho = leftjoin(rho, weight, on = [:originregion, :destinationregion])
rho[!,:w1] = [rho[i,:x1] != 0.0 ? rho[i,:remittanceflows] / rho[i,:x1] : 0.0 for i in eachindex(rho[:,1])]
rho_r = combine(groupby(rho, [:originregion, :destinationregion]), df -> sum(df[:w1] .* df[:rho]))
rename!(rho_r, :x1 => :rho)

# Note: rho > 1 indicates that migrants are able to send (thus make) more money than the average per capita income in their destination country. 
# This happens in 14% of the corridors, largely in destination of developing countries. 
# In >60% of those cases, migrants come from wealthier regions.

# Sorting the data
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
rho_r = innerjoin(rho_r, regionsdf, on = [:originregion, :destinationregion])
sort!(rho_r, (:indexo, :indexd))
delete!(rho_r, [:indexo, :indexd])
CSV.write("../data_mig/remshare.csv", rho_r; writeheader=false)

# Stress test: make remittances 100% of income
stresstestpar = DataFrame(
    source = repeat(regions, inner = length(regions)), 
    destination = repeat(regions, outer = length(regions)), 
    remshare = ones(length(regions)*length(regions))
)
CSV.write(joinpath(@__DIR__,"../data_borderpolicy/remshare_stresstest.csv"), stresstestpar; writeheader=false)