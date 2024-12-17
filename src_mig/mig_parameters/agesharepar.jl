using CSV, DataFrames, Query, DelimitedFiles


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
isonum_fundregion = CSV.File(joinpath(@__DIR__,"../../input_data/isonum_fundregion.csv")) |> DataFrame
edu = ["e1","e2","e3","e4","e5","e6"]


################## Prepare population data: original SSP ####################
# Original version:
# Source:  Wittgenstein Center (WIC) Population and Human Capital Projections, version v.1.3 (February 2024). 
# https://zenodo.org/records/10618931
ssp1 = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP1_V13_2024update.csv", DataFrame)
ssp2 = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP2_V13_2024update.csv", DataFrame)
ssp3 = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP3_V13_2024update.csv", DataFrame)
ssp4 = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP4_V13_2024update.csv", DataFrame)
ssp5 = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP5_V13_2024update.csv", DataFrame)

ssp1.scen = repeat(["SSP1"], size(ssp1,1))
ssp2.scen = repeat(["SSP2"], size(ssp2,1))
ssp3.scen = repeat(["SSP3"], size(ssp3,1))
ssp4.scen = repeat(["SSP4"], size(ssp4,1))
ssp5.scen = repeat(["SSP5"], size(ssp5,1))

ssp = vcat(ssp1, ssp2, ssp3, ssp4, ssp5)

# Age: attribute newborns (agest = -5) to the 0-4 year old category
ssp.agest = [ssp[i,:agest] == -5 ? 0 : ssp[i,:agest] for i in eachindex(ssp[:,1])]
ssp = rename(
    combine(
        groupby(
            ssp,
            [:scen,:Time,:region,:edu,:agest,:sex]
        ),
        :pop => sum, :emi => sum, :imm => sum
    ),
    :Time => :period, :agest => :age, :pop_sum => :pop, :emi_sum => :outmig, :imm_sum => :inmig
)

# Keep only population numbers for distinct countries (isono < 900)
ssp[!,:region] = map(x -> parse(Int, SubString(x, 4)), ssp[!,:region])
filter!(
    row -> (row.region < 900),
    ssp
)

ssp.sex = [(ssp[i,:sex] == "m" ? "male" : "female") for i in eachindex(ssp[:,1])]


#################################################### Computing age of migrants at time of migration ###################################################
# Sum projections for all sexes and educations: population + inmigration per scenario, country, time period, and age
agegroup_c = combine(groupby(ssp, [:age, :region, :period, :scen]), d -> (inmig = sum(d.inmig), pop = sum(d.pop)))

# Convert to FUND region level: weight by immigrant flows
agegroup_c = innerjoin(agegroup_c, rename(isonum_fundregion, :isonum => :region), on = :region)
agegroup = combine(groupby(agegroup_c, [:scen, :period, :fundregion, :age]), d -> (pop = sum(d.pop), inmig = sum(d.inmig)))

# Computing shares of migrants by age
agegroup = innerjoin(
    agegroup, 
    rename(combine(groupby(agegroup, [:scen, :fundregion, :period]), d -> sum(d.inmig)), :x1 => :inmig_sum),
    on = [:scen, :fundregion, :period]
)
agegroup[!,:share] = agegroup[!,:inmig] ./ agegroup[!,:inmig_sum]
for i in eachindex(agegroup[:,1]) ; if agegroup[!,:inmig][i] == 0 && agegroup[!,:inmig_sum][i] == 0 ; agegroup[!,:share][i] = 0 end end

# Sorting the data
regionsdf = DataFrame(fundregion = regions, index = 1:16)
agegroup = innerjoin(agegroup, regionsdf, on = :fundregion)
sort!(agegroup, [:scen, :period, :index, :age])

# When testing, we find that every region, for every time period and every scenario, has a similar age distribution for migrants
# Thus we simplify and provide the agegroup parameter for the USA for SSP2 in 2020 as constant for all regions, time periods and scenarios
agegroup_simple = DataFrame(age=unique(agegroup[!,:age]), share=agegroup[1:length(unique(agegroup[!,:age])),:share])

# Linearizing age groups from 5-age to agely values. Note: a value for age x actually represents age group at the beginning of the five year period                                                
age_all = DataFrame(age = vcat(repeat(0:5:115, inner=5),[120]), ageall = 0:120)
age_all = innerjoin(age_all, agegroup_simple, on = :age)
age_all[:,:share] ./= 5

for i in 3:size(age_all,1)-3
    if mod(age_all[i,:ageall], 5) != 2 
        floor = age_all[i,:share] ; ceiling = age_all[min(i+5,121),:share]
        a = floor + (ceiling - floor) / 5 * (mod(age_all[i,:ageall], 5) - 2)
        age_all[i, :share] = a
    end
end
val1 = age_all[3,:share] * 5
a1 = (val1 - sum(age_all[3:5,:share])) / 2
for i in 1:2 ; age_all[i, :share] = a1 end
val2 = age_all[118,:share] * 5
a2 = (val2 - sum(age_all[118:120,:share])) / 2
for i in size(age_all,1)-2:size(age_all,1) ; age_all[i, :share] = a2 end


CSV.write(joinpath(@__DIR__,"../../data_mig/ageshare.csv"), age_all[:,[:ageall,:share]]; writeheader=false)
CSV.write(joinpath(@__DIR__, "../../input_data/agegroup.csv"), agegroup)