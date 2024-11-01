using CSV, DataFrames, DelimitedFiles, FileIO, XLSX
using Distances


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]


# Calculating population weights based on country level population data in 2015 from the UN World Population Prospects 2019
pop_allvariants = CSV.read(joinpath(@__DIR__, "../../input_data/WPP2019.csv"), DataFrame)
# We use the Medium variant, the most commonly used. Unit: thousands
pop2015 = @from i in pop_allvariants begin
    @where i.Variant == "Medium" && i.Time == 2015
    @select {i.LocID, i.Location, i.PopTotal}
    @collect DataFrame
end

# The Channels Islands do not have a proper ISO code, instead Jersey (832) and Guernsey (831) do. 
# Based on census data for 2011, we attribute 60% of the Channels population to Jersey and the rest to Guernsey.
channelsind = findfirst(pop2015[!,:LocID] .== 830)
pop2015 = push!(pop2015, [831, "Guernsey", pop2015[channelsind,:PopTotal]*0.4])
pop2015 = push!(pop2015, [832, "Jersey", pop2015[channelsind,:PopTotal]*0.6])
pop2015 = pop2015[[1:(channelsind-1); (channelsind+1:end)],:]
rename!(pop2015, :LocID => :isonum, :Location => :country, :PopTotal => :pop)

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../../input_data/isonum_fundregion.csv"), DataFrame)
pop2015weight = innerjoin(pop2015, isonum_fundregion, on = :isonum)
weight = combine(groupby(pop2015weight, :fundregion), df -> sum(df[!,:pop]))
pop2015weight[!,:weight] = [pop2015weight[i,:pop] / weight[!,:x1][findfirst(weight[!,:fundregion] .== pop2015weight[i,:fundregion])] for i in eachindex(pop2015weight[:,1])]


# Calculating distances between regions as distances between centers of population of regions
# Centers of population of regions are computed as the aryhtmetic means of coordinates of a region's countries' capitals weighted by 2010 country-level population
# Distances between two centers of population are computed as great-circle distances based on the haversine formula from the Distances package (e.g. used in NASA's distance calculator (https://www.nhc.noaa.gov/gccalc.shtml))
# Distances are expressed in km

# Use UN POP data on countries's capitals coordinates
loc = load(joinpath(@__DIR__, "../../input_data/WUP2014-F13-Capital_Cities.xls"), "DATA!A17:J257") |> DataFrame
# choose one capital per country (needed for 7 countries)
inddupl = []
for c in ["Yamoussoukro", "Pretoria", "Bloemfontein", "Porto-Novo", "Sucre", "Sri Jayewardenepura Kotte", "s-Gravenhage (The Hague)"]
    ind = findfirst(x -> x == c, loc[!,Symbol("Capital City")])
    append!(inddupl, ind)
end
sort!(inddupl)
deleteat!(loc, inddupl)
# change ISO code for Guernsey from 830 to 831 and for Jersey from 830 to 832
ind831 = findfirst(loc[!,Symbol("Capital City")] .== "St. Peter Port")
loc[ind831, Symbol("Country code")] = 831
ind832 = findfirst(loc[!,Symbol("Capital City")] .== "St. Helier")
loc[ind832, Symbol("Country code")] = 832

select!(loc, Not([:Index, Symbol("Capital City"), :Note, Symbol("Capital Type"), Symbol("City code"), Symbol("Population (thousands)")]))
loc[!,Symbol("Country code")] = map( x -> trunc(Int, x), loc[!,Symbol("Country code")])
rename!(loc, Symbol("Country code") => :country_code, Symbol("Country or area") => :country)
# add Taiwan
push!(loc, ["Taiwan", 158, 25.0330, 121.5654])

rename!(pop2015weight, :isonum => :country_code)
loc = innerjoin(loc, pop2015weight[:,[:country_code, :fundregion, :weight]], on = :country_code)
coordinates = combine(groupby(loc, :fundregion), d -> (lat = sum(d.Latitude .* d.weight), lon = sum(d.Longitude .* d.weight)))

# Read earth radius data
earthradius = readdlm(joinpath(@__DIR__,"../../input_data/earth_radius.csv"), skipstart = 1, comments = true)         # in km

# Prepare distance DataFrame
dist = DataFrame(
    origin = repeat(coordinates[!,:fundregion], inner = length(regions)), 
    lat_or = repeat(coordinates[!,:lat], inner = length(regions)), 
    lon_or = repeat(coordinates[!,:lon], inner = length(regions)), 
    destination = repeat(coordinates[!,:fundregion], outer = length(regions)), 
    lat_dest = repeat(coordinates[!,:lat], outer = length(regions)), 
    lon_dest = repeat(coordinates[!,:lon], outer = length(regions))
)
dist[!,:loc_or] = [tuple(dist[!,:lat_or][i], dist[!,:lon_or][i]) for i in eachindex(dist[:,1])]
dist[!,:loc_dest] = [tuple(dist[!,:lat_dest][i], dist[!,:lon_dest][i]) for i in eachindex(dist[:,1])]

# Compute distances with Haversine formula
dist[!,:distance] = [haversine(dist[!,:loc_or][i], dist[!,:loc_dest][i], earthradius[1]) for i in eachindex(dist[:,1])]

# Sort data
regionsdf = DataFrame(origin = regions, index_or = 1:16)
dist = innerjoin(dist, regionsdf, on = :origin)
rename!(regionsdf, :origin => :destination, :index_or => :index_dest)
dist = innerjoin(dist, regionsdf, on = :destination)
sort!(dist, [:index_or, :index_dest])


CSV.write(joinpath(@__DIR__,"../../data_mig/distance.csv"), dist[:,[:origin, :destination, :distance]]; writeheader=false)     # Distance is expressed in km.
