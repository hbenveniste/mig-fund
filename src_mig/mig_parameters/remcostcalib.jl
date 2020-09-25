using CSV, DataFrames, ExcelFiles, Query, Statistics

####################### Calculating the cost of sending remittances, as share of money sent, phi ###########################
# Reading remittances price data by World Bank: Remittance Prices Worldwide (2018)
# We aggregate data at the country * country level for 2017. 
rpw = load(joinpath(@__DIR__, "../data/rem_wb/WB_rpw.xlsx"), "WB_rpw!A1:AO36689") |> DataFrame
select!(rpw, Not(vcat(names(rpw)[1], names(rpw)[4:8], names(rpw)[10:22], names(rpw)[27:29], names(rpw)[34:end])))
# !!! Source is the sending country, i.e. the migrant's destination
rename!(rpw, Symbol("cc1 total cost %") => :cc1, Symbol("cc2 total cost %") => :cc2, :source_code => :destination, :destination_code => :origin)
rpw[!,:period] = map(x -> parse(Int, SubString(x,1:4)), rpw[!,:period])
indnot2017 = findall(rpw[!,:period] .!= 2017)
deleterows!(rpw, indnot2017)

# Drop rows for which costs are negative
rpw[!,:meancost] = [(typeof(rpw[i,:cc1]) == Float64 && rpw[i,:cc1]>=0) ? ((typeof(rpw[i,:cc2]) == Float64 && rpw[i,:cc2]>=0) ? mean([rpw[!,:cc1][i], rpw[!,:cc2][i]]) : max(0,rpw[i,:cc1])) : max(0,rpw[i,:cc2]) for i in 1:size(rpw, 1)]
phi = by(rpw, [:origin, :destination], df -> mean(df[!,:meancost]) ./ 100)        # We average over surveys and firms per corridor.
rename!(phi, :x1 => :phi)
CSV.write("../data/rem_wb/phi.csv", phi)