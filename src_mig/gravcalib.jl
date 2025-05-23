using CSV, DataFrames, DelimitedFiles, ExcelFiles, XLSX
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths, ImageIO, ImageMagick
using Statistics, Query, Distributions, StatsPlots, Distances
using FixedEffectModels, RegressionTables
using GLM


########################## Prepare migration flows data from Abel and Cohen (2019) ########################################
migflow_allstockdemo = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Abel_data/gf_imr.csv") |> DataFrame
migflow_alldata = CSV.File(joinpath(@__DIR__, "../input_data/ac19.csv")) |> DataFrame          # Use Abel and Cohen (2019)

# From Abel's paper, we choose demographic data from the UN's WPP2015, and migrant stock data from the World Bank for 1960-1990 and the UN for 1990-2015.
migflow = @from i in migflow_allstockdemo begin
    @where i.demo == "wpp2015" && i.sex == "b" && ((i.stock == "wb11" && i.year0 < 1990) || (i.stock == "un15" && i.year0 >= 1990))
    @select {i.stock, i.demo, i.sex, i.year0, i.interval, i.orig, i.dest, i.orig_code, i.dest_code, i.flow}
    @collect DataFrame
end

# From Abel and Cohen's paper, we choose Azose and Raftery's data for 1990-2015, on Guy Abel's suggestion (based a demographic accounting, pseudo-Bayesian method, which performs the best)
migflow_ar = migflow_alldata[:,[:year0, :orig, :dest, :da_pb_closed]]

########################## Prepare population data from the Wittgenstein Centre, based on historical data from the WPP 2019 ##################################
pop_allvariants = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/data_large/WPP2019.csv") |> DataFrame
# We use the Medium variant, the most commonly used. Unit: thousands
pop = @from i in pop_allvariants begin
    @where i.Variant == "Medium" && i.Time < 2016 
    @select {i.LocID, i.Location, i.Time, i.PopTotal}
    @collect DataFrame
end

########################## Prepare gdp data from the World Bank's WDI as available at the IIASA SSP database #####################
# Unit: billion US$ 2005 / year PPP
gdp_unstacked = XLSX.readdata(joinpath(@__DIR__, "../input_data/gdphist.xlsx"), "data!A2:Q184")
gdp_unstacked = DataFrame(gdp_unstacked, :auto)
rename!(gdp_unstacked, Symbol.(Vector(gdp_unstacked[1,:])))
deleteat!(gdp_unstacked,1)
select!(gdp_unstacked, Not([:Model, Symbol("Scenario (History)"), :Variable, :Unit]))
gdp = stack(gdp_unstacked, 2:size(gdp_unstacked, 2))
rename!(gdp, :variable => :year0, :value => :gdp)
gdp[!,:year0] = map( x -> parse(Int, String(x)), gdp[!,:year0])


########################## Prepare distance data based on UN POP data on capital cities coordinates ##############################
loc = load(joinpath(@__DIR__, "../input_data/WUP2014-F13-Capital_Cities.xls"), "DATA!A17:J257") |> DataFrame
# choose one capital per country (needed for 8 countries)
inddupl = []
for c in ["Yamoussoukro", "Pretoria", "Bloemfontein", "Porto-Novo", "Sucre", "Sri Jayewardenepura Kotte", "s-Gravenhage (The Hague)", "St. Peter Port"]
    ind = findfirst(x -> x == c, loc[!,Symbol("Capital City")])
    append!(inddupl, ind)
end
sort!(inddupl)
deleteat!(loc, inddupl)
select!(loc, Not([:Index, Symbol("Capital City"), :Note, Symbol("Capital Type"), Symbol("City code"), Symbol("Population (thousands)")]))
loc[!,Symbol("Country code")] = map( x -> trunc(Int, x), loc[!,Symbol("Country code")])
rename!(loc, Symbol("Country code") => :country_code, Symbol("Country or area") => :country)
push!(loc, ["Taiwan", 158, 25.0330, 121.5654])

earthradius = 6372.8        # in km

# Calculating distances between countries as distances between their capital cities, using the Haversine formula of the Distances package
dist = DataFrame(orig_code = repeat(loc[!,:country_code], inner = size(loc,1)), lat_or = repeat(loc[!,:Latitude], inner = size(loc,1)), lon_or = repeat(loc[!,:Longitude], inner = size(loc,1)), dest_code = repeat(loc[!,:country_code], outer = size(loc,1)), lat_dest = repeat(loc[!,:Latitude], outer = size(loc,1)), lon_dest = repeat(loc[!,:Longitude], outer = size(loc,1)))
dist[!,:loc_or] = [tuple(dist[i,:lat_or], dist[i,:lon_or]) for i in 1:size(dist,1)]
dist[!,:loc_dest] = [tuple(dist[i,:lat_dest], dist[i,:lon_dest]) for i in 1:size(dist,1)]
dist[!,:distance] = [haversine(dist[i,:loc_or], dist[i,:loc_dest], earthradius) for i in 1:size(dist, 1)]

iso3c_isonum = CSV.read(joinpath(@__DIR__, "../input_data/iso3c_isonum.csv"), DataFrame) 
dist = innerjoin(dist, rename(iso3c_isonum, :isonum => :orig_code), on = :orig_code)
rename!(dist, :iso3c => :orig)
dist = innerjoin(dist, rename(iso3c_isonum, :isonum => :dest_code), on = :dest_code)
rename!(dist, :iso3c => :dest)
select!(dist, [:orig,:dest,:distance])


########################################### Prepare remittance data based on World Bank data ##############################
rho = CSV.read(joinpath(@__DIR__, "../input_data/rho.csv"), DataFrame)
phi = CSV.read(joinpath(@__DIR__,"../input_data/phi.csv"), DataFrame)
remittances = leftjoin(rho, phi, on = [:origin, :destination])
# For corridors with no cost data we assume that the cost of sending remittances is the mean of all available corridors
for i in eachindex(remittances[:,1])
    if ismissing(remittances[i,:phi])
        remittances[i,:phi] = (remittances[i,:origin] == remittances[i,:destination] ? 0.0 : mean(skipmissing(phi.phi)))
    end
end


############################################ Prepare land surface data from WDI (World Bank) #######################
land = XLSX.readdata(joinpath(@__DIR__,"../input_data/land_area.xlsx"), "Data!A1:E218") 
land = DataFrame(land, :auto)
rename!(land, Symbol.(Vector(land[1,:])))
deleteat!(land,1)
rename!(land, Symbol("Country Code") => :country, Symbol("2017 [YR2017]") => :area)
select!(land, [:country, :area])

# Deal with Sudan and South Sudan: Sudan surface is 1,886,068 km^2
ind_ssd = findfirst(land[!,:country].=="SSD")
delete!(land,ind_ssd)
ind_sdn = findfirst(land[!,:country].=="SDN")
land[ind_sdn,:area] = 1886068 


############################################# Prepare data on common official languages #############################
countries = unique(migflow_ar[:,:orig])
comol = DataFrame(
    orig = repeat(countries, inner = length(countries)), 
    dest = repeat(countries, outer=length(countries)), 
    comofflang = zeros(length(countries)^2)
)

# Assign common official languages
offlang = Dict(
    "Chinese" => ["CHN", "TWN","HKG","SGP","MAC"],
    "Spanish" => ["MEX", "COL","ARG","ESP","VEN","PER","CHL","ECU","CUB","GTM","DOM","HND","BOL","SLV","NIC","CRI","PRY","URY","PAN","PRI","GNQ"],
    "English" => ["USA","GBR","CAN","AUS","ZAF","IRL","GHA","NZL","SGP","LBR","PAN","ZWE","ZMB","HKG","JEY","VGB","GUM","BMU","CYM","BWA","LCA","GIB","MLT","BLZ","MNP","VUT","SYC","COK","FLK","PLW","ASM","WSM","NFK","NIU","TKL","NRU","ATG","BHS","BRB","BDI","CMR","DMA","SWZ","FJI","GMB","GRD","GUY","IND","JAM","KEN","KIR","LSO","MWI","MHL","FSM","NAM","NGA","PAK","PNG","PHL","RWA","KNA","VCT","SLE","SLB","SSD","SDN","TZA","TON","TTO","TUV","UGA"],
    "Arabic" => ["EGY","DZA","SAU","IRQ","YEM","MAR","SDN","SYR","JOR","TUN","LBY","LBN","ARE","OMN","KWT","TCD","ISR","QAT","BHR","ESH","DJI","COM","ERI","MRT","PSE","SOM","TZA"],
    "Portuguese" => ["BRA","AGO","PRT","MOZ","GNB","STP","CPV","MAC","GNQ","TLS"],
    "Russian" => ["RUS","BLR","KGZ","KAZ"],
    "German" => ["DEU","AUT","CHE","BEL","LIE","LUX"],
    "Tamil" => ["SGP","LKA","IND"],
    "French" => ["FRA","CAN","BEL","CHE","MLI","PYF","NCL","MYT","BDI","LUX","MCO","RWA","WLF","VUT","SYC","COD","CMR","MDG","CIV","NER","BFA","SEN","TCD","GIN","BEN","HTI","TGO","CAF","COG","GAB","GNQ","DJI"],
    "Korean" => ["PRK","KOR"],
    "Turkish" => ["TUR","CYP"],
    "Italian" => ["ITA","CHE","SMR"],
    "Malay" => ["IDN","MYS","SGP","BRN"],
    "Hindustani" => ["FJI","IND","PAK"],
    "Sotho" => ["ZAF","LSO","ZWE"],
    "Quechua" => ["PER","BOL","ECU"],
    "Persian" => ["IRN","AFG","TJK"],
    "Dutch" => ["NLD","BEL","SUR"],
    "Yoruba" => ["NGA","BEN","TGO","BRA"],
    "Swahili" => ["TZA","KEN","UGA","RWA"],
    "Hausa" => ["NGA","NER","CMR","GHA","BEN","CIV","TGO","SDN"],
    "Aymara" => ["PER","BOL"],
    "Bengali" => ["BGD","IND"],
    "Berber" => ["DZA","MAR"],
    "Greek" => ["GRC","CYP"],
    "Guarani" => ["BOL","PRY"],
    "Romanian" => ["ROU","MDA"],
    "Rundi" => ["BDI","RWA"],
    "Swati" => ["ZAF","SWZ"],
    "Swedish" => ["SWE","FIN"],
    "Tswana" => ["ZAF","BWA"]
)

for i in eachindex(comol[:,1]) ; if comol[i,:orig] == comol[i,:dest] ; comol[i,:comofflang] = 1 end end
for l in offlang
    for c1 in l[2]
        for c2 in l[2]
            ind = intersect(findall(comol.orig .==c1),findall(comol.dest .==c2))
            if !isempty(ind)
                comol[ind[1],:comofflang] = 1
            end
        end
    end
end


############################################# Prepare data on regional damages from FUND ############################
damcalib = CSV.read(joinpath(@__DIR__, "../input_data/damcalib.csv"), DataFrame;header=false)


############################################# Join the datasets #########################################
# Joining the datasets
data = innerjoin(migflow, dist, on = [:orig, :dest])
select!(data, Not([:stock, :demo, :sex]))
data[!,:flow] = float(data[!,:flow])
rename!(data, :flow => :flow_Abel)
# Or for Raftery's data
data_ar = innerjoin(migflow_ar, dist, on = [:orig, :dest])
rename!(data_ar, :da_pb_closed => :flow_AzoseRaftery)

rename!(pop, :LocID => :orig_code, :Time => :year0)
data = innerjoin(data, pop, on = [:year0, :orig_code])
rename!(data, :Location => :orig_name, :PopTotal => :pop_orig)
rename!(pop, :orig_code => :dest_code)
data = innerjoin(data, pop, on = [:year0, :dest_code])
rename!(data, :Location => :dest_name, :PopTotal => :pop_dest)
# Or for Raftery's data
rename!(pop, :dest_code => :isonum)
pop = innerjoin(pop, iso3c_isonum, on = :isonum)
rename!(pop, :iso3c => :orig, :PopTotal => :pop_orig)
data_ar = innerjoin(data_ar, pop[:,[:year0, :pop_orig, :orig]], on = [:year0, :orig])
rename!(pop, :orig => :dest, :pop_orig => :pop_dest)
data_ar = innerjoin(data_ar, pop[:,[:year0, :pop_dest, :dest]], on = [:year0, :dest])

rename!(gdp, :Region => :orig)
data = innerjoin(data, gdp, on = [:year0, :orig])
data_ar = innerjoin(data_ar, gdp, on = [:year0, :orig])
rename!(data, :gdp => :gdp_orig)
rename!(data_ar, :gdp => :gdp_orig)
rename!(gdp, :orig => :dest)
data = innerjoin(data, gdp, on = [:year0, :dest])
data_ar = innerjoin(data_ar, gdp, on = [:year0, :dest])
rename!(data, :gdp => :gdp_dest)
rename!(data_ar, :gdp => :gdp_dest)

rename!(remittances, :origin => :orig, :destination => :dest, :rho => :remshare, :phi => :remcost)
data = innerjoin(data, remittances, on = [:orig,:dest])
data_ar = innerjoin(data_ar, remittances, on =[:orig, :dest])

rename!(land, :country => :orig, :area => :area_orig)
data = innerjoin(data, land, on = :orig)
data_ar = innerjoin(data_ar, land, on = :orig)
rename!(land, :orig => :dest, :area_orig => :area_dest)
data = innerjoin(data, land, on = :dest)
data_ar = innerjoin(data_ar, land, on = :dest)

data = innerjoin(data, comol, on = [:orig,:dest])
data_ar = innerjoin(data_ar, comol, on = [:orig,:dest])

# we attribute regional exposure (damages/GDP) levels to all countries in each region
iso3c_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/iso3c_fundregion.csv"), DataFrame)
data = innerjoin(data, rename(iso3c_fundregion, :fundregion => :originregion, :iso3c => :orig), on =:orig)
data = innerjoin(data, rename(iso3c_fundregion, :fundregion => :destinationregion, :iso3c => :dest), on =:dest)
data_ar = innerjoin(data_ar, rename(iso3c_fundregion, :fundregion => :originregion, :iso3c => :orig), on =:orig)
data_ar = innerjoin(data_ar, rename(iso3c_fundregion, :fundregion => :destinationregion, :iso3c => :dest), on =:dest)
data = innerjoin(data, rename(damcalib, :Column1=>:year0, :Column2=>:originregion,:Column3=>:expo_orig),on=[:year0,:originregion])
data = innerjoin(data, rename(damcalib, :Column1=>:year0, :Column2=>:destinationregion,:Column3=>:expo_dest),on=[:year0,:destinationregion])
data_ar = innerjoin(data_ar, rename(damcalib, :Column1=>:year0, :Column2=>:originregion,:Column3=>:expo_orig),on=[:year0,:originregion])
data_ar = innerjoin(data_ar, rename(damcalib, :Column1=>:year0, :Column2=>:destinationregion,:Column3=>:expo_dest),on=[:year0,:destinationregion])

# Making units consistent 
data[!,:flow_Abel] ./= data[!,:interval]               # flows are for a multiple-year period. we compute annual migrant flows as constant over said period
# Or for Raftery's data:
data_ar[!,:flow_AzoseRaftery] ./= 5
data_ar[!,:pop_orig] .*= 1000        # pop is in thousands
data_ar[!,:pop_dest] .*= 1000
data_ar[!,:gdp_orig] .*= 10^9        # gdp is in billion $
data_ar[!,:gdp_dest] .*= 10^9
data[!,:pop_orig] .*= 1000        # pop is in thousands
data[!,:pop_dest] .*= 1000
data[!,:gdp_orig] .*= 10^9        # gdp is in billion $
data[!,:gdp_dest] .*= 10^9

# Creating gdp per capita variables
data[!,:ypc_orig] = data[!,:gdp_orig] ./ data[!,:pop_orig]
data[!,:ypc_dest] = data[!,:gdp_dest] ./ data[!,:pop_dest]
data[!,:ypc_ratio] = data[!,:ypc_dest] ./ data[!,:ypc_orig]
data_ar[!,:ypc_orig] = data_ar[!,:gdp_orig] ./ data_ar[!,:pop_orig]
data_ar[!,:ypc_dest] = data_ar[!,:gdp_dest] ./ data_ar[!,:pop_dest]
data_ar[!,:ypc_ratio] = data_ar[!,:ypc_dest] ./ data_ar[!,:ypc_orig]

# Creating ypc for other countries
data_all = combine(groupby(unique(data[:,[:year0,:orig,:pop_orig,:gdp_orig]]), :year0), d->(pop_all=sum(skipmissing(d.pop_orig)), gdp_all=sum(skipmissing(d.gdp_orig))))
data = innerjoin(data, data_all, on = :year0)
data[!,:ypc_other] = (data[!,:gdp_all] .- data[!,:gdp_orig] .- data[!,:gdp_dest]) ./ (data[!,:pop_all] .- data[!,:pop_orig] .- data[!,:pop_dest]) 
data_ar_all = combine(groupby(unique( data_ar[:,[:year0,:orig,:pop_orig,:gdp_orig]]), :year0), d->(pop_all=sum(skipmissing(d.pop_orig)), gdp_all=sum(skipmissing(d.gdp_orig))))
 data_ar = innerjoin( data_ar,  data_ar_all, on = :year0)
 data_ar[!,:ypc_other] = ( data_ar[!,:gdp_all] .-  data_ar[!,:gdp_orig] .-  data_ar[!,:gdp_dest]) ./ ( data_ar[!,:pop_all] .-  data_ar[!,:pop_orig] .-  data_ar[!,:pop_dest]) 

# Create ratios of move_od / stay_o variables
emig = combine(groupby(data, [:year0,:orig]), d->sum(d.flow_Abel))
rename!(emig, :x1 => :emig)
data = innerjoin(data, emig, on=[:year0,:orig])
data[!,:stay_orig] = data[!,:pop_orig] .- data[!,:emig]
data[!,:mig_ratio] = data[!,:flow_Abel] ./ data[!,:stay_orig]
data[!,:mig_ratio_tot] = data[!,:flow_Abel] ./ data[!,:pop_orig]
emig_ar = combine(groupby(data_ar, [:year0,:orig]), d->sum(d.flow_AzoseRaftery))
rename!(emig_ar, :x1 => :emig)
data_ar = innerjoin(data_ar, emig_ar, on=[:year0,:orig])
data_ar[!,:stay_orig] = data_ar[!,:pop_orig] .- data_ar[!,:emig]
data_ar[!,:mig_ratio] = data_ar[!,:flow_AzoseRaftery] ./ data_ar[!,:stay_orig]
data_ar[!,:mig_ratio_tot] = data_ar[!,:flow_AzoseRaftery] ./ data_ar[!,:pop_orig]

# Create density variables
data[!,:density_orig] = data[!,:pop_orig] ./ data[!,:area_orig]
data[!,:density_dest] = data[!,:pop_dest] ./ data[!,:area_dest]
data[!,:density_ratio] = data[!,:density_dest] ./ data[!,:density_orig]
data_ar[!,:density_orig] = data_ar[!,:pop_orig] ./ data_ar[!,:area_orig]
data_ar[!,:density_dest] = data_ar[!,:pop_dest] ./ data_ar[!,:area_dest]
data_ar[!,:density_ratio] = data_ar[!,:density_dest] ./ data_ar[!,:density_orig]


#################################################### Calibrate the gravity equation ##################################
# log transformation
logdata = DataFrame(
    year = data[!,:year0], 
    orig = data[!,:orig], 
    dest = data[!,:dest],
    remshare = data[!,:remshare], 
    remcost = data[!,:remcost],
    comofflang = data[!,:comofflang],
    expo_orig = data[!,:expo_orig],
    expo_dest = data[!,:expo_dest]
)
for name in [:flow_Abel, :mig_ratio, :mig_ratio_tot, :pop_orig, :pop_dest, :area_orig, :area_dest, :density_orig, :density_dest, :density_ratio, :gdp_orig, :gdp_dest, :ypc_orig, :ypc_dest, :ypc_ratio, :ypc_other, :distance]
    logdata[!,name] = [log(data[i,name]) for i in eachindex(logdata[:,1])]
end
logdata_ar = DataFrame(
    year = data_ar[!,:year0], 
    orig = data_ar[!,:orig], 
    dest = data_ar[!,:dest], 
    remshare = data_ar[!,:remshare], 
    remcost = data_ar[!,:remcost],
    comofflang = data_ar[!,:comofflang],
    expo_orig = data_ar[!,:expo_orig],
    expo_dest = data_ar[!,:expo_dest]
)
for name in [:flow_AzoseRaftery, :mig_ratio, :mig_ratio_tot, :pop_orig, :pop_dest, :area_orig, :area_dest, :density_orig, :density_dest, :density_ratio, :gdp_orig, :gdp_dest, :ypc_orig, :ypc_dest, :ypc_ratio, :ypc_other, :distance]
    logdata_ar[!,name] = [log(data_ar[i,name]) for i in eachindex(logdata_ar[:,1])]
end

# Remove rows with distance = 0 or flow = 0
gravity = @from i in logdata begin
    @where i.distance != -Inf && i.flow_Abel != -Inf && i.mig_ratio_tot != -Inf && i.mig_ratio != -Inf
    @select {i.year, i.orig, i.dest, i.flow_Abel, i.mig_ratio, i.mig_ratio_tot, i.pop_orig, i.pop_dest, i.area_orig, i.area_dest, i.density_orig, i.density_dest, i.density_ratio, i.gdp_orig, i.gdp_dest, i.ypc_orig, i.ypc_dest, i.ypc_ratio, i.ypc_other, i.distance, i.remshare, i.remcost, i.comofflang,i.expo_orig,i.expo_dest}
    @collect DataFrame
end
dropmissing!(gravity)       # remove rows with missing values in ypc_orig or ypc_dest
gravity_ar = @from i in logdata_ar begin
    @where i.distance != -Inf && i.mig_ratio_tot != -Inf && i.mig_ratio != -Inf && i.flow_AzoseRaftery != -Inf
    @select {i.year, i.orig, i.dest, i.flow_AzoseRaftery, i.mig_ratio, i.mig_ratio_tot, i.pop_orig, i.pop_dest, i.area_orig, i.area_dest, i.density_orig, i.density_dest, i.density_ratio, i.gdp_orig, i.gdp_dest, i.ypc_orig, i.ypc_dest, i.ypc_ratio, i.ypc_other, i.distance, i.remshare, i.remcost, i.comofflang,i.expo_orig,i.expo_dest}
    @collect DataFrame
end
dropmissing!(gravity_ar) 


##################################################### Second specification: considering remshare endogenous #################################
# Reading GDP per capita at country level; data for 2017 from World Bank(WDI), in current USD. 
ypc_2017 = readdlm(joinpath(@__DIR__,"../input_data/ypc2017.csv"), ';', comments = true)
ypc2017 = DataFrame(iso3c = ypc_2017[2:end,1], ypc = ypc_2017[2:end,2])

data_17 = innerjoin(ypc2017, iso3c_isonum, on=:iso3c)
dropmissing!(data_17)       # remove rows with missing values in ypc

data_17 = innerjoin(data_17, rename(pop_allvariants[.&(pop_allvariants[:,:Variant].=="Medium", pop_allvariants[:,:Time].==2017),[:LocID,:PopTotal]], :LocID=>:isonum), on=:isonum)
data_17[!,:PopTotal] .*= 1000        # pop is in thousands

gravity_17 = innerjoin(rename(data_17, :iso3c => :orig, :ypc=>:ypc_orig,:PopTotal=>:pop_orig)[:,Not(:isonum)], remittances, on=:orig)
gravity_17 = innerjoin(rename(data_17,:iso3c=>:dest,:ypc=>:ypc_dest,:PopTotal=>:pop_dest)[:,Not(:isonum)], gravity_17, on=:dest)
gravity_17[!,:ypc_ratio] = gravity_17[!,:ypc_dest] ./ gravity_17[!,:ypc_orig]

# log transformation
for name in [:pop_orig, :pop_dest, :ypc_orig, :ypc_dest, :ypc_ratio]
    gravity_17[!,name] = [log(gravity_17[i,name]) for i in eachindex(gravity_17[:,1])]
end
gravity_17[!,:log_remshare] = [log(gravity_17[i,:remshare]) for i in eachindex(gravity_17[:,1])]

# Regress remshare on log(ypc_orig), log(ypc_dest) (or ypc_ratio) and remcost
r17anex1 = reg(gravity_17, @formula(remshare ~ ypc_orig + ypc_dest + remcost), Vcov.cluster(:orig, :dest), save=true)
r17anex2 = reg(gravity_17, @formula(remshare ~ ypc_dest + ypc_ratio + remcost), Vcov.cluster(:orig, :dest), save=true)
r17anex3 = reg(gravity_17, @formula(remshare ~ ypc_orig + ypc_ratio + remcost), Vcov.cluster(:orig, :dest), save=true)
r17anex4 = reg(gravity_17, @formula(remshare ~ ypc_dest + ypc_ratio + remcost + fe(orig) + fe(dest)), Vcov.cluster(:orig, :dest), save=true)

# Regress log(remshare) on log(ypc_orig), log(ypc_dest) (or ypc_ratio) and remcost
r17anex5 = reg(gravity_17[(gravity_17[:,:remshare] .!= 0.0),:], @formula(log_remshare ~ ypc_orig + ypc_dest + remcost), Vcov.cluster(:orig, :dest), save=true)
r17anex6 = reg(gravity_17[(gravity_17[:,:remshare] .!= 0.0),:], @formula(log_remshare ~ ypc_dest + ypc_ratio + remcost), Vcov.cluster(:orig, :dest), save=true)
r17anex7 = reg(gravity_17[(gravity_17[:,:remshare] .!= 0.0),:], @formula(log_remshare ~ ypc_orig + ypc_ratio + remcost), Vcov.cluster(:orig, :dest), save=:residuals)
r17anex8 = reg(gravity_17[(gravity_17[:,:remshare] .!= 0.0),:], @formula(log_remshare ~ ypc_dest + ypc_ratio + remcost + fe(orig) + fe(dest)), Vcov.cluster(:orig, :dest), save=true)

regtable(r17anex1, r17anex2, r17anex5, r17anex6; render = LatexTable(),regression_statistics=[:nobs, :r2])     
# r17anex6 appears to make most sense. 
gravity_17[!,:residual_ratio] = residuals(r17anex6, gravity_17)
gravity_17[!,:residual_dest] = residuals(r17anex5, gravity_17)
gravity_17[!,:exp_residual] = [exp(gravity_17[i,:residual_ratio]) for i in eachindex(gravity_17[:,1])]     # need exp(residuals)

# Join to gravity estimation data, considering remshare endogeneous 
gravity_endo = innerjoin(gravity_ar, gravity_17[:,[:orig,:dest,:residual_ratio]], on=[:orig,:dest])
gravity_endo_abel = innerjoin(gravity, gravity_17[:,[:orig,:dest,:residual_ratio]], on=[:orig,:dest])
gravity_endo[!,:exp_residual] = [exp(gravity_endo[i,:residual_ratio]) for i in eachindex(gravity_endo[:,1])]     # need exp(residuals)
gravity_endo_abel[!,:exp_residual] = [exp(gravity_endo_abel[i,:residual_ratio]) for i in eachindex(gravity_endo_abel[:,1])]     # need exp(residuals)

# Estimate the main gravity equation using residuals from remshare regression
re1 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
re2 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
re3 = reg(gravity_endo, @formula(mig_ratio_tot ~ density_ratio + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
re4 = reg(gravity_endo, @formula(mig_ratio_tot ~ density_ratio + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
re5 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
re6 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(re1, re2, re3, re4, re5, re6; render = LatexTable(),regression_statistics=[:nobs, :r2 ])     

beta_endo = DataFrame(
    regtype = ["reg_endo_yfe","reg_endo_odyfe","reg_endo_abel_yfe", "reg_endo_abel_odyfe"],
    b1 = [0.689,0.713,0.606,1.684],       # pop_orig
    b2 = [0.687,-0.720,0.615,-1.225],       # pop_dest
    b4 = [0.417,0.171,0.113,0.197],       # ypc_orig
    b5 = [0.831,0.010,0.806,-0.123],       # ypc_dest
    b7 = [-1.299,-1.490,-1.047,-1.324],       # distance
    b8 = [0.011,0.010,0.002,0.006],       # exp_residual
    b9 = [-8.928,-12.144,-15.163,-14.013],       # remcost
    b10 = [1.733,1.584,1.579,1.335]     # comofflang
)
beta_endo_ratio = DataFrame(
    regtype = ["reg_ratio_endo_yfe","reg_ratio_endo_odyfe"],
    b3 = [0.041,-0.218],       # density_ratio
    b6 = [0.141,-0.089],       # ypc_ratio
    b7 = [-1.161,-1.490],       # distance
    b8 = [0.015,0.010],       # exp_residual
    b9 = [-10.162,-12.137],       # remcost
    b10 = [1.186,1.585]       # comofflang
)

# Compute constant including year fixed effect as average of beta0 + yearFE
cst_endo_yfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re1))
cst_endo_yfe[!,:constant] = cst_endo_yfe[!,:flow_AzoseRaftery] .- beta_endo[1,:b1] .* cst_endo_yfe[!,:pop_orig] .- beta_endo[1,:b2] .* cst_endo_yfe[!,:pop_dest] .- beta_endo[1,:b4] .* cst_endo_yfe[!,:ypc_orig] .- beta_endo[1,:b5] .* cst_endo_yfe[!,:ypc_dest] .- beta_endo[1,:b7] .* cst_endo_yfe[!,:distance] .- beta_endo[1,:b8] .* cst_endo_yfe[!,:exp_residual] .- beta_endo[1,:b9] .* cst_endo_yfe[!,:remcost] .- beta_endo[1,:b10] .* cst_endo_yfe[!,:comofflang]
constant_endo_yfe = mean(cst_endo_yfe[!,:constant])

cst_endo_odyfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re2))
cst_endo_odyfe[!,:constant] = cst_endo_odyfe[!,:flow_AzoseRaftery] .- beta_endo[2,:b1] .* cst_endo_odyfe[!,:pop_orig] .- beta_endo[2,:b2] .* cst_endo_odyfe[!,:pop_dest] .- beta_endo[2,:b4] .* cst_endo_odyfe[!,:ypc_orig] .- beta_endo[2,:b5] .* cst_endo_odyfe[!,:ypc_dest] .- beta_endo[2,:b7] .* cst_endo_odyfe[!,:distance] .- beta_endo[2,:b8] .* cst_endo_odyfe[!,:exp_residual] .- beta_endo[2,:b9] .* cst_endo_odyfe[!,:remcost] .- beta_endo[2,:b10] .* cst_endo_odyfe[!,:comofflang] .- cst_endo_odyfe[!,:fe_orig] .- cst_endo_odyfe[!,:fe_dest]
constant_endo_odyfe = mean(cst_endo_odyfe[!,:constant])

cst_ratio_endo_yfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re3))
cst_ratio_endo_yfe[!,:constant] = cst_ratio_endo_yfe[!,:flow_AzoseRaftery] .- beta_endo_ratio[1,:b3] .* cst_ratio_endo_yfe[!,:density_ratio] .- beta_endo_ratio[1,:b6] .* cst_ratio_endo_yfe[!,:ypc_ratio] .- beta_endo_ratio[1,:b7] .* cst_ratio_endo_yfe[!,:distance] .- beta_endo_ratio[1,:b8] .* cst_ratio_endo_yfe[!,:exp_residual] .- beta_endo_ratio[1,:b9] .* cst_ratio_endo_yfe[!,:remcost] .- beta_endo_ratio[1,:b10] .* cst_ratio_endo_yfe[!,:comofflang]
constant_ratio_endo_yfe = mean(cst_ratio_endo_yfe[!,:constant])

cst_ratio_endo_odyfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re4))
cst_ratio_endo_odyfe[!,:constant] = cst_ratio_endo_odyfe[!,:flow_AzoseRaftery] .- beta_endo_ratio[2,:b3] .* cst_ratio_endo_odyfe[!,:density_ratio] .- beta_endo_ratio[2,:b6] .* cst_ratio_endo_odyfe[!,:ypc_ratio] .- beta_endo_ratio[2,:b7] .* cst_ratio_endo_odyfe[!,:distance] .- beta_endo_ratio[2,:b8] .* cst_ratio_endo_odyfe[!,:exp_residual] .- beta_endo_ratio[2,:b9] .* cst_ratio_endo_odyfe[!,:remcost] .- beta_endo_ratio[2,:b10] .* cst_ratio_endo_odyfe[!,:comofflang] .- cst_ratio_endo_odyfe[!,:fe_orig] .- cst_ratio_endo_odyfe[!,:fe_dest]
constant_ratio_endo_odyfe = mean(cst_ratio_endo_odyfe[!,:constant])

cst_endo_abel_yfe = hcat(gravity_endo_abel[:,Not([:orig,:dest,:year])], fe(re5))
cst_endo_abel_yfe[!,:constant] = cst_endo_abel_yfe[!,:flow_Abel] .- beta_endo[3,:b1] .* cst_endo_abel_yfe[!,:pop_orig] .- beta_endo[3,:b2] .* cst_endo_abel_yfe[!,:pop_dest] .- beta_endo[3,:b4] .* cst_endo_abel_yfe[!,:ypc_orig] .- beta_endo[3,:b5] .* cst_endo_abel_yfe[!,:ypc_dest] .- beta_endo[3,:b7] .* cst_endo_abel_yfe[!,:distance] .- beta_endo[3,:b8] .* cst_endo_abel_yfe[!,:exp_residual] .- beta_endo[3,:b9] .* cst_endo_abel_yfe[!,:remcost] .- beta_endo[3,:b10] .* cst_endo_abel_yfe[!,:comofflang]
constant_endo_abel_yfe = mean(cst_endo_abel_yfe[!,:constant])

cst_endo_abel_odyfe = hcat(gravity_endo_abel[:,Not([:orig,:dest,:year])], fe(re6))
cst_endo_abel_odyfe[!,:constant] = cst_endo_abel_odyfe[!,:flow_Abel] .- beta_endo[4,:b1] .* cst_endo_abel_odyfe[!,:pop_orig] .- beta_endo[4,:b2] .* cst_endo_abel_odyfe[!,:pop_dest] .- beta_endo[4,:b4] .* cst_endo_abel_odyfe[!,:ypc_orig] .- beta_endo[4,:b5] .* cst_endo_abel_odyfe[!,:ypc_dest] .- beta_endo[4,:b7] .* cst_endo_abel_odyfe[!,:distance] .- beta_endo[4,:b8] .* cst_endo_abel_odyfe[!,:exp_residual] .- beta_endo[4,:b9] .* cst_endo_abel_odyfe[!,:remcost] .- beta_endo[4,:b10] .* cst_endo_abel_odyfe[!,:comofflang] .- cst_endo_abel_odyfe[!,:fe_orig] .- cst_endo_abel_odyfe[!,:fe_dest]
constant_endo_abel_odyfe = mean(skipmissing(cst_endo_abel_odyfe[!,:constant]))

beta_endo[!,:b0] = [constant_endo_yfe,constant_endo_odyfe,constant_endo_abel_yfe, constant_endo_abel_odyfe]       # constant
beta_endo_ratio[!,:b0] = [constant_ratio_endo_yfe,constant_ratio_endo_odyfe]       # constant

# Gather FE values
fe_endo_yfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re1))
fe_endo_odyfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re2))
fe_ratio_endo_yfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re3))
fe_ratio_endo_odyfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re4))
fe_endo_abel_yfe = hcat(gravity_endo_abel[:,[:year,:orig,:dest]], fe(re5))
fe_endo_abel_odyfe = hcat(gravity_endo_abel[:,[:year,:orig,:dest]], fe(re6))


CSV.write(joinpath(@__DIR__,"../results/gravity/beta_endo.csv"), beta_endo)
CSV.write(joinpath(@__DIR__,"../results/gravity/beta_endo_ratio.csv"), beta_endo_ratio)

CSV.write(joinpath(@__DIR__,"../results/gravity/fe_endo_yfe.csv"), fe_endo_yfe)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_endo_odyfe.csv"), fe_endo_odyfe)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_ratio_endo_yfe.csv"), fe_ratio_endo_yfe)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_ratio_endo_odyfe.csv"), fe_ratio_endo_odyfe)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_endo_abel_yfe.csv"), fe_endo_abel_yfe)
CSV.write(joinpath(@__DIR__,"../results/gravity/fe_endo_abel_odyfe.csv"), fe_endo_abel_odyfe)

CSV.write(joinpath(@__DIR__,"../results/gravity/gravity_17_update.csv"), gravity_17)
CSV.write(joinpath(@__DIR__,"../results/gravity/gravity_endo_update.csv"), gravity_endo)
CSV.write(joinpath(@__DIR__,"../results/gravity/gravity_endo_abel_update.csv"), gravity_endo_abel)


##################################################### Third specification: remshare endogenous + include regional damages #################################
# Estimate the main gravity equation using residuals from remshare regression and including regional exposure levels
ree1 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + expo_orig + expo_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
ree2 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + expo_orig + expo_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
ree3 = reg(gravity_endo, @formula(mig_ratio_tot ~ density_ratio + ypc_ratio + expo_orig + expo_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
ree4 = reg(gravity_endo, @formula(mig_ratio_tot ~ density_ratio + ypc_ratio + expo_orig + expo_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
ree5 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + expo_orig + expo_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
ree6 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + expo_orig + expo_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(ree1, ree2, ree3, ree4, ree5, ree6; render = LatexTable(),regression_statistics=[:nobs, :r2 ])     
regtable(re1, ree1; render = LatexTable(),regression_statistics=[:nobs, :r2 ])     

beta_endo_expo = DataFrame(
    regtype = ["reg_endo_expo_yfe","reg_endo_expo_odyfe","reg_endo_expo_abel_yfe", "reg_endo_expo_abel_odyfe"],
    b1 = [0.691,0.722,0.610,1.763],       # pop_orig
    b2 = [0.690,-0.748,0.621,-1.247],       # pop_dest
    b4 = [0.431,0.177,0.069,0.258],       # ypc_orig
    b5 = [0.893,-0.004,0.909,-0.174],       # ypc_dest
    b11 = [0.685,1.513,-11.307,10.687],        # expo_orig
    b12 = [13.230,-3.695,21.440,-11.334],        # expo_dest
    b7 = [-1.283,-1.487,-1.079,-1.322],       # distance
    b8 = [0.011,0.010,0.002,0.006],       # exp_residual
    b9 = [-11.069,-12.723,-17.676,-14.749],       # remcost
    b10 = [1.716,1.591,1.587,1.340]     # comofflang
)
beta_endo_expo_ratio = DataFrame(
    regtype = ["reg_ratio_endo_expo_yfe","reg_ratio_endo_expo_odyfe"],
    b3 = [0.061,-0.236],       # density_ratio
    b6 = [0.169,-0.099],       # ypc_ratio
    b11 = [-18.643,3.130],        # expo_orig
    b12 = [-4.081,-1.783],        # expo_dest
    b7 = [-1.198,-1.487],       # distance
    b8 = [0.012,0.010],       # exp_residual
    b9 = [-9.742,-12.716],       # remcost
    b10 = [1.297,1.592]       # comofflang
)

# Compute constant including year fixed effect as average of beta0 + yearFE
cst_endo_expo_yfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re1))
cst_endo_expo_yfe[!,:constant] = cst_endo_expo_yfe[!,:flow_AzoseRaftery] .- beta_endo_expo[1,:b1] .* cst_endo_expo_yfe[!,:pop_orig] .- beta_endo_expo[1,:b2] .* cst_endo_expo_yfe[!,:pop_dest] .- beta_endo_expo[1,:b4] .* cst_endo_expo_yfe[!,:ypc_orig] .- beta_endo_expo[1,:b5] .* cst_endo_expo_yfe[!,:ypc_dest] .- beta_endo_expo[1,:b7] .* cst_endo_expo_yfe[!,:distance] .- beta_endo_expo[1,:b8] .* cst_endo_expo_yfe[!,:exp_residual] .- beta_endo_expo[1,:b9] .* cst_endo_expo_yfe[!,:remcost] .- beta_endo_expo[1,:b10] .* cst_endo_expo_yfe[!,:comofflang]
constant_endo_expo_yfe = mean(cst_endo_expo_yfe[!,:constant])

cst_endo_expo_odyfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re2))
cst_endo_expo_odyfe[!,:constant] = cst_endo_expo_odyfe[!,:flow_AzoseRaftery] .- beta_endo_expo[2,:b1] .* cst_endo_expo_odyfe[!,:pop_orig] .- beta_endo_expo[2,:b2] .* cst_endo_expo_odyfe[!,:pop_dest] .- beta_endo_expo[2,:b4] .* cst_endo_expo_odyfe[!,:ypc_orig] .- beta_endo_expo[2,:b5] .* cst_endo_expo_odyfe[!,:ypc_dest] .- beta_endo_expo[2,:b7] .* cst_endo_expo_odyfe[!,:distance] .- beta_endo_expo[2,:b8] .* cst_endo_expo_odyfe[!,:exp_residual] .- beta_endo_expo[2,:b9] .* cst_endo_expo_odyfe[!,:remcost] .- beta_endo_expo[2,:b10] .* cst_endo_expo_odyfe[!,:comofflang] .- cst_endo_expo_odyfe[!,:fe_orig] .- cst_endo_expo_odyfe[!,:fe_dest]
constant_endo_expo_odyfe = mean(cst_endo_expo_odyfe[!,:constant])

cst_ratio_endo_expo_yfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re3))
cst_ratio_endo_expo_yfe[!,:constant] = cst_ratio_endo_expo_yfe[!,:flow_AzoseRaftery] .- beta_endo_expo_ratio[1,:b3] .* cst_ratio_endo_expo_yfe[!,:density_ratio] .- beta_endo_expo_ratio[1,:b6] .* cst_ratio_endo_expo_yfe[!,:ypc_ratio] .- beta_endo_expo_ratio[1,:b7] .* cst_ratio_endo_expo_yfe[!,:distance] .- beta_endo_expo_ratio[1,:b8] .* cst_ratio_endo_expo_yfe[!,:exp_residual] .- beta_endo_expo_ratio[1,:b9] .* cst_ratio_endo_expo_yfe[!,:remcost] .- beta_endo_expo_ratio[1,:b10] .* cst_ratio_endo_expo_yfe[!,:comofflang]
constant_ratio_endo_expo_yfe = mean(cst_ratio_endo_expo_yfe[!,:constant])

cst_ratio_endo_expo_odyfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(re4))
cst_ratio_endo_expo_odyfe[!,:constant] = cst_ratio_endo_expo_odyfe[!,:flow_AzoseRaftery] .- beta_endo_expo_ratio[2,:b3] .* cst_ratio_endo_expo_odyfe[!,:density_ratio] .- beta_endo_expo_ratio[2,:b6] .* cst_ratio_endo_expo_odyfe[!,:ypc_ratio] .- beta_endo_expo_ratio[2,:b7] .* cst_ratio_endo_expo_odyfe[!,:distance] .- beta_endo_expo_ratio[2,:b8] .* cst_ratio_endo_expo_odyfe[!,:exp_residual] .- beta_endo_expo_ratio[2,:b9] .* cst_ratio_endo_expo_odyfe[!,:remcost] .- beta_endo_expo_ratio[2,:b10] .* cst_ratio_endo_expo_odyfe[!,:comofflang] .- cst_ratio_endo_expo_odyfe[!,:fe_orig] .- cst_ratio_endo_expo_odyfe[!,:fe_dest]
constant_ratio_endo_expo_odyfe = mean(cst_ratio_endo_expo_odyfe[!,:constant])

cst_endo_expo_abel_yfe = hcat(gravity_endo_abel[:,Not([:orig,:dest,:year])], fe(re5))
cst_endo_expo_abel_yfe[!,:constant] = cst_endo_expo_abel_yfe[!,:flow_Abel] .- beta_endo_expo[3,:b1] .* cst_endo_expo_abel_yfe[!,:pop_orig] .- beta_endo_expo[3,:b2] .* cst_endo_expo_abel_yfe[!,:pop_dest] .- beta_endo_expo[3,:b4] .* cst_endo_expo_abel_yfe[!,:ypc_orig] .- beta_endo_expo[3,:b5] .* cst_endo_expo_abel_yfe[!,:ypc_dest] .- beta_endo_expo[3,:b7] .* cst_endo_expo_abel_yfe[!,:distance] .- beta_endo_expo[3,:b8] .* cst_endo_expo_abel_yfe[!,:exp_residual] .- beta_endo_expo[3,:b9] .* cst_endo_expo_abel_yfe[!,:remcost] .- beta_endo_expo[3,:b10] .* cst_endo_expo_abel_yfe[!,:comofflang]
constant_endo_expo_abel_yfe = mean(cst_endo_expo_abel_yfe[!,:constant])

cst_endo_expo_abel_odyfe = hcat(gravity_endo_abel[:,Not([:orig,:dest,:year])], fe(re6))
cst_endo_expo_abel_odyfe[!,:constant] = cst_endo_expo_abel_odyfe[!,:flow_Abel] .- beta_endo_expo[4,:b1] .* cst_endo_expo_abel_odyfe[!,:pop_orig] .- beta_endo_expo[4,:b2] .* cst_endo_expo_abel_odyfe[!,:pop_dest] .- beta_endo_expo[4,:b4] .* cst_endo_expo_abel_odyfe[!,:ypc_orig] .- beta_endo_expo[4,:b5] .* cst_endo_expo_abel_odyfe[!,:ypc_dest] .- beta_endo_expo[4,:b7] .* cst_endo_expo_abel_odyfe[!,:distance] .- beta_endo_expo[4,:b8] .* cst_endo_expo_abel_odyfe[!,:exp_residual] .- beta_endo_expo[4,:b9] .* cst_endo_expo_abel_odyfe[!,:remcost] .- beta_endo_expo[4,:b10] .* cst_endo_expo_abel_odyfe[!,:comofflang] .- cst_endo_expo_abel_odyfe[!,:fe_orig] .- cst_endo_expo_abel_odyfe[!,:fe_dest]
constant_endo_expo_abel_odyfe = mean(skipmissing(cst_endo_expo_abel_odyfe[!,:constant]))

beta_endo_expo[!,:b0] = [constant_endo_expo_yfe,constant_endo_expo_odyfe,constant_endo_expo_abel_yfe, constant_endo_expo_abel_odyfe]       # constant
beta_endo_expo_ratio[!,:b0] = [constant_ratio_endo_expo_yfe,constant_ratio_endo_expo_odyfe]       # constant

# Gather FE values
fe_endo_expo_yfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re1))
fe_endo_expo_odyfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re2))
fe_ratio_endo_expo_yfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re3))
fe_ratio_endo_expo_odyfe = hcat(gravity_endo[:,[:year,:orig,:dest]], fe(re4))
fe_endo_expo_abel_yfe = hcat(gravity_endo_abel[:,[:year,:orig,:dest]], fe(re5))
fe_endo_expo_abel_odyfe = hcat(gravity_endo_abel[:,[:year,:orig,:dest]], fe(re6))


##################################################### Fourth specification: remshare endogenous + include ypc_orig^2 #################################
# Estimate the main gravity equation using residuals from remshare regression and including square of origin income per cap
gravity_endo[!,:ypc_orig_sq2] = map(x->x^2,gravity_endo[:,:ypc_orig])
gravity_endo_abel[!,:ypc_orig_sq2] = map(x->x^2,gravity_endo_abel[:,:ypc_orig])

res1 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_orig_sq2 + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
res2 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_orig_sq2 + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
res3 = reg(gravity_endo, @formula(mig_ratio_tot ~ density_ratio + ypc_ratio + ypc_orig_sq2 + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
res4 = reg(gravity_endo, @formula(mig_ratio_tot ~ density_ratio + ypc_ratio + ypc_orig_sq2 + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
res5 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_orig_sq2 + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
res6 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_orig_sq2 + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(res1, res2, res3, res4, res5, res6; render = LatexTable(),regression_statistics=[:nobs, :r2 ])   
regtable(re1, res1; render = LatexTable(),regression_statistics=[:nobs, :r2 ])   


##################################################### Fifth specification: remshare endogenous + constrain ypc_ratio #################################
# Estimate the main gravity equation using residuals from remshare regression and constraining coeffs on ypc_orig and ypc_dest to be the same with opposite signs
rer1 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rer2 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rer5 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rer6 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(re1, re2, re5, re6, rer1, rer2, rer5, rer6; render = LatexTable(),regression_statistics=[:nobs, :r2 ]) 
regtable(re1, rer1; render = LatexTable(),regression_statistics=[:nobs, :r2 ]) 

beta_constr = DataFrame(
    regtype = ["reg_constr_yfe","reg_constr_odyfe","reg_constr_abel_yfe", "reg_constr_abel_odyfe"],
    b1 = [0.591,0.678,0.538,1.671],       # pop_orig
    b2 = [0.598,-0.746,0.584,-1.224],       # pop_dest
    b6 = [0.174,-0.078,0.310,-0.164],       # ypc_ratio
    b7 = [-1.203,-1.487,-1.027,-1.322],       # distance
    b8 = [0.016,0.010,0.007,0.006],       # exp_residual
    b9 = [-16.264,-12.727,-21.341,-14.769],       # remcost
    b10 = [1.281,1.591,1.294,1.340]     # comofflang
)

# Compute constant including year fixed effect as average of beta0 + yearFE
cst_constr_yfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(rer1))
cst_constr_yfe[!,:constant] = cst_constr_yfe[!,:flow_AzoseRaftery] .- beta_constr[1,:b1] .* cst_constr_yfe[!,:pop_orig] .- beta_constr[1,:b2] .* cst_constr_yfe[!,:pop_dest] .- beta_constr[1,:b6] .* cst_constr_yfe[!,:ypc_ratio] .- beta_constr[1,:b7] .* cst_constr_yfe[!,:distance] .- beta_constr[1,:b8] .* cst_constr_yfe[!,:exp_residual] .- beta_constr[1,:b9] .* cst_constr_yfe[!,:remcost] .- beta_constr[1,:b10] .* cst_constr_yfe[!,:comofflang]
constant_constr_yfe = mean(cst_constr_yfe[!,:constant])

cst_constr_odyfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(rer2))
cst_constr_odyfe[!,:constant] = cst_constr_odyfe[!,:flow_AzoseRaftery] .- beta_constr[2,:b1] .* cst_constr_odyfe[!,:pop_orig] .- beta_constr[2,:b2] .* cst_constr_odyfe[!,:pop_dest] .- beta_constr[2,:b6] .* cst_constr_odyfe[!,:ypc_ratio] .- beta_constr[2,:b7] .* cst_constr_odyfe[!,:distance] .- beta_constr[2,:b8] .* cst_constr_odyfe[!,:exp_residual] .- beta_constr[2,:b9] .* cst_constr_odyfe[!,:remcost] .- beta_constr[2,:b10] .* cst_constr_odyfe[!,:comofflang] .- cst_constr_odyfe[!,:fe_orig] .- cst_constr_odyfe[!,:fe_dest]
constant_constr_odyfe = mean(cst_constr_odyfe[!,:constant])

cst_constr_abel_yfe = hcat(gravity_endo_abel[:,Not([:orig,:dest,:year])], fe(rer5))
cst_constr_abel_yfe[!,:constant] = cst_constr_abel_yfe[!,:flow_Abel] .- beta_constr[3,:b1] .* cst_constr_abel_yfe[!,:pop_orig] .- beta_constr[3,:b2] .* cst_constr_abel_yfe[!,:pop_dest] .- beta_constr[3,:b6] .* cst_constr_abel_yfe[!,:ypc_ratio] .- beta_constr[3,:b7] .* cst_constr_abel_yfe[!,:distance] .- beta_constr[3,:b8] .* cst_constr_abel_yfe[!,:exp_residual] .- beta_constr[3,:b9] .* cst_constr_abel_yfe[!,:remcost] .- beta_constr[3,:b10] .* cst_constr_abel_yfe[!,:comofflang]
constant_constr_abel_yfe = mean(cst_constr_abel_yfe[!,:constant])

cst_constr_abel_odyfe = hcat(gravity_endo_abel[:,Not([:orig,:dest,:year])], fe(rer6))
cst_constr_abel_odyfe[!,:constant] = cst_constr_abel_odyfe[!,:flow_Abel] .- beta_constr[4,:b1] .* cst_constr_abel_odyfe[!,:pop_orig] .- beta_constr[4,:b2] .* cst_constr_abel_odyfe[!,:pop_dest] .- beta_constr[4,:b6] .* cst_constr_abel_odyfe[!,:ypc_ratio] .- beta_constr[4,:b7] .* cst_constr_abel_odyfe[!,:distance] .- beta_constr[4,:b8] .* cst_constr_abel_odyfe[!,:exp_residual] .- beta_constr[4,:b9] .* cst_constr_abel_odyfe[!,:remcost] .- beta_constr[4,:b10] .* cst_constr_abel_odyfe[!,:comofflang] .- cst_constr_abel_odyfe[!,:fe_orig] .- cst_constr_abel_odyfe[!,:fe_dest]
constant_constr_abel_odyfe = mean(skipmissing(cst_constr_abel_odyfe[!,:constant]))

beta_constr[!,:b0] = [constant_constr_yfe,constant_constr_odyfe,constant_constr_abel_yfe, constant_constr_abel_odyfe]       # constant


##################################################### Sixth specification: specs 2 and 5 separately on poor and on non-poor countries #################################
# Cut-off for low-income + lower-middle-income countries: GNI per cap < $3995 in 2018 (https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups)
# We use as cut-off: ypc in 2010 = $4000
countp = unique(data_ar[.&(data_ar[:,:year0].==2010, map(x->!ismissing(x),data_ar[:,:ypc_orig]), data_ar[:,:ypc_orig].<4000),:orig])
countnp = unique(data_ar[.&(data_ar[:,:year0].==2010, map(x->!ismissing(x),data_ar[:,:ypc_orig]), data_ar[:,:ypc_orig].>=4000),:orig])

# Estimate the main gravity equation using residuals from remshare regression
renp1 = reg(gravity_endo[.&(map(x->in(x, countnp),gravity_endo[:,:orig])),:], @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
renp2 = reg(gravity_endo[.&(map(x->in(x, countnp),gravity_endo[:,:orig])),:], @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
renp5 = reg(gravity_endo_abel[.&(map(x->in(x, countnp),gravity_endo_abel[:,:orig])),:], @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
renp6 = reg(gravity_endo_abel[.&(map(x->in(x, countnp),gravity_endo_abel[:,:orig])),:], @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rep1 = reg(gravity_endo[.&(map(x->in(x, countp),gravity_endo[:,:orig])),:], @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rep2 = reg(gravity_endo[.&(map(x->in(x, countp),gravity_endo[:,:orig])),:], @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rep5 = reg(gravity_endo_abel[.&(map(x->in(x, countp),gravity_endo_abel[:,:orig])),:], @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rep6 = reg(gravity_endo_abel[.&(map(x->in(x, countp),gravity_endo_abel[:,:orig])),:], @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(re1, re2, re5, re6, renp1, renp2, renp5, renp6; render = LatexTable(),regression_statistics=[:nobs, :r2 ])
regtable(re1, renp1, rep1; render = LatexTable(),regression_statistics=[:nobs, :r2 ])

# Estimate the main gravity equation using residuals from remshare regression and constraining coeffs on ypc_orig and ypc_dest to be the same with opposite signs
renpr1 = reg(gravity_endo[.&(map(x->in(x, countnp),gravity_endo[:,:orig])),:], @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
renpr2 = reg(gravity_endo[.&(map(x->in(x, countnp),gravity_endo[:,:orig])),:], @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
renpr5 = reg(gravity_endo_abel[.&(map(x->in(x, countnp),gravity_endo_abel[:,:orig])),:], @formula(flow_Abel ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
renpr6 = reg(gravity_endo_abel[.&(map(x->in(x, countnp),gravity_endo_abel[:,:orig])),:], @formula(flow_Abel ~ pop_orig + pop_dest + ypc_ratio + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(rer1, rer2, rer5, rer6, renpr1, renpr2, renpr5, renpr6; render = LatexTable(),regression_statistics=[:nobs, :r2 ])


##################################################### Seventh specification: use continent-level fixed effects #################################
gravity_endo = innerjoin(gravity_endo, rename(iso3c_fundregion, :iso3c => :orig, :fundregion => :originregion), on = :orig)
gravity_endo = innerjoin(gravity_endo, rename(iso3c_fundregion, :iso3c => :dest, :fundregion => :destinationregion), on = :dest)
gravity_endo_abel = innerjoin(gravity_endo_abel, rename(iso3c_fundregion, :iso3c => :orig, :fundregion => :originregion), on = :orig)
gravity_endo_abel = innerjoin(gravity_endo_abel, rename(iso3c_fundregion, :iso3c => :dest, :fundregion => :destinationregion), on = :dest)

rec2 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(originregion) + fe(destinationregion) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rec6 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + distance + exp_residual + remcost + comofflang + fe(originregion) + fe(destinationregion) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(re1, re2, rec2, re5, re6, rec6; render = LatexTable(),regression_statistics=[:nobs, :r2 ])     
regtable(re1, re2, rec2; render = LatexTable(),regression_statistics=[:nobs, :r2 ])     


##################################################### Eighth specification: include income levels in other countries #################################
reo1 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_other + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
reo2 = reg(gravity_endo, @formula(flow_AzoseRaftery ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_other + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)
reo5 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_other + distance + exp_residual + remcost + comofflang + fe(year)), Vcov.cluster(:orig, :dest), save=true)
reo6 = reg(gravity_endo_abel, @formula(flow_Abel ~ pop_orig + pop_dest + ypc_orig + ypc_dest + ypc_other + distance + exp_residual + remcost + comofflang + fe(orig) + fe(dest) + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(re1, reo1, re2, reo2, re5, reo5, re6, reo6; render = LatexTable(),regression_statistics=[:nobs, :r2 ])     

rco = reg(gravity_endo, @formula(ypc_other ~ ypc_orig + ypc_dest + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rcoo = reg(gravity_endo, @formula(ypc_other ~ ypc_orig + fe(year)), Vcov.cluster(:orig, :dest), save=true)
rcod = reg(gravity_endo, @formula(ypc_other ~ ypc_dest + fe(year)), Vcov.cluster(:orig, :dest), save=true)

regtable(rco, rcoo, rcod; render = AsciiTable(),regression_statistics=[:nobs, :r2 ])     

beta_other = DataFrame(
    regtype = ["reg_other_yfe"],
    b1 = [0.691],       # pop_orig
    b2 = [0.686],       # pop_dest
    b4 = [0.364],       # ypc_orig
    b5 = [0.773],       # ypc_dest
    b6 = [-6.928],       # ypc_other
    b7 = [-1.303],       # distance
    b8 = [0.013],       # exp_residual
    b9 = [-8.724],       # remcost
    b10 = [1.689]     # comofflang
)

# Compute constant including year fixed effect as average of beta0 + yearFE
cst_other_yfe = hcat(gravity_endo[:,Not([:orig,:dest,:year])], fe(reo1))
cst_other_yfe[!,:constant] = cst_other_yfe[!,:flow_AzoseRaftery] .- beta_other[1,:b1] .* cst_other_yfe[!,:pop_orig] .- beta_other[1,:b2] .* cst_other_yfe[!,:pop_dest] .- beta_other[1,:b4] .* cst_other_yfe[!,:ypc_orig] .- beta_other[1,:b5] .* cst_other_yfe[!,:ypc_dest] .- beta_other[1,:b6] .* cst_other_yfe[!,:ypc_other] .- beta_other[1,:b7] .* cst_other_yfe[!,:distance] .- beta_other[1,:b8] .* cst_other_yfe[!,:exp_residual] .- beta_other[1,:b9] .* cst_other_yfe[!,:remcost] .- beta_other[1,:b10] .* cst_other_yfe[!,:comofflang]
constant_other_yfe = mean(cst_other_yfe[!,:constant])

beta_other[!,:b0] = [constant_other_yfe]       # constant

