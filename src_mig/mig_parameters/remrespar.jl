using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics, XLSX
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths


# Reading residuals at country level
gravity_17 = CSV.read(joinpath(@__DIR__,"../results/gravity/gravity_17.csv"), DataFrame)

iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv", DataFrame)

# Reading migrant stocks at country * country level; data for 2017 from World Bank.
migstock_matrix = XLSX.readdata(joinpath(@__DIR__, "../../input_data/WB_Bilateral_Estimates_Migrant_Stocks_2017.xlsx"), "Bilateral_Migration_2017!A1:HJ219")
migstock_matrix = DataFrame(migstock_matrix, :auto)
header = 3
countries = migstock_matrix[(header):(length(migstock_matrix[:,1]) - 3), 1]
migstock = DataFrame(
    origin = repeat(countries, inner = length(countries)), 
    destination = repeat(countries, outer = length(countries))
)
stock = []
for o in (header):(length(countries)+header-1)
    ostock = migstock_matrix[o, 2:(end - 3)]
    append!(stock, ostock)
end
migstock.migrantstock = stock
indmissing = findall([typeof(migstock[i,:migrantstock]) != Int64 for i in eachindex(migstock[:,1])])
for i in indmissing
    migstock[i,:migrantstock] = 0.0
end 

# Matching with country codes.
country_iso3c = CSV.read("../input_data/country_iso3c.csv", DataFrame)
matching = leftjoin(DataFrame(country = countriesm), country_iso3c, on = :country)
misspelled = findall([ismissing(matching[i,:iso3c]) for i in eachindex(matching[:,1])])
for i in misspelled
    ind = findfirst([occursin(j, split(matching[i,:country], ",")[1]) for j in country_iso3c[!,:country]] .== true)
    if typeof(ind) == Int64 ; matching[i,:iso3c] = country_iso3c[ind, :iso3c] end
end
matching[44, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Congo Democratic Republic")]    # Corrections
matching[101, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "North Korea")]    
matching[102, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "South Korea")]    
matching[105, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Kyrgyzstan")]    
matching[106, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Laos")]    
matching[204, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "United States of America")]    
matching[210, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Virgin Islands US")]          # Corrections
matching[64, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Faroe Islands")]    
matching[170, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Slovakia")]    
matching[178, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Saint Kitts and Nevis")]    
matching[179, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Saint Lucia")]    
matching[181, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Saint Vincent and the Grenadines")]    
matching[209, :iso3c] = country_iso3c[:iso3c][findfirst(country_iso3c[:country] .== "Viet Nam")]    
matching[169, :iso3c] = "SXM"        
matching[180, :iso3c] = "MAF"    
matching[39, :iso3c] = "CHI"                     
matching[103, :iso3c] = "XKX"

migstock = innerjoin(migstock, rename(matching, :country=>:origin,:iso3c=>:orig), on = :origin)
migstock = innerjoin(migstock, rename(matching, :country=>:destination,:iso3c=>:dest), on = :destination)


############################## Calculating residuals from remshare estimation at FUND region level ######################################
############################## Second method: weight exp(residuals) by weights suggested with Marc #################################################
data_resweight = gravity_17[:,union(1:6,13)]
data_resweight[!,:gdp_orig] = data_resweight[:,:ypc_orig] .* data_resweight[:,:pop_orig]
data_resweight[!,:gdp_dest] = data_resweight[:,:ypc_dest] .* data_resweight[:,:pop_dest]

data_resweight = innerjoin(data_resweight, migstock[:,3:5], on = [:orig,:dest])

data_resweight = innerjoin(data_resweight, rename(iso3c_fundregion, :iso3c=>:orig,:fundregion=>:originregion),on=:orig)
data_resweight = innerjoin(data_resweight, rename(iso3c_fundregion, :iso3c=>:dest,:fundregion=>:destinationregion),on=:dest)

# Calculate appropriate weights for exp(residuals)
data_resweight_calc = combine(groupby(data_resweight, [:originregion,:destinationregion]), d -> (pop_orig_reg = sum(d.pop_orig),gdp_orig_reg=sum(d.gdp_orig),pop_dest_reg = sum(d.pop_dest),gdp_dest_reg=sum(d.gdp_dest),migstock_reg=sum(d.migrantstocks)))
data_resweight = innerjoin(data_resweight, data_resweight_calc, on=[:originregion,:destinationregion])
data_resweight[!,:ypc_mig] = [max((data_resweight[i,:ypc_orig] + data_resweight[i,:ypc_dest])/2,data_resweight[i,:ypc_orig]) for i in eachindex(data_resweight[:,1])]
data_resweight[!,:ypc_mig_reg] = [max((data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg] + data_resweight[i,:gdp_dest_reg]/data_resweight[i,:pop_dest_reg])/2,data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg]) for i in eachindex(data_resweight[:,1])]
data_resweight[!,:res_weight] = data_resweight[:,:migrantstocks] ./ data_resweight[:,:migstock_reg] .* data_resweight[:,:ypc_mig] ./ data_resweight[:,:ypc_mig_reg]
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
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
data_resweight_fund = innerjoin(data_resweight_fund, regionsdf, on = [:originregion, :destinationregion])
sort!(data_resweight_fund, (:indexo, :indexd))
delete!(data_resweight_fund, [:indexo, :indexd])
CSV.write("../data_mig/remres.csv", data_resweight_fund; writeheader=false)
