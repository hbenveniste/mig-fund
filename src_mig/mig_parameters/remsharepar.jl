using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics, XLSX


##################### Calculating the share of income that migrants send to their home region as remittances, rho ##################
# Reading migrant stocks at country * country level; data for 2017 from World Bank.
migstock_matrix = XLSX.readdata(joinpath(@__DIR__, "../../input_data/WB_Bilateral_Estimates_Migrant_Stocks_2017.xlsx"), "Bilateral_Migration_2017!A2:HJ219") 
migstock_matrix = DataFrame(migstock_matrix, :auto)
rename!(migstock_matrix, Symbol.(Vector(migstock_matrix[1,:])))
deleteat!(migstock_matrix,1)
countriesm = migstock_matrix[1:214,1]
migstock = stack(migstock_matrix, 2:215)
select!(migstock, Not([Symbol("Other North"), Symbol("Other South"), :World]))
rename!(migstock, :missing => :origin, :variable => :destination, :value => :migrantstock)
sort!(migstock, :origin)
indregion = vcat(findall(migstock[!,:origin] .== "Other North"), findall(migstock[!,:origin] .== "Other South"), findall(migstock[!,:origin] .== "World"))
delete!(migstock, indregion)
indmissing = findall([ismissing(migstock[i,:migrantstock]) for i in eachindex(migstock[:,1])])
for i in indmissing ; migstock[!,:migrantstock][i] = 0.0 end
migstock[!,:migrantstock] = map(x -> float(x), migstock[!,:migrantstock])
migstock[!,:destination] = map(x -> string(x), migstock[!,:destination])

# Reading remittances flows at country * country level; data for 2017 from World Bank.
remittances_flow = XLSX.readdata(joinpath(@__DIR__, "../../input_data/WB_Bilateral_Remittance_Estimates_2017.xlsx"), "Bilateral_Remittances_2017!A2:HH217")
remittances_flow = DataFrame(remittances_flow, :auto)
rename!(remittances_flow, Symbol.(Vector(remittances_flow[1,:])))
deleteat!(remittances_flow,1) 
countriesr = remittances_flow[1:214,1]
remflow = stack(remittances_flow, 2:215)
select!(remflow, Not([:WORLD]))
rename!(remflow, Symbol("receiving (across) / sending (down) ") => :sending, :variable => :receiving, :value => :remittanceflows)
indregion = findall(remflow[!,:sending] .== "WORLD")
delete!(remflow, indregion)
indmissing = findall([typeof(remflow[i,:remittanceflows]) != Float64 for i in eachindex(remflow[:,1])])
for i in indmissing
    remflow[i,:remittanceflows] = 0.0
end    
remflow[!,:remittanceflows] = map(x -> float(x), remflow[!,:remittanceflows])
remflow[!,:sending] = map(x -> string(x), remflow[!,:sending])

# Reading GDP per capita at country level; data for 2017 from World Bank(WDI), in current USD. 
ypc_2017 = readdlm(joinpath(@__DIR__,"../../input_data/ypc2017.csv"), ';', comments = true)
ypc2017 = DataFrame(iso3c = ypc_2017[2:end,1], ypc = ypc_2017[2:end,2])
for i in eachindex(ypc2017[:,1]) ; if ypc2017[i,:ypc] == ".." ; ypc2017[i,:ypc] = missing end end      # replacing missing values by zeros

# Joining data in one DataFrame
rename!(remflow, :sending => :destination) ; rename!(remflow, :receiving => :origin)                # remittances sending country = destination country
rho = outerjoin(remflow, migstock, on = [:origin, :destination])

# Matching with country codes.
country_iso3c = CSV.read(joinpath(@__DIR__,"../../input_data/country_iso3c.csv"), DataFrame)
matching = leftjoin(DataFrame(country = countriesm), country_iso3c, on = :country)
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

rename!(matching, :country => :origin)
rho = leftjoin(rho, matching, on = :origin)
rename!(rho, :iso3c => :origincountry)
rename!(matching, :origin => :destination)
rho = leftjoin(rho, matching, on = :destination)
rename!(rho, :iso3c => :destinationcountry)

# Adding per capita income
# Try Marc's suggestion: use not just ypc_dest, but instead max((ypc_dest + ypc_or)/2, ypc_or)
rename!(ypc2017, :iso3c => :destinationcountry, :ypc => :ypc_destinationcountry)
dropmissing!(rho)
rho = innerjoin(rho, ypc2017, on = :destinationcountry)
rename!(ypc2017, :destinationcountry => :origincountry, :ypc_destinationcountry => :ypc_origincountry)
rho = innerjoin(rho, ypc2017, on = :origincountry)
rho[!,:ypc] = [max(mean([rho[i,:ypc_origincountry],rho[i,:ypc_destinationcountry]]), rho[i,:ypc_origincountry]) for i in eachindex(rho[:,1])]
dropmissing!(rho)

# Calculating rho using rho * ypc * migstock = remflow
rhovalue = []
for i in eachindex(rho[:,1])
    v = 0.0
    (rho[i,:migrantstock] != 0.0 && rho[i,:ypc] != 0.0) ? v += rho[i,:remittanceflows] * 1000000 / rho[i,:migrantstock] / rho[i,:ypc] : v += 0.0     # Remittances are in million USD 2018
    append!(rhovalue, v)
end
rho[!,:rho] = rhovalue        


CSV.write(joinpath(@__DIR__,"../../input_data/rho.csv"), sort(rename(rho[:,[:origincountry,:destinationcountry,:rho]], :origincountry => :origin, :destinationcountry => :destination), [:origin,:destination]))