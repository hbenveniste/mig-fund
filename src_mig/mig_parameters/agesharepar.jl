using CSV, DataFrames, Query, DelimitedFiles


regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
isonum_fundregion = CSV.File(joinpath(@__DIR__,"../../input_data/isonum_fundregion.csv")) |> DataFrame
edu = ["e1","e2","e3","e4","e5","e6"]


################## Prepare population data: original SSP ####################
ssp1 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP1.csv") |> DataFrame
ssp2 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP2.csv") |> DataFrame
ssp3 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP3.csv") |> DataFrame
ssp4 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP4.csv") |> DataFrame
ssp5 = CSV.File("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP5.csv") |> DataFrame

select!(ssp1, Not(:Column1))
select!(ssp2, Not(:Column1))
select!(ssp3, Not(:Column1))
select!(ssp4, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))
select!(ssp5, Not([:Column1, :pattern, :nSx, :pop1, :deaths, :pop2, :pop3, :asfr, Symbol("pop3.shift"), :births, Symbol("deaths.nb"), :pop4, :area]))

ssp4[!,:scen] = repeat(["SSP4"], size(ssp4,1))
ssp5[!,:scen] = repeat(["SSP5"], size(ssp5,1))

select!(ssp4, [2,1,3,4,5,6,7,8,9])
select!(ssp5, [2,1,3,4,5,6,7,8,9])

# Join ssp datasets
ssp = vcat(ssp1, ssp2, ssp3, ssp4, ssp5)

# Replace missing values by zeros
for name in [:inmig, :outmig]
    for i in 1:length(ssp[!,name])
        if ssp[!,name][i] == "NA" 
            ssp[!,name][i] = "0"
        end
    end
    ssp[!,name] = map(x -> parse(Float64, x), ssp[!,name])
end


####################### Update SSP population scenarios #################################################
# Source:  K.C., S., Lutz, W. , Potančoková, M. , Abel, G. , Barakat, B., Eder, J., Goujon, A. , Jurasszovich, S., et al. (2020). 
# Global population and human capital projections for Shared Socioeconomic Pathways – 2015 to 2100, Revision-2018. 
# https://pure.iiasa.ac.at/id/eprint/17550/
ssp1_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP1_2018update.csv", DataFrame)
ssp2_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP2_2018update.csv", DataFrame)
ssp3_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP3_2018update.csv", DataFrame)
ssp4_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP4_2018update.csv", DataFrame)
ssp5_update = CSV.read("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/YSSP-IIASA/Samir_data/SSP5_2018update.csv", DataFrame)

ssp1_update.scen = repeat(["SSP1"], size(ssp1_update,1))
ssp2_update.scen = repeat(["SSP2"], size(ssp2_update,1))
ssp3_update.scen = repeat(["SSP3"], size(ssp3_update,1))
ssp4_update.scen = repeat(["SSP4"], size(ssp4_update,1))
ssp5_update.scen = repeat(["SSP5"], size(ssp5_update,1))

ssp_update = vcat(ssp1_update, ssp2_update, ssp3_update, ssp4_update, ssp5_update)

# Full update: use population sizes and demographic distribution of updated scenarios
# Convert 21 age groups to 25 age groups: assume no population over 105 yers old
ssp_update.ageno_22 = zeros(size(ssp_update,1))
ssp_update.ageno_23 = zeros(size(ssp_update,1))
ssp_update.ageno_24 = zeros(size(ssp_update,1))
ssp_update.ageno_25 = zeros(size(ssp_update,1))

ssp_update = stack(
    ssp_update[!,Not([:ageno_0])],
    [:ageno_1,:ageno_2,:ageno_3,:ageno_4,:ageno_5,:ageno_6,:ageno_7,:ageno_8,:ageno_9,:ageno_10,:ageno_11,:ageno_12,:ageno_13,:ageno_14,:ageno_15,:ageno_16,:ageno_17,:ageno_18,:ageno_19,:ageno_20,:ageno_21,:ageno_22,:ageno_23,:ageno_24,:ageno_25]
)
ssp_update.age = (map(x->parse(Int,SubString(x,7)), ssp_update.variable) .- 1 ) .* 5
rename!(ssp_update, :value => :pop_update)

# Keep only population numbers for each age group, each sex and disaggregated education levels, and distinct countries (isono < 900)
filter!(
    row -> (row.sexno != 0 && row.eduno !=0 && row.isono < 900),
    ssp_update
)
ssp_update.sex = [(ssp_update[i,:sexno] == 1 ? "male" : "female") for i in eachindex(ssp_update[:,1])]
select!(ssp_update, [:scen,:year,:isono,:eduno,:age,:sex,:pop_update])

# Convert 10 education levels (Under 15, No Education, Incomplete Primary, Primary, Lower Secondary, Upper Secondary, Post Secondary, Short Post Secondary, Bachelor, Master and higher)
# to 6 education levels (no education, some primary, primary completed, lower secondary completed, upper secondary completed, post secondary completed)
ssp_update[!,:edu_6] = [(ssp_update[i,:eduno] == 1 || ssp_update[i,:eduno] == 2) ? "e1" : (ssp_update[i,:eduno] == 3 ? "e2" : (ssp_update[i,:eduno] == 4 ? "e3" : (ssp_update[i,:eduno] == 5 ? "e4" : (ssp_update[i,:eduno] == 6 ? "e5" : "e6")))) for i in eachindex(ssp_update[:,1])]

ssp.region = map(x -> parse(Int, SubString(x, 3)), ssp.region)

ssp = leftjoin(
    ssp,
    rename(
        combine(
            groupby(
                ssp_update, 
                [:year,:isono,:scen,:edu_6,:age,:sex]
            ), 
            :pop_update => sum
        ),
        :year => :period, :isono => :region, :edu_6 => :edu, :pop_update_sum => :pop_update
    ),
    on = [:scen, :period, :region, :edu, :age, :sex]
)


# We assume that for each country, SSP scenario, and demographic group, the ratios inmig/pop and outmig/pop remain the same for the update
ssp.inmig_update = ssp.inmig .* ssp.pop_update ./ ssp.pop
ssp.outmig_update = ssp.outmig .* ssp.pop_update ./ ssp.pop
replace!(ssp.inmig_update, NaN => 0.0)
replace!(ssp.outmig_update, NaN => 0.0)

# We then rescale inmig_update to make sure that for each SSP scenario, time period, and demographic group, the sum over countries of outmig_update = the sum over countries of outmig_update
ssp = innerjoin(
    ssp,
    combine(
        groupby(
            ssp,
            [:scen, :period, :sex, :age, :edu]
        ),
        :inmig_update => sum, :outmig_update => sum
    ),
    on = [:scen, :period, :sex, :age, :edu]
)
ssp.inmig_update = ssp.inmig_update .* ssp.outmig_update_sum ./ ssp.inmig_update_sum
replace!(ssp.inmig_update, NaN => 0.0)

# Keep only updated versions and rename them 
select!(ssp, Not([:pop,:outmig,:inmig,:inmig_update_sum,:outmig_update_sum]))
rename!(ssp, :pop_update => :pop, :inmig_update => :inmig, :outmig_update => :outmig)

CSV.write("C:/Users/hmrb/Stanford_Benveniste Dropbox/Hélène Benveniste/migration-exposure-immobility/results_large/ssp_update.csv", ssp)



#################################################### Computing age of migrants at time of migration ###################################################
# Sum projections for all sexes and educations: population + inmigration per scenario, country, time period, and age
agegroup_c = combine(groupby(ssp, [:age, :region, :period, :scen]), d -> (inmig = sum(d.inmig), pop = sum(d.pop)))

# The Channels Islands do not have a proper ISO code, instead Jersey (832, JEY) and Guernsey (831, GGY) do. 
# Based on census data for 2011, we attribute 60% of the Channels population to Jersey and the rest to Guernsey.
channelsind = findall(agegroup_c[!,:region] .== 830)
for i in channelsind
    push!(agegroup_c, [agegroup_c[!,:age][i], 831, agegroup_c[!,:period][i], agegroup_c[!,:scen][i], agegroup_c[!,:inmig][i]*0.4, agegroup_c[!,:pop][i]*0.4])
    push!(agegroup_c, [agegroup_c[!,:age][i], 832, agegroup_c[!,:period][i], agegroup_c[!,:scen][i], agegroup_c[!,:inmig][i]*0.6, agegroup_c[!,:pop][i]*0.6])
end
deleteat!(agegroup_c, channelsind)

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

# When testing, we find that every region, for every time period and every scenario, has basically the same age distribution for migrants
# Thus we simplify and provide the agegroup parameter for the USA for SSP2 in 2015 as constant for all regions, time periods and scenarios
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