using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics

##################### Calculating the share of income that migrants send to their home region as remittances, rho ##################
# Reading remittances flows at country * country level. Data for 2017 from World Bank
remflow_matrix = load(joinpath(@__DIR__, "../data/rem_wb/WB_Bilateral_Remittance_Estimates_2017.xlsx"), "Bilateral_Remittances_2017!A2:HH217") |> DataFrame
countriesr = remflow_matrix[1:214,1]
remflow = stack(remflow_matrix, 2:215)
select!(remflow, Not(:WORLD))
rename!(remflow, Symbol("receiving (across) / sending (down) ") => :sending, :variable => :receiving, :value => :flow)
permutecols!(remflow, [3,1,2])
sort!(remflow, :sending)
indworld = findall(remflow[!,:sending] .== "WORLD")
deleterows!(remflow, indworld)
indmissing = findall([typeof(remflow[!,:flow][i]) != Float64 for i in 1:size(remflow, 1)])
for i in indmissing ; remflow[!,:flow][i] = 0.0 end
remflow[!,:flow] = map(x -> float(x), remflow[!,:flow])
remflow[!,:receiving] = map(x -> string(x), remflow[!,:receiving])

# Reading migrant stocks at country * country level. Data for 2017 from World Bank
migstock_matrix = load(joinpath(@__DIR__, "../data/rem_wb/WB_Bilateral_Estimates_Migrant_Stocks_2017.xlsx"), "Bilateral_Migration_2017!A2:HJ219") |> DataFrame
countriesm = migstock_matrix[1:214,1]
migstock = stack(migstock_matrix, 2:215)
select!(migstock, Not([Symbol("Other North"), Symbol("Other South"), :World]))
rename!(migstock, :x1 => :origin, :variable => :destination, :value => :stock)
permutecols!(migstock, [3,1,2])
sort!(migstock, :origin)
indregion = vcat(findall(migstock[!,:origin] .== "Other North"), findall(migstock[!,:origin] .== "Other South"), findall(migstock[!,:origin] .== "World"))
deleterows!(migstock, indregion)
indmissing = findall([typeof(migstock[!,:stock][i]) != Float64 for i in 1:size(migstock, 1)])
for i in indmissing ; migstock[!,:stock][i] = 0.0 end
migstock[!,:stock] = map(x -> float(x), migstock[!,:stock])
migstock[!,:destination] = map(x -> string(x), migstock[!,:destination])

# Reading GDP per capita at country level. Data for 2017 from World Bank(WDI), in current USD
ypc2017 = load(joinpath(@__DIR__,"../data/rem_wb/GDPpercap2017.xlsx"), "Data!A1:E218") |> DataFrame
select!(ypc2017, Not([Symbol("Series Code"), Symbol("Series Name")]))
rename!(ypc2017, Symbol("Country Name") => :country, Symbol("Country Code") => :country_code, Symbol("2017 [YR2017]") => :ypc)
for i in 1:size(ypc2017, 1) ; if ypc2017[!,:ypc][i] == ".." ; ypc2017[!,:ypc][i] = missing end end      # replacing missing values by zeros

# Joining data
rename!(remflow, :sending => :destination) ; rename!(remflow, :receiving => :origin)                # remittances sending country = destination country
rho = join(remflow, migstock, on = [:origin, :destination], kind = :outer)
permutecols!(rho, [2,1,3,4])
sort!(rho, :origin)
rename!(rho, :flow => :remflow, :stock => :migstock)

rename!(ypc2017, :country => :destination, :country_code => :code_dest, :ypc => :ypc_dest)
indnkorea = findfirst(x -> x == "Korea, Dem. People’s Rep.", ypc2017[!,:destination])
ypc2017[!,:destination][indnkorea] = "Korea, Dem. Rep."
rho = join(rho, ypc2017, on = :destination)         # Only Swaziland and Faeroe Islands are missing (no ypc values)
rename!(ypc2017, :destination => :origin, :code_dest => :code_or, :ypc_dest => :ypc_or)
rho = join(rho, ypc2017, on = :origin)         # Only Swaziland and Faeroe Islands are missing (no ypc values)
rho[!,:ypc] = [max(mean([rho[i,:ypc_or],rho[i,:ypc_dest]]), rho[i,:ypc_or]) for i in 1:size(rho,1)]

# Calculating rho using rho * ypc * migstock = remflow
rho[!,:rho] = rho[!,:remflow] .* 1000000 ./ (rho[!,:migstock] .* rho[!,:ypc])       # Remittances are in million USD 2018
for i in 1:size(rho, 1)
    if ismissing(rho[i,:ypc]) || rho[!,:migstock][i] == 0.0 || rho[!,:ypc][i] == 0.0
        rho[!,:rho][i] = 0.0
    end
end

# Note: rho > 1 indicates that migrants are able to send (thus make) more money than the average per capita income in their destination country. 
# This happens in 2.4% of the corridors, largely in destination of developing countries. 
# In 80% of those cases, migrants come from wealthier regions

# Sorting the data
rhofinal = rho[:,[:code_or,:code_dest,:rho]]
sort!(rhofinal, [:code_or,:code_dest])
rename!(rhofinal, :code_or => :origin, :code_dest => :destination)
CSV.write("../data/rem_wb/rho.csv", rhofinal)