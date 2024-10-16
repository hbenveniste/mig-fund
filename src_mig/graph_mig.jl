using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query

using Mimi, MimiFUND

include("main_mig.jl")


# Run models
m_ssp1_nomig = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nomig = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nomig = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nomig = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nomig = getmigrationmodel(scen="SSP5",migyesno="nomig")

run(m_ssp1_nomig)
run(m_ssp2_nomig)
run(m_ssp3_nomig)
run(m_ssp4_nomig)
run(m_ssp5_nomig)

# Compare migrant flows and population levels in Mig-FUND for different border policy scenarios
param_border = MimiFUND.load_default_parameters(joinpath(@__DIR__,"../data_borderpolicy"))

# Closed borders between regions
m_ssp1_nomig_cb = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nomig_cb = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nomig_cb = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nomig_cb = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nomig_cb = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nomig_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp2_nomig_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp3_nomig_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp4_nomig_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp5_nomig_cb, :policy, param_border[:policy_zero])
run(m_ssp1_nomig_cb)
run(m_ssp2_nomig_cb)
run(m_ssp3_nomig_cb)
run(m_ssp4_nomig_cb)
run(m_ssp5_nomig_cb)

# Increase in migrant flows of 100% compared to current policy
m_ssp1_nomig_ob = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nomig_ob = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nomig_ob = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nomig_ob = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nomig_ob = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nomig_ob, :policy, param_border[:policy_2])
update_param!(m_ssp2_nomig_ob, :policy, param_border[:policy_2])
update_param!(m_ssp3_nomig_ob, :policy, param_border[:policy_2])
update_param!(m_ssp4_nomig_ob, :policy, param_border[:policy_2])
update_param!(m_ssp5_nomig_ob, :policy, param_border[:policy_2])
run(m_ssp1_nomig_ob)
run(m_ssp2_nomig_ob)
run(m_ssp3_nomig_ob)
run(m_ssp4_nomig_ob)
run(m_ssp5_nomig_ob)

# Current policies within Global North and Global South, closed between
m_ssp1_nomig_2w = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nomig_2w = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nomig_2w = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nomig_2w = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nomig_2w = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nomig_2w, :policy, param_border[:policy_half])
update_param!(m_ssp2_nomig_2w, :policy, param_border[:policy_half])
update_param!(m_ssp3_nomig_2w, :policy, param_border[:policy_half])
update_param!(m_ssp4_nomig_2w, :policy, param_border[:policy_half])
update_param!(m_ssp5_nomig_2w, :policy, param_border[:policy_half])
run(m_ssp1_nomig_2w)
run(m_ssp2_nomig_2w)
run(m_ssp3_nomig_2w)
run(m_ssp4_nomig_2w)
run(m_ssp5_nomig_2w)


ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

migration = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
enter_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:enter_currentborders] = enter_currentborders
leave_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:leave_currentborders] = leave_currentborders

enter_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:enter_closedborders] = enter_closedborders
leave_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:leave_closedborders] = leave_closedborders

enter_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:enter_moreopen] = enter_moreopen
leave_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:leave_moreopen] = leave_moreopen

enter_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:enter_bordersnorthsouth] = enter_bordersnorthsouth
leave_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:leave_bordersnorthsouth] = leave_bordersnorthsouth


# Look at net migrant flows for different border policies
migration[!,:netmig_currentborders] = migration[!,:enter_currentborders] .- migration[!,:leave_currentborders]
migration[!,:netmig_overallclosed] = migration[!,:enter_closedborders] .- migration[!,:leave_closedborders]
migration[!,:netmig_bordersmoreopen] = migration[!,:enter_moreopen] .- migration[!,:leave_moreopen]
migration[!,:netmig_northsouthclosed] = migration[!,:enter_bordersnorthsouth] .- migration[!,:leave_bordersnorthsouth]

netmig_all = stack(
    migration, 
    [:netmig_currentborders,:netmig_overallclosed,:netmig_bordersmoreopen,:netmig_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(netmig_all, :variable => :netmig_type, :value => :netmig)
regions_fullname = DataFrame(
    fundregion=regions,
    regionname = [
        "United States (USA)",
        "Canada (CAN)",
        "Western Europe (WEU)",
        "Japan & South Korea (JPK)",
        "Australia & New Zealand (ANZ)",
        "Central & Eastern Europe (EEU)",
        "Former Soviet Union (FSU)",
        "Middle East (MDE)",
        "Central America (CAM)",
        "South America (LAM)",
        "South Asia (SAS)",
        "Southeast Asia (SEA)",
        "China plus (CHI)",
        "North Africa (MAF)",
        "Sub-Saharan Africa (SSA)",
        "Small Island States (SIS)"
    ]
)
netmig_all = innerjoin(netmig_all,regions_fullname, on=:fundregion)

# For SSP2, the below figure is Fig.S3 for the main specification
# Fig.S10 for the estimation with residuals from gravity model based on the last 5-yr period (2010-2015)
# Fig.S14 for runs without remittances
for s in ssps
    netmig_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"netmig_type:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_",s,"_mitig.png")))
end


################################################ Compare to without climate change ##################################
# Run models without climate change
# Current borders
m_ssp1_nocc = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc, :runwithoutdamage, true)
update_param!(m_ssp2_nocc, :runwithoutdamage, true)
update_param!(m_ssp3_nocc, :runwithoutdamage, true)
update_param!(m_ssp4_nocc, :runwithoutdamage, true)
update_param!(m_ssp5_nocc, :runwithoutdamage, true)
run(m_ssp1_nocc)
run(m_ssp2_nocc)
run(m_ssp3_nocc)
run(m_ssp4_nocc)
run(m_ssp5_nocc)

# Closed borders between regions
m_ssp1_nocc_cb = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc_cb = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc_cb = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc_cb = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc_cb = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc_cb, :runwithoutdamage, true)
update_param!(m_ssp2_nocc_cb, :runwithoutdamage, true)
update_param!(m_ssp3_nocc_cb, :runwithoutdamage, true)
update_param!(m_ssp4_nocc_cb, :runwithoutdamage, true)
update_param!(m_ssp5_nocc_cb, :runwithoutdamage, true)
update_param!(m_ssp1_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp2_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp3_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp4_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp5_nocc_cb, :policy, param_border[:policy_zero])
run(m_ssp1_nocc_cb)
run(m_ssp2_nocc_cb)
run(m_ssp3_nocc_cb)
run(m_ssp4_nocc_cb)
run(m_ssp5_nocc_cb)

# Increase in migrant flows of 100% compared to current policy
m_ssp1_nocc_ob = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc_ob = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc_ob = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc_ob = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc_ob = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc_ob, :runwithoutdamage, true)
update_param!(m_ssp2_nocc_ob, :runwithoutdamage, true)
update_param!(m_ssp3_nocc_ob, :runwithoutdamage, true)
update_param!(m_ssp4_nocc_ob, :runwithoutdamage, true)
update_param!(m_ssp5_nocc_ob, :runwithoutdamage, true)
update_param!(m_ssp1_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp2_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp3_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp4_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp5_nocc_ob, :policy, param_border[:policy_2])
run(m_ssp1_nocc_ob)
run(m_ssp2_nocc_ob)
run(m_ssp3_nocc_ob)
run(m_ssp4_nocc_ob)
run(m_ssp5_nocc_ob)

# Current policies within Global North and Global South, closed between
m_ssp1_nocc_2w = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc_2w = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc_2w = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc_2w = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc_2w = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc_2w, :runwithoutdamage, true)
update_param!(m_ssp2_nocc_2w, :runwithoutdamage, true)
update_param!(m_ssp3_nocc_2w, :runwithoutdamage, true)
update_param!(m_ssp4_nocc_2w, :runwithoutdamage, true)
update_param!(m_ssp5_nocc_2w, :runwithoutdamage, true)
update_param!(m_ssp1_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp2_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp3_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp4_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp5_nocc_2w, :policy, param_border[:policy_half])
run(m_ssp1_nocc_2w)
run(m_ssp2_nocc_2w)
run(m_ssp3_nocc_2w)
run(m_ssp4_nocc_2w)
run(m_ssp5_nocc_2w)

# Look at net migrant flows for different border policies
migration_nocc = migration[:,[:year, :scen, :fundregion, :leave_currentborders, :leave_closedborders, :leave_moreopen, :leave_bordersnorthsouth, :netmig_currentborders, :netmig_overallclosed, :netmig_bordersmoreopen, :netmig_northsouthclosed]]

enter_nocc_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:enter_nocc_currentborders] = enter_nocc_currentborders
leave_nocc_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:leave_nocc_currentborders] = leave_nocc_currentborders

enter_nocc_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:enter_nocc_closedborders] = enter_nocc_closedborders
leave_nocc_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:leave_nocc_closedborders] = leave_nocc_closedborders

enter_nocc_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:enter_nocc_moreopen] = enter_nocc_moreopen
leave_nocc_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:leave_nocc_moreopen] = leave_nocc_moreopen

enter_nocc_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:enter_nocc_bordersnorthsouth] = enter_nocc_bordersnorthsouth
leave_nocc_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_nocc[:,:leave_nocc_bordersnorthsouth] = leave_nocc_bordersnorthsouth

migration_nocc[!,:netmig_nocc_currentborders] = migration_nocc[!,:enter_nocc_currentborders] .- migration_nocc[!,:leave_nocc_currentborders]
migration_nocc[!,:netmig_nocc_overallclosed] = migration_nocc[!,:enter_nocc_closedborders] .- migration_nocc[!,:leave_nocc_closedborders]
migration_nocc[!,:netmig_nocc_bordersmoreopen] = migration_nocc[!,:enter_nocc_moreopen] .- migration_nocc[!,:leave_nocc_moreopen]
migration_nocc[!,:netmig_nocc_northsouthclosed] = migration_nocc[!,:enter_nocc_bordersnorthsouth] .- migration_nocc[!,:leave_nocc_bordersnorthsouth]

# Plot differences in migration (people leaving a place) with and without climate change
leave_nocc_both = rename(stack(
    rename(migration_nocc, :leave_closedborders=>:leave_overallclosed, :leave_moreopen=>:leave_bordersmoreopen,:leave_bordersnorthsouth=>:leave_northsouthclosed), 
    [:leave_currentborders,:leave_overallclosed,:leave_bordersmoreopen,:leave_northsouthclosed], 
    [:scen, :fundregion, :year]
), :variable => :leave_type, :value => :leave)
leave_nocc = rename(stack(
    rename(migration_nocc, :leave_nocc_closedborders=>:leave_nocc_overallclosed, :leave_nocc_moreopen=>:leave_nocc_bordersmoreopen,:leave_nocc_bordersnorthsouth=>:leave_nocc_northsouthclosed), 
    [:leave_nocc_currentborders,:leave_nocc_overallclosed,:leave_nocc_bordersmoreopen,:leave_nocc_northsouthclosed],
    [:scen, :fundregion, :year]
), :variable => :leave_nocc_type, :value => :leave_nocc)
sort!(leave_nocc_both, [:scen,:fundregion,:year])
sort!(leave_nocc, [:scen,:fundregion,:year])
leave_nocc_both[!,:leave_nocc] = leave_nocc[:,:leave_nocc]
leave_nocc_both[!,:border] = [SubString(String(leave_nocc_both[i,:leave_type]), 7) for i in eachindex(leave_nocc_both[:,1])]
leave_nocc_both = innerjoin(leave_nocc_both,regions_fullname, on=:fundregion)
leave_nocc_both[!,:leave_diff] = leave_nocc_both[:,:leave] .- leave_nocc_both[:,:leave_nocc]

leave_nocc_tot = combine(groupby(leave_nocc_both, [:scen,:year,:border]), d->(leave_diff=sum(d.leave_diff),leave=sum(d.leave)))
leave_nocc_tot[!,:ccshare] = leave_nocc_tot[:,:leave_diff] ./ leave_nocc_tot[:,:leave]
for i in eachindex(leave_nocc_tot[:,1]) ; if leave_nocc_tot[i,:leave] == 0.0 ; leave_nocc_tot[i,:ccshare] = 0 end end

# Plot results
# Combined, these 5 graphs are Fig.S12
for s in ssps
    leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"ccshare:q", title = "Effect of climate change on global migration flows", axis={labelFontSize=16, titleFontSize=14,values = -0.012:0.004:0.012}, scale={domain=[-0.012,0.012]}},
        color={"border:o",scale={scheme=:darkmulti},legend={title=string("Border policy, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_ccshare_",s,"_mitig.png")))
end


########################################## Run models with zero CO2 fertilization ####################################################
param_damcalib = MimiFUND.load_default_parameters(joinpath(@__DIR__,"../data_damcalib"))

# Current borders
m_ssp1_nofert = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nofert = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nofert = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nofert = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nofert = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nofert, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp2_nofert, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp3_nofert, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp4_nofert, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp5_nofert, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp1_nofert, :consleak, 2.5)
update_param!(m_ssp2_nofert, :consleak, 2.5)
update_param!(m_ssp3_nofert, :consleak, 2.5)
update_param!(m_ssp4_nofert, :consleak, 2.5)
update_param!(m_ssp5_nofert, :consleak, 2.5)
run(m_ssp1_nofert)
run(m_ssp2_nofert)
run(m_ssp3_nofert)
run(m_ssp4_nofert)
run(m_ssp5_nofert)

# Closed borders between regions
m_ssp1_nofert_cb = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nofert_cb = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nofert_cb = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nofert_cb = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nofert_cb = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nofert_cb, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp2_nofert_cb, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp3_nofert_cb, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp4_nofert_cb, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp5_nofert_cb, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp1_nofert_cb, :consleak, 2.5)
update_param!(m_ssp2_nofert_cb, :consleak, 2.5)
update_param!(m_ssp3_nofert_cb, :consleak, 2.5)
update_param!(m_ssp4_nofert_cb, :consleak, 2.5)
update_param!(m_ssp5_nofert_cb, :consleak, 2.5)
update_param!(m_ssp1_nofert_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp2_nofert_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp3_nofert_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp4_nofert_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp5_nofert_cb, :policy, param_border[:policy_zero])
run(m_ssp1_nofert_cb)
run(m_ssp2_nofert_cb)
run(m_ssp3_nofert_cb)
run(m_ssp4_nofert_cb)
run(m_ssp5_nofert_cb)

# Increase in migrant flows of 100% compared to current policy
m_ssp1_nofert_ob = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nofert_ob = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nofert_ob = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nofert_ob = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nofert_ob = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nofert_ob, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp2_nofert_ob, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp3_nofert_ob, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp4_nofert_ob, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp5_nofert_ob, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp1_nofert_ob, :consleak, 2.5)
update_param!(m_ssp2_nofert_ob, :consleak, 2.5)
update_param!(m_ssp3_nofert_ob, :consleak, 2.5)
update_param!(m_ssp4_nofert_ob, :consleak, 2.5)
update_param!(m_ssp5_nofert_ob, :consleak, 2.5)
update_param!(m_ssp1_nofert_ob, :policy, param_border[:policy_2])
update_param!(m_ssp2_nofert_ob, :policy, param_border[:policy_2])
update_param!(m_ssp3_nofert_ob, :policy, param_border[:policy_2])
update_param!(m_ssp4_nofert_ob, :policy, param_border[:policy_2])
update_param!(m_ssp5_nofert_ob, :policy, param_border[:policy_2])
run(m_ssp1_nofert_ob)
run(m_ssp2_nofert_ob)
run(m_ssp3_nofert_ob)
run(m_ssp4_nofert_ob)
run(m_ssp5_nofert_ob)

# Current policies within Global North and Global South, closed between
m_ssp1_nofert_2w = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nofert_2w = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nofert_2w = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nofert_2w = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nofert_2w = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nofert_2w, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp2_nofert_2w, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp3_nofert_2w, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp4_nofert_2w, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp5_nofert_2w, :agcbm, map(x->x/10,m_ssp2_nomig[:impactagriculture,:agcbm]))
update_param!(m_ssp1_nofert_2w, :consleak, 2.5)
update_param!(m_ssp2_nofert_2w, :consleak, 2.5)
update_param!(m_ssp3_nofert_2w, :consleak, 2.5)
update_param!(m_ssp4_nofert_2w, :consleak, 2.5)
update_param!(m_ssp5_nofert_2w, :consleak, 2.5)
update_param!(m_ssp1_nofert_2w, :policy, param_border[:policy_half])
update_param!(m_ssp2_nofert_2w, :policy, param_border[:policy_half])
update_param!(m_ssp3_nofert_2w, :policy, param_border[:policy_half])
update_param!(m_ssp4_nofert_2w, :policy, param_border[:policy_half])
update_param!(m_ssp5_nofert_2w, :policy, param_border[:policy_half])
run(m_ssp1_nofert_2w)
run(m_ssp2_nofert_2w)
run(m_ssp3_nofert_2w)
run(m_ssp4_nofert_2w)
run(m_ssp5_nofert_2w)


# Check whether exposure findings still hold when changing calibrations
move_nofert = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

move_nofert_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nofert[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nofert[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nofert[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nofert[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nofert[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_nofert[:,:move_nofert_currentborders] = move_nofert_currentborders
move_nofert_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nofert_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nofert_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nofert_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nofert_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_nofert[:,:move_nofert_closedborders] = move_nofert_closedborders
move_nofert_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nofert_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nofert_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nofert_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nofert_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_nofert[:,:move_nofert_moreopen] = move_nofert_moreopen
move_nofert_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nofert_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nofert_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nofert_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nofert_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_nofert[:,:move_nofert_bordersnorthsouth] = move_nofert_bordersnorthsouth

exposed_nofert = innerjoin(move_nofert, rename(rename(
    move_nofert, 
    :origin=>:dest,
    :destination=>:origin,
    :move_nofert_currentborders=>:move_nofert_otherdir_currentborders,
    :move_nofert_closedborders=>:move_nofert_otherdir_closedborders,
    :move_nofert_moreopen=>:move_nofert_otherdir_moreopen,
    :move_nofert_bordersnorthsouth=>:move_nofert_otherdir_bordersnorthsouth
),:dest=>:destination), on = [:year,:scen,:origin,:destination])
for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed_nofert[!,Symbol(string(:move_nofert_net,btype))] = exposed_nofert[!,Symbol(string(:move_nofert,btype))] .- exposed_nofert[!,Symbol(string(:move_nofert_otherdir,btype))]
end

exposed_nofert = innerjoin(exposed_nofert, rename(
    damages_nofert, 
    :fundregion => :origin, 
    :damgdp_nofert_currentborders => :damgdp_nofert_or_currentborders, 
    :damgdp_nofert_closedborders => :damgdp_nofert_or_closedborders, 
    :damgdp_nofert_moreopen => :damgdp_nofert_or_moreopen, 
    :damgdp_nofert_bordersnorthsouth => :damgdp_nofert_or_bordersnorthsouth
)[:,[:year,:scen,:origin,:damgdp_nofert_or_currentborders,:damgdp_nofert_or_closedborders,:damgdp_nofert_or_moreopen,:damgdp_nofert_or_bordersnorthsouth]], on = [:year,:scen,:origin])
exposed_nofert = innerjoin(exposed_nofert, rename(
    damages_nofert, 
    :fundregion => :destination, 
    :damgdp_nofert_currentborders => :damgdp_nofert_dest_currentborders, 
    :damgdp_nofert_closedborders => :damgdp_nofert_dest_closedborders, 
    :damgdp_nofert_moreopen => :damgdp_nofert_dest_moreopen, 
    :damgdp_nofert_bordersnorthsouth => :damgdp_nofert_dest_bordersnorthsouth
)[:,[:year,:scen,:destination,:damgdp_nofert_dest_currentborders,:damgdp_nofert_dest_closedborders,:damgdp_nofert_dest_moreopen,:damgdp_nofert_dest_bordersnorthsouth]], on = [:year,:scen,:destination])

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed_nofert[!,Symbol(string(:exposure_nofert,btype))] = [exposed_nofert[i,Symbol(string(:move_nofert_net,btype))] >0 ? (exposed_nofert[i,Symbol(string(:damgdp_nofert_dest,btype))] > exposed_nofert[i,Symbol(string(:damgdp_nofert_or,btype))] ? "increase" : "decrease") : (exposed_nofert[i,Symbol(string(:move_nofert_net,btype))] <0 ? ("") : "nomove") for i in eachindex(exposed_nofert[:,1])]
end

index_r = DataFrame(index=1:16,region=regions)
exposed_nofert = innerjoin(exposed_nofert,rename(index_r,:region=>:origin,:index=>:index_or),on=:origin)
exposed_nofert = innerjoin(exposed_nofert,rename(index_r,:region=>:destination,:index=>:index_dest),on=:destination)

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed_nofert[!,Symbol(string(:damgdp_nofert_diff,btype))] = exposed_nofert[!,Symbol(string(:damgdp_nofert_dest,btype))] .- exposed_nofert[!,Symbol(string(:damgdp_nofert_or,btype))]
end

exposed_nofert_all = DataFrame(
    scen = repeat(exposed_nofert[(exposed_nofert[!,:year].==2100),:scen],4),
    origin = repeat(exposed_nofert[(exposed_nofert[!,:year].==2100),:origin],4),
    destination = repeat(exposed_nofert[(exposed_nofert[!,:year].==2100),:destination],4),
    btype = vcat(repeat(["currentborders"],size(exposed_nofert[(exposed_nofert[!,:year].==2100),:],1)), repeat(["overallclosed"],size(exposed_nofert[(exposed_nofert[!,:year].==2100),:],1)), repeat(["bordersmoreopen"],size(exposed_nofert[(exposed_nofert[!,:year].==2100),:],1)), repeat(["northsouthclosed"],size(exposed_nofert[(exposed_nofert[!,:year].==2100),:],1))),
    move = vcat(exposed_nofert[(exposed_nofert[!,:year].==2100),:move_nofert_currentborders],exposed_nofert[(exposed_nofert[!,:year].==2100),:move_nofert_closedborders],exposed_nofert[(exposed_nofert[!,:year].==2100),:move_nofert_moreopen],exposed_nofert[(exposed_nofert[!,:year].==2100),:move_nofert_bordersnorthsouth]),
    damgdp_nofert_diff = vcat(exposed_nofert[(exposed_nofert[!,:year].==2100),:damgdp_nofert_diff_currentborders],exposed_nofert[(exposed_nofert[!,:year].==2100),:damgdp_nofert_diff_closedborders],exposed_nofert[(exposed_nofert[!,:year].==2100),:damgdp_nofert_diff_moreopen],exposed_nofert[(exposed_nofert[!,:year].==2100),:damgdp_nofert_diff_bordersnorthsouth])
)
for i in eachindex(exposed_nofert_all[:,1])
    if exposed_nofert_all[i,:move] == 0
        exposed_nofert_all[i,:damgdp_nofert_diff] = 0
    end
end
exposed_nofert_all = innerjoin(exposed_nofert_all, rename(regions_fullname, :fundregion => :origin, :regionname => :originname), on= :origin)
exposed_nofert_all = innerjoin(exposed_nofert_all, rename(regions_fullname, :fundregion => :destination, :regionname => :destinationname), on= :destination)
exposed_nofert_all[!,:scen_btype] = [string(exposed_nofert_all[i,:scen],"_",exposed_nofert_all[i,:btype]) for i in eachindex(exposed_nofert_all[:,1])]

exposed_nofert_all |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_nofert_diff:q", axis={labelFontSize=16, titleFontSize=16}, title="Change in exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    size= {"move:q", legend=nothing},
    color={"btype:o",scale={scheme=:dark2},legend={title=string("Migrant outflows"), titleFontSize=24, titleLimit=240, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages/", string("FigS13.png")))

