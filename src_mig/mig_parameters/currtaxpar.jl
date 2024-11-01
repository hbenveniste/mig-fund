using CSV, DataFrames, Statistics, Query, DelimitedFiles, FileIO, ExcelFiles, XLSX, VegaLite


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]     # We use ["SSP1-RCP1.9","SSP2-RCP4.5","SSP3-RCP7.0","SSP4-RCP6.0","SSP5-RCP8.5"]

# Determine carbon price at FUND region level using SSP scenarios
# The carbon price is the same for all regions

# Reading data from SSP database (IIASA). Units: US$2005/t CO2
cpdata = XLSX.readdata(joinpath(@__DIR__, "../../input_data/Carbonprice_SSPdatabase.xlsx"), "data!A1:P21")
cpdata = DataFrame(cpdata, :auto)
rename!(cpdata, Symbol.(Vector(cpdata[1,:])))
deleteat!(cpdata,1)
select!(cpdata, Not(union(1,4:6)))
rename!(cpdata, :Region => :sspregion, :Scenario => :scen)
cpdata[!,:scen] = map(x->SubString(x,1:4),cpdata[:,:scen])
cpdata[!,:sspregion] = map(x->SubString(x,5),cpdata[:,:sspregion])

# Adding data for SSP3 - RCP7.0: carbon price = 0.0
sspregions = ["ASIA","LAM","MAF","OECD","REF"]
for r in sspregions
    push!(cpdata,["SSP3",r,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0])
end

# Matching regions between SSP (5 regions) and FUND
regions_ssp = DataFrame(
    region = regions,
    sspregion = ["OECD","OECD","OECD","OECD","OECD","OECD","REF","MAF","LAM","LAM","ASIA","ASIA","ASIA","MAF","MAF","LAM"]
)
cpdata = innerjoin(cpdata, regions_ssp, on = :sspregion)

# Stack data
cpdata_s = stack(cpdata,3:12)
rename!(cpdata_s, :variable=>:year, :value=>:cprice)
cpdata_s[!,:year] = map(x->parse(Int,String(x)), cpdata_s[:,:year])

# Linearizing from 10-year periods to yearly values. Note: a value for year x actually represents Carbon price at the beginning of the period                                                
cp_allyr = DataFrame(
    year = repeat(2010:2100, outer = length(ssps)*length(regions)),
    scen = repeat(ssps, inner = length(2010:2100)*length(regions)),
    region = repeat(regions, inner = length(2010:2100), outer = length(ssps))
)
cp = outerjoin(cpdata_s[:,Not(:sspregion)], cp_allyr, on = [:year, :scen, :region])
sort!(cp, [:scen, :region, :year])
for i in eachindex(cp[:,1])
    if mod(cp[i,:year], 10) != 0
        ind = i - mod(cp[i,:year], 10)
        floor = cp[ind,:cprice] ; ceiling = cp[ind+10,:cprice]
        a = floor + (ceiling - floor) / 10 * mod(cp[i,:year], 10)
        cp[i, :cprice] = a
    end
end

# Adding data for 1950-2010 and 2100-3000 (zero prices)
cp_scen = vcat(
    cp, 
    DataFrame(
        year=repeat(1950:2009,outer = length(ssps)*length(regions)),
        cprice = zeros(length(ssps)*length(regions)*length(1950:2009)),
        scen = repeat(ssps, inner = length(1950:2009)*length(regions)),
        region = repeat(regions, inner = length(1950:2009), outer = length(ssps))
    )
)
cp_scen = vcat(
    cp_scen, 
    DataFrame(
        year=repeat(2101:3000,outer = length(ssps)*length(regions)),
        cprice = zeros(length(ssps)*length(regions)*length(2101:3000)),
        scen = repeat(ssps, inner = length(2101:3000)*length(regions)),
        region = repeat(regions, inner = length(2101:3000), outer = length(ssps))
    )
)
sort!(cp_scen,[:scen,:year,:region])

# Converting to $/tC: 1 tC = 3.67 tCO2
cp_scen[!,:cprice] .*= 3.67

# Sorting the data
regionsdf = DataFrame(region = regions, index = 1:16)
cp_scen = innerjoin(cp_scen, regionsdf, on = :region)
sort!(cp_scen, [:scen, :year, :index])

# Plot results
cp_scen |> @filter(_.year >= 2010 && _.year <= 2100) |> @vlplot(
    :line, width=300, height=250, 
    x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, 
    y = {"mean(cprice)", title="Carbon price, USD/tC", axis={labelFontSize=16,titleFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Climate scenario", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}}
) |> save(joinpath(@__DIR__, "../results/emissions/", "FigS2.png"))

# Write data for each SSP separately
for s in ssps
    CSV.write(joinpath(@__DIR__, string("../scen/cp_", s, ".csv")), cp_scen[(cp_scen[:,:scen].==s),[:year, :region, :cprice]]; writeheader=false)
end