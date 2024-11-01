using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths


# Reading residuals at country level
gravity_17 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/results_large/gravity_17_update.csv") |> DataFrame
country_iso3c = CSV.File(joinpath(@__DIR__,"../../input_data/country_iso3c.csv")) |> DataFrame
iso3c_fundregion = CSV.File(joinpath(@__DIR__,"../../input_data/iso3c_fundregion.csv")) |> DataFrame
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))


############################## Calculating residuals from remshare estimation at FUND region level ######################################
############################## Weight exp(residuals) by weights #################################################
# Weight by migrant stocks at country * country level; data for 2017 from World Bank.
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

migstock = innerjoin(migstock, rename(matching, :country=>:origin,:iso3c=>:orig), on = :origin)
migstock = innerjoin(migstock, rename(matching, :country=>:destination,:iso3c=>:dest), on = :destination)

data_resweight = innerjoin(gravity_17, migstock[:,Not([:origin,:destination])], on = [:orig,:dest])

data_resweight[!,:gdp_orig] = data_resweight[:,:ypc_orig] .* data_resweight[:,:pop_orig]
data_resweight[!,:gdp_dest] = data_resweight[:,:ypc_dest] .* data_resweight[:,:pop_dest]

data_resweight = innerjoin(data_resweight, rename(iso3c_fundregion, :iso3c=>:orig,:fundregion=>:originregion),on=:orig)
data_resweight = innerjoin(data_resweight, rename(iso3c_fundregion, :iso3c=>:dest,:fundregion=>:destinationregion),on=:dest)

# Calculate appropriate weights for exp(residuals)
data_resweight_calc = combine(groupby(data_resweight, [:originregion,:destinationregion]), d -> (pop_orig_reg = sum(d.pop_orig),gdp_orig_reg=sum(d.gdp_orig),pop_dest_reg = sum(d.pop_dest),gdp_dest_reg=sum(d.gdp_dest),migstock_reg=sum(d.migrantstock)))
data_resweight = innerjoin(data_resweight, data_resweight_calc, on=[:originregion,:destinationregion])
data_resweight[!,:ypc_mig] = [max((data_resweight[i,:ypc_orig] + data_resweight[i,:ypc_dest])/2,data_resweight[i,:ypc_orig]) for i in eachindex(data_resweight[:,1])]
data_resweight[!,:ypc_mig_reg] = [max((data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg] + data_resweight[i,:gdp_dest_reg]/data_resweight[i,:pop_dest_reg])/2,data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg]) for i in eachindex(data_resweight[:,1])]
data_resweight[!,:res_weight] = data_resweight[:,:migrantstock] ./ data_resweight[:,:migstock_reg] .* data_resweight[:,:ypc_mig] ./ data_resweight[:,:ypc_mig_reg]
for i in eachindex(data_resweight[:,1])
    if data_resweight[i,:migstock_reg] == 0.0
        data_resweight[i,:res_weight] = 0.0
    end
end
# Weight exp(residuals), instead of taking exp of weighted residuals 
data_resweight[!,:exp_res_weighted] = map(x -> exp(x),data_resweight[:,:residual_ratio]) .* data_resweight[:,:res_weight]

# Prepare remshare estimation at FUND region level
data_resweight_fund = combine(groupby(data_resweight, [:originregion,:destinationregion]), d -> sum(d.exp_res_weighted))
rename!(data_resweight_fund, :x1 => :remres)

# Sorting the data
data_resweight_fund = innerjoin(data_resweight_fund, regionsdf, on = [:originregion, :destinationregion])
sort!(data_resweight_fund, [:indexo, :indexd])
select!(data_resweight_fund, [:originregion, :destinationregion, :remres])


CSV.write(joinpath(@__DIR__,"../../data_mig/remres_update.csv"), data_resweight_fund; writeheader=false)
