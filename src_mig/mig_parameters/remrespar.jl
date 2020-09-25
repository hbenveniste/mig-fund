using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths


# Reading residuals at country level
gravity_17 = CSV.read(joinpath(@__DIR__,"../results/gravity/gravity_17.csv"))


############################## Calibrating remshare directly at FUND level ###################################################
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
rho = join(gravity_17[:,1:7], rename(iso3c_fundregion, :iso3c=>:orig,:fundregion=>:originregion),on=:orig)
rho = join(rho, rename(iso3c_fundregion, :iso3c=>:dest,:fundregion=>:destinationregion),on=:dest)
rho[:,:gdp_orig] = rho[:,:ypc_orig] .* rho[:,:pop_orig]
rho[:,:gdp_dest] = rho[:,:ypc_dest] .* rho[:,:pop_dest]

# Reading migrant stocks at country * country level; data for 2017 from World Bank.
migrant_stock = load(joinpath(@__DIR__, "../input_data/WB_Bilateral_Estimates_Migrant_Stocks_2017.xlsx"), "Bilateral_Migration_2017!A1:HJ219") |> DataFrame
header = 2
countriesm = migrant_stock[(header):(length(migrant_stock[:,1]) - 3), 1]
migstock = DataFrame(origin = repeat(countriesm, inner = length(countriesm)), destination = repeat(countriesm, outer = length(countriesm)))
stocks = []
for o in (header):(length(countriesm) + 1)
    ostock = migrant_stock[o, 2:(end - 3)]
    append!(stocks, ostock)
end
migstock[:,:migrantstocks] = stocks
indmissing = findall([typeof(migstock[i,:migrantstocks]) != Float64 for i in 1:size(migstock, 1)])
for i in indmissing
    migstock[i,:migrantstocks] = 0.0
end

# Matching with country codes.
country_iso3c = CSV.read("../input_data/country_iso3c.csv")
matching = join(DataFrame(country = countriesm), country_iso3c, on = :country, kind = :left)
misspelled = findall([ismissing(matching[i,:iso3c]) for i in 1:size(matching, 1)])
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

migstock = join(migstock, rename(matching, :country=>:origin,:iso3c=>:orig), on = :origin)
migstock = join(migstock, rename(matching, :country=>:destination,:iso3c=>:dest), on = :destination)
rho = join(rho, migstock[:,3:5], on = [:orig,:dest])

# Calculate appropriate weights for remshare
rho_calc = by(rho, [:originregion,:destinationregion], d -> (pop_orig_reg = sum(d.pop_orig),gdp_orig_reg=sum(d.gdp_orig),pop_dest_reg = sum(d.pop_dest),gdp_dest_reg=sum(d.gdp_dest),migstock_reg=sum(d.migrantstocks)))
rho = join(rho, rho_calc, on=[:originregion,:destinationregion])
rho[!,:ypc_mig] = [max((rho[i,:ypc_orig] + rho[i,:ypc_dest])/2,rho[i,:ypc_orig]) for i in 1:size(rho,1)]
rho[!,:ypc_mig_reg] = [max((rho[i,:gdp_orig_reg]/rho[i,:pop_orig_reg] + rho[i,:gdp_dest_reg]/rho[i,:pop_dest_reg])/2,rho[i,:gdp_orig_reg]/rho[i,:pop_orig_reg]) for i in 1:size(rho,1)]
rho[!,:rho_weight] = rho[:,:migrantstocks] ./ rho[:,:migstock_reg] .* rho[:,:ypc_mig] ./ rho[:,:ypc_mig_reg]
for i in 1:size(rho,1)
    if rho[i,:migstock_reg] == 0.0
        rho[i,:rho_weight] = 0.0
    end
end
rho[!,:remshare_weighted] = rho[:,:remshare] .* rho[:,:rho_weight]

# Prepare remshare estimation at FUND region level
rho_fund = by(rho, [:originregion,:destinationregion], d -> (gdp_orig_reg = sum(d.gdp_orig), gdp_dest_reg = sum(d.gdp_dest), pop_orig_reg = sum(d.pop_orig), pop_dest_reg = sum(d.pop_dest), remshare_reg = sum(d.remshare_weighted)))
rho_fund[!,:ypc_orig_reg] = rho_fund[:,:gdp_orig_reg] ./ rho_fund[:,:pop_orig_reg]
rho_fund[!,:ypc_dest_reg] = rho_fund[:,:gdp_dest_reg] ./ rho_fund[:,:pop_dest_reg]
rho_fund[!,:ypc_ratio_reg] = rho_fund[!,:ypc_dest_reg] ./ rho_fund[!,:ypc_orig_reg]

remcost = CSV.read(joinpath(@__DIR__,"../data_mig/remcost.csv");header=false)
rho_fund = join(rho_fund, rename(remcost, :Column1=>:originregion, :Column2 =>:destinationregion, :Column3=>:remcost_reg), on=[:originregion,:destinationregion])

# log transformation
rho_fund_est = rho_fund[:,Not(3:6)]
for name in [:ypc_orig_reg, :ypc_dest_reg, :ypc_ratio_reg]
    rho_fund_est[!,name] = [log(rho_fund_est[i,name]) for i in 1:size(rho_fund_est, 1)]
end
rho_fund_est[!,:log_remshare_reg] = [log(rho_fund_est[i,:remshare_reg]) for i in 1:size(rho_fund_est, 1)]

# Create country fixed effects
rho_fund_est.OrigCategorical = categorical(rho_fund_est.originregion)
rho_fund_est.DestCategorical = categorical(rho_fund_est.destinationregion)

# Regress remshare on log(ypc_orig), log(ypc_dest) (or ypc_ratio) and remcost
rfanex1 = reg(rho_fund_est, @formula(remshare_reg ~ ypc_orig_reg + ypc_dest_reg + remcost_reg), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
rfanex2 = reg(rho_fund_est, @formula(remshare_reg ~ ypc_dest_reg + ypc_ratio_reg + remcost_reg), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
rfanex3 = reg(rho_fund_est, @formula(remshare_reg ~ ypc_orig_reg + ypc_ratio_reg + remcost_reg), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
#rfanex4 = reg(rho_fund_est, @formula(remshare_reg ~ ypc_dest_reg + ypc_ratio_reg + remcost_reg + fe(OrigCategorical) + fe(DestCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

# Regress log(remshare) on log(ypc_orig), log(ypc_dest) (or ypc_ratio) and remcost
rfanex5 = reg(rho_fund_est[(rho_fund_est[:,:remshare_reg] .!= 0.0),:], @formula(log_remshare_reg ~ ypc_orig_reg + ypc_dest_reg + remcost_reg), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
rfanex6 = reg(rho_fund_est[(rho_fund_est[:,:remshare_reg] .!= 0.0),:], @formula(log_remshare_reg ~ ypc_dest_reg + ypc_ratio_reg + remcost_reg), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)
rfanex7 = reg(rho_fund_est[(rho_fund_est[:,:remshare_reg] .!= 0.0),:], @formula(log_remshare_reg ~ ypc_orig_reg + ypc_ratio_reg + remcost_reg), Vcov.cluster(:OrigCategorical, :DestCategorical), save=:residuals)
rfanex8 = reg(rho_fund_est[(rho_fund_est[:,:remshare_reg] .!= 0.0),:], @formula(log_remshare_reg ~ ypc_dest_reg + ypc_ratio_reg + remcost_reg + fe(OrigCategorical) + fe(DestCategorical)), Vcov.cluster(:OrigCategorical, :DestCategorical), save=true)

regtable(rfanex1, rfanex2, rfanex5, rfanex6; renderSettings = latexOutput(),regression_statistics=[:nobs, :r2])     
# rfanex6 appears to make most sense. 
rho_fund_est[!,:residual_ratio] = residuals(rfanex6, rho_fund_est)
rho_fund_est[!,:residual_dest] = residuals(rfanex5, rho_fund_est)
rho_fund_est[!,:exp_residual] = [exp(rho_fund_est[i,:residual_ratio]) for i in 1:size(rho_fund_est, 1)]     # need exp(residuals)

CSV.write(joinpath(@__DIR__,"../input_data/rho_fund_est.csv"),rho_fund_est)

# Sorting the data
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
rho_fund_est = join(rho_fund_est, regionsdf, on = [:originregion, :destinationregion])
sort!(rho_fund_est, (:indexo, :indexd))
CSV.write("../data_mig/remres.csv", rho_fund_est[:,union(1:2,13)]; writeheader=false)

# Compare remshare as estimated directly at FUND level with as calculated with MigFUND: MigFUND version way too small
test=join(
    remshare_all[.&(remshare_all[:,:year].==2015,remshare_all[:,:scen].==s,remshare_all[:,:remshare_type].==Symbol("remshare_currentborders")),union(2,4:5)],
    rename(rho_fund_est[:,1:3],:originregion=>:origin,:destinationregion=>:destination),
    on=[:origin,:destination]
)
test[!,:xfactor] = test[:,:remshare_reg] ./ test[:,:remshare]
sort(test,:xfactor)


############################## Calculating residuals from remshare estimation at FUND region level ######################################
############################## First method: weight exp(residuals) by remittances flows #################################################
data_res = gravity_17[:,[:orig,:dest,:exp_residual]]

# Reading remittances flows at country * country level; data for 2017 from World Bank.
remittances_flow = load(joinpath(@__DIR__, "../input_data/WB_Bilateral_Remittance_Estimates_2017.xlsx"), "Bilateral_Remittances_2017!A1:HH217") |> DataFrame
header = 2
countriesr = remittances_flow[(header):(length(remittances_flow[:,1]) - 1), 1]
remflow = DataFrame(sending = repeat(countriesr, inner = length(countriesr)), receiving = repeat(countriesr, outer = length(countriesr)))
flow = []
for o in (header):(length(countriesr) + 1)
    oflow = remittances_flow[o, 2:(end-1)]
    append!(flow, oflow)
end
remflow[:remittanceflows] = flow
indmissing = findall([typeof(remflow[i,:remittanceflows]) != Float64 for i in 1:size(remflow, 1)])
for i in indmissing
    remflow[:remittanceflows][i] = 0.0
end    

# Matching with country codes.
country_iso3c = CSV.read("../input_data/country_iso3c.csv")
matching = join(DataFrame(country = countriesr), country_iso3c, on = :country, kind = :left)
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

remflow = join(remflow, rename(matching,:iso3c => :dest,:country=>:sending), on = :sending)
remflow = join(remflow, rename(matching,:iso3c => :orig,:country=>:receiving), on = :receiving)

remres = join(remflow[:,3:5],data_res,on=[:orig,:dest])

# Transposing to FUND region * region level. We weight corridors by remittances flows.
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
remres = join(remres, rename(iso3c_fundregion,:iso3c=>:orig,:fundregion=>:originregion), on = :orig, kind = :left)
remres = join(remres, rename(iso3c_fundregion,:iso3c=>:dest,:fundregion=>:destinationregion), on = :dest, kind = :left)

weight = by(remres, [:originregion, :destinationregion], df -> sum(df[:,:remittanceflows]))
remres = join(remres, weight, on = [:originregion, :destinationregion], kind = :left)
remres[!,:w1] = [remres[i,:x1] != 0.0 ? remres[i,:remittanceflows] / remres[i,:x1] : 0.0 for i in 1:size(remres, 1)]
remres_r = by(remres, [:originregion, :destinationregion], df -> sum(df.w1 .* df.exp_residual))
rename!(remres_r, :x1 => :remres)

# Sorting the data
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
remres_r = join(remres_r, regionsdf, on = [:originregion, :destinationregion])
sort!(remres_r, (:indexo, :indexd))
delete!(remres_r, [:indexo, :indexd])
CSV.write("../data_mig/remres.csv", remres_r; writeheader=false)


############################## Second method: weight exp(residuals) by weights suggested with Marc #################################################
data_resweight = gravity_17[:,union(1:6,13)]
data_resweight[!,:gdp_orig] = data_resweight[:,:ypc_orig] .* data_resweight[:,:pop_orig]
data_resweight[!,:gdp_dest] = data_resweight[:,:ypc_dest] .* data_resweight[:,:pop_dest]

data_resweight = join(data_resweight, migstock[:,3:5], on = [:orig,:dest])

data_resweight = join(data_resweight, rename(iso3c_fundregion, :iso3c=>:orig,:fundregion=>:originregion),on=:orig)
data_resweight = join(data_resweight, rename(iso3c_fundregion, :iso3c=>:dest,:fundregion=>:destinationregion),on=:dest)

# Calculate appropriate weights for exp(residuals)
data_resweight_calc = by(data_resweight, [:originregion,:destinationregion], d -> (pop_orig_reg = sum(d.pop_orig),gdp_orig_reg=sum(d.gdp_orig),pop_dest_reg = sum(d.pop_dest),gdp_dest_reg=sum(d.gdp_dest),migstock_reg=sum(d.migrantstocks)))
data_resweight = join(data_resweight, data_resweight_calc, on=[:originregion,:destinationregion])
data_resweight[!,:ypc_mig] = [max((data_resweight[i,:ypc_orig] + data_resweight[i,:ypc_dest])/2,data_resweight[i,:ypc_orig]) for i in 1:size(data_resweight,1)]
data_resweight[!,:ypc_mig_reg] = [max((data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg] + data_resweight[i,:gdp_dest_reg]/data_resweight[i,:pop_dest_reg])/2,data_resweight[i,:gdp_orig_reg]/data_resweight[i,:pop_orig_reg]) for i in 1:size(data_resweight,1)]
data_resweight[!,:res_weight] = data_resweight[:,:migrantstocks] ./ data_resweight[:,:migstock_reg] .* data_resweight[:,:ypc_mig] ./ data_resweight[:,:ypc_mig_reg]
for i in 1:size(data_resweight,1)
    if data_resweight[i,:migstock_reg] == 0.0
        data_resweight[i,:res_weight] = 0.0
    end
end
# !!! Weight exp(residuals), instead of taking exp of weighted residuals !!!
data_resweight[!,:exp_res_weighted] = map(x -> exp(x),data_resweight[:,:residual_ratio]) .* data_resweight[:,:res_weight]

# Prepare remshare estimation at FUND region level
data_resweight_fund = by(data_resweight, [:originregion,:destinationregion], d -> sum(d.exp_res_weighted))
rename!(data_resweight_fund, :x1 => :remres)

# Sorting the data
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
data_resweight_fund = join(data_resweight_fund, regionsdf, on = [:originregion, :destinationregion])
sort!(data_resweight_fund, (:indexo, :indexd))
delete!(data_resweight_fund, [:indexo, :indexd])
CSV.write("../data_mig/remres.csv", data_resweight_fund; writeheader=false)

# Compare exp(residuals) from country*country level weighted as here, with exp(residuals) from region*region level as above
remres_comp = stack(join(rename(data_resweight_fund,:remres=>:country), rename(rho_fund_est[:,union(1:2,13)],:exp_residual=>:region), on=[:originregion,:destinationregion]), 3:4)
rename!(remres_comp,:variable=>:type,:value=>:exp_epsilon)

remres_comp |> @vlplot(
    mark={:point, filled=true, size=80}, width=260, columns=4, wrap={"destinationregion:o", title="Residuals from remshare estimation for each destination region", header={labelFontSize=24,titleFontSize=20}},  
    y={"exp_epsilon:q", axis={labelFontSize=16, titleFontSize=16}, title="exp(epsilon_od)"},
    x={"originregion:o", title = "Origin region", axis={labelFontSize=16, titleFontSize=16}},
    resolve = {scale={y=:independent}},
    color={"originregion:o", scale={scheme=:tableau20}, legend={title="Origin region", titleFontSize=16, symbolSize=60, labelFontSize=16}},
    shape={"type:o", scale={range=["circle", "triangle-up"]}, legend={title="Estimation level", titleFontSize=16, symbolSize=60, labelFontSize=16}}
) |> save(joinpath(@__DIR__, "../results/gravity/", "exp_epsilon_countryregion.png"))