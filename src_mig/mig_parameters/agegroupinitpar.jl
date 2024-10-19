using CSV, DataFrames, Query, DelimitedFiles, FileIO, XLSX


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]

# Computing the initial stock of migrants, and how it declines over time
# I use bilateral migration stocks from 2017 from the World Bank
# In order to get its age distribution, I assume that it is the average of two age distributions in the destination country: 
# the one of migrants at time of migration in the period 2015-2020 (computed from the SSP2 as "share")
# and the one of the overall destination population in the period 2015-2020 (based on SSP2)

# Reading bilateral migrant stocks from 2017
migstock_matrix = XLSX.readdata(joinpath(@__DIR__, "../../input_data/WB_Bilateral_Estimates_Migrant_Stocks_2017.xlsx"), "Bilateral_Migration_2017!A2:HJ219") 
igstock_matrix = DataFrame(migstock_matrix, :auto)
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
migstock.stock = stock
indmissing = findall([typeof(migstock[i,:stock]) != Int64 for i in eachindex(migstock[:,1])])
for i in indmissing
    migstock[i,:stock] = 0.0
end 

# Converting into country codes
ccode = XLSX.readdata(joinpath(@__DIR__,"../../input_data/GDPpercap2017.xlsx"), "Data!A1:E218") 
ccode = DataFrame(ccode, :auto)
rename!(ccode, Symbol.(Vector(ccode[1,:])))
deleteat!(ccode,1)
select!(ccode, Not([Symbol("Series Code"), Symbol("Series Name"), Symbol("2017 [YR2017]")]))
rename!(ccode, Symbol("Country Name") => :country, Symbol("Country Code") => :country_code)
rename!(ccode, :country => :destination)
indnkorea = findfirst(x -> x == "Korea, Dem. People’s Rep.", ccode[!,:destination])
ccode[!,:destination][indnkorea] = "Korea, Dem. Rep."
migstock = innerjoin(migstock, ccode, on = :destination)
rename!(migstock, :country_code => :dest_code)
rename!(ccode, :destination => :origin)
migstock = innerjoin(migstock, ccode, on = :origin)
rename!(migstock, :country_code => :orig_code)
select!(migstock, Not([:origin, :destination]))

iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv", DataFrame)
rename!(iso3c_fundregion, :iso3c => :orig_code)
migstock = leftjoin(migstock, iso3c_fundregion, on = :orig_code)
rename!(migstock, :fundregion => :origin)
mis3c = Dict("SXM" => "SIS", "MAF" => "SIS", "CHI" => "WEU", "XKX" => "EEU")
for c in ["SXM", "MAF", "CHI", "XKX"] 
    indmissing = findall(migstock[!,:orig_code] .== c)
    for i in indmissing
        migstock[!,:origin][i] = mis3c[c]
    end
end
rename!(iso3c_fundregion, :orig_code => :dest_code)
migstock = leftjoin(migstock, iso3c_fundregion, on = :dest_code)
rename!(migstock, :fundregion => :destination)
for c in ["SXM", "MAF", "CHI", "XKX"] 
    indmissing = findall(migstock[!,:dest_code] .== c)
    for i in indmissing
        migstock[!,:destination][i] = mis3c[c]
    end
end

# Summing for FUND regions
migstock_reg = combine(groupby(migstock, [:origin, :destination]), d -> sum(d.stock))
rename!(migstock_reg, :x1 => :stock)

# Sorting the data
regionsdf = DataFrame(origin = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destination = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
migstock_reg = outerjoin(migstock_reg, regionsdf, on = [:origin, :destination])
sort!(migstock_reg, (:indexo, :indexd))
CSV.write("../data_mig/migstockinit.csv", migstock_reg[:,[:origin, :destination, :stock]]; writeheader=false)


# Getting age distributions
agegroup = CSV.read(joinpath(@__DIR__, "../input_data/agegroup.csv"), DataFrame)
agedist = @from i in agegroup begin
    @where i.period == 2015 && i.scen == "SSP2"
    @select {i.fundregion, i.age, i.pop, migshare = i.share}
    @collect DataFrame
end
popshare = combine(groupby(agedist, :fundregion), d -> sum(d.:pop))
rename!(popshare, :x1 => :pop_sum)
agedist = innerjoin(agedist, popshare, on = :fundregion)
agedist[!,:popshare] = agedist[!,:pop] ./ agedist[!,:pop_sum]
select!(agedist, Not([:pop, :pop_sum]))
agedist[!,:meanshare] = (agedist[!,:popshare] .+ agedist[!,:migshare]) ./ 2

# Join data
rename!(agedist, :fundregion => :destination)
migstock_reg = innerjoin(migstock_reg, agedist, on = :destination)
migstock_reg[!,:stock_by_age] = migstock_reg[!,:stock] .* migstock_reg[!,:meanshare]

# Linearizing age groups from 5-age to agely values. Note: a value for age x actually represents the average over age group [x; x+5].                                                
migstock_all = DataFrame(
    origin = repeat(regions, inner = length(regions)*length(0:120)),
    destination = repeat(regions, inner = length(0:120), outer = length(regions)),
    age = repeat(vcat(repeat(0:5:115, inner=5),[120]), outer = length(regions)*length(regions)), 
    ageall = repeat(0:120, outer = length(regions)*length(regions))
)
migstock_all = outerjoin(migstock_all, migstock_reg[:,[:origin, :destination, :age, :stock_by_age]], on = [:origin, :destination, :age])
migstock_all[:,:stock_by_age] ./= 5

for o in 0:length(regions)-1
    for d in 0:length(regions)-1
        ind0 = o*length(regions)*length(0:120)+d*length(0:120)
        for i in ind0+3:ind0+length(0:120)-3
            if mod(migstock_all[i,:ageall], 5) != 2 
                floor = migstock_all[i,:stock_by_age] ; ceiling = migstock_all[min(i+5,121),:stock_by_age]
                a = floor + (ceiling - floor) / 5 * (mod(migstock_all[i,:ageall], 5) - 2)
                migstock_all[i, :stock_by_age] = a
            end
        end
        val1 = migstock_all[ind0+3,:stock_by_age] * 5
        a1 = (val1 - sum(migstock_all[ind0+3:ind0+5,:stock_by_age])) / 2
        for i in ind0+1:ind0+2 
            migstock_all[i, :stock_by_age] = a1 
        end
        val2 = migstock_all[ind0+length(0:120)-3,:stock_by_age] * 5
        a2 = (val2 - sum(migstock_all[ind0+length(0:120)-3:ind0+length(0:120),:stock_by_age])) / 2
        for i in ind0+length(0:120)-2:ind0+length(0:120) 
            migstock_all[i, :stock_by_age] = a2 
        end
    end
end

CSV.write("../data_mig_3d/agegroupinit.csv", migstock_all[:,[:origin, :destination, :ageall,:stock_by_age]]; writeheader=false)