using CSV, DataFrames, ExcelFiles, Query, DelimitedFiles, Statistics

# Calculating the dummies indicating where two regions have common official languages, psi.

# Reading migrant flows at country * country level; data for Azose and Raftery (2018) as compiled in Abel and Cohen (2019).
migflow_alldata = CSV.read(joinpath(@__DIR__, "../../yssp/data/migflow_all/ac19.csv"))
migflow_ar = migflow_alldata[:,[:year0, :orig, :dest, :da_pb_closed]]       # select Azose-Raftery data

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

for i in 1:size(comol,1) ; if comol[i,:orig] == comol[i,:dest] ; comol[i,:comofflang] = 1 end end
for l in offlang
    for c1 in l[2]
        for c2 in l[2]
            ind = intersect(findall(comol[:,:orig].==c1),findall(comol[:,:dest].==c2))
            comol[ind,:comofflang] = 1
        end
    end
end

# Transposing to FUND region * region level. 
# Dummies will actually be numbers in [0,1] as weighted averages of relevant dummies. We weight corridors by migrant flows.
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
rename!(iso3c_fundregion, :iso3c => :orig, :fundregion => :originregion)
comol = join(comol, iso3c_fundregion, on = :orig)
rename!(iso3c_fundregion, :orig => :dest, :originregion => :destinationregion)
comol = join(comol, iso3c_fundregion, on = :dest)

# Computing weights as % of regional bilateral flow averaged over the five 5-year periods
migflow_ar = join(migflow_ar, iso3c_fundregion, on = :dest)
rename!(iso3c_fundregion, :dest => :orig, :destinationregion => :originregion)
migflow_ar = join(migflow_ar, iso3c_fundregion, on = :orig)

rename!(migflow_ar, :da_pb_closed => :migflow)
migweight_yr = by(migflow_ar, [:year0, :originregion, :destinationregion], d -> sum(d.migflow))
rename!(migweight_yr, :x1 => :migflow_reg)
migflow_ar = join(migflow_ar, migweight_yr, on = [:year0,:originregion,:destinationregion])
migflow_ar[:,:weight_yr] = migflow_ar[:,:migflow] ./ migflow_ar[:,:migflow_reg]
for i in 1:size(migflow_ar,1) ; if migflow_ar[i,:migflow_reg]==0 ; migflow_ar[i,:weight_yr]=0 end end
migweight = by(migflow_ar, [:orig, :dest], d -> mean(d.weight_yr))
rename!(migweight, :x1 => :migweight)

comol = join(comol, migweight, on = [:orig, :dest])
comol[:,:dummyweighted] = comol[:,:comofflang] .* comol[:,:migweight]

comofflang = by(comol, [:originregion, :destinationregion], d -> sum(d.dummyweighted))
rename!(comofflang, :x1 => :weighteddummy)

# Sorting the data
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
comofflang = join(comofflang, regionsdf, on = [:originregion, :destinationregion])
sort!(comofflang, (:indexo, :indexd))

CSV.write(joinpath(@__DIR__,"../data_mig/comofflang.csv"), comofflang[:,[:originregion,:destinationregion,:weighteddummy]]; writeheader=false)