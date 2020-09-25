using CSV, DataFrames

regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]

emptypar = DataFrame(year = repeat(1950:3000, inner = length(regions)), region = repeat(regions, outer = length(1950:3000)), transfer = zeros(length(regions) * length(1950:3000)))
CSV.write("../../fund/data/transfer.csv", emptypar; header=false)
CSV.write("../../fund/data/otherincomeloss.csv", emptypar; header=false)
CSV.write("../../fund/data/otherconsloss.csv", emptypar; header=false)
