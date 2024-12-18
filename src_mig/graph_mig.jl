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

run(m_ssp1_nomig; ntimesteps = 2100-1950+1)
run(m_ssp2_nomig; ntimesteps = 2100-1950+1)
run(m_ssp3_nomig; ntimesteps = 2100-1950+1)
run(m_ssp4_nomig; ntimesteps = 2100-1950+1)
run(m_ssp5_nomig; ntimesteps = 2100-1950+1)

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
run(m_ssp1_nomig_cb; ntimesteps = 2100-1950+1)
run(m_ssp2_nomig_cb; ntimesteps = 2100-1950+1)
run(m_ssp3_nomig_cb; ntimesteps = 2100-1950+1)
run(m_ssp4_nomig_cb; ntimesteps = 2100-1950+1)
run(m_ssp5_nomig_cb; ntimesteps = 2100-1950+1)

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
run(m_ssp1_nomig_ob; ntimesteps = 2100-1950+1)
run(m_ssp2_nomig_ob; ntimesteps = 2100-1950+1)
run(m_ssp3_nomig_ob; ntimesteps = 2100-1950+1)
run(m_ssp4_nomig_ob; ntimesteps = 2100-1950+1)
run(m_ssp5_nomig_ob; ntimesteps = 2100-1950+1)

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
run(m_ssp1_nomig_2w; ntimesteps = 2100-1950+1)
run(m_ssp2_nomig_2w; ntimesteps = 2100-1950+1)
run(m_ssp3_nomig_2w; ntimesteps = 2100-1950+1)
run(m_ssp4_nomig_2w; ntimesteps = 2100-1950+1)
run(m_ssp5_nomig_2w; ntimesteps = 2100-1950+1)


ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

migration_df = DataFrame(
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
migration_df[:,:enter_currentborders] = enter_currentborders
leave_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_df[:,:leave_currentborders] = leave_currentborders

enter_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_df[:,:enter_closedborders] = enter_closedborders
leave_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_df[:,:leave_closedborders] = leave_closedborders

enter_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_df[:,:enter_moreopen] = enter_moreopen
leave_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_df[:,:leave_moreopen] = leave_moreopen

enter_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_df[:,:enter_bordersnorthsouth] = enter_bordersnorthsouth
leave_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_df[:,:leave_bordersnorthsouth] = leave_bordersnorthsouth


# Look at net migrant flows for different border policies
migration_df[!,:netmig_currentborders] = migration_df[!,:enter_currentborders] .- migration_df[!,:leave_currentborders]
migration_df[!,:netmig_overallclosed] = migration_df[!,:enter_closedborders] .- migration_df[!,:leave_closedborders]
migration_df[!,:netmig_bordersmoreopen] = migration_df[!,:enter_moreopen] .- migration_df[!,:leave_moreopen]
migration_df[!,:netmig_northsouthclosed] = migration_df[!,:enter_bordersnorthsouth] .- migration_df[!,:leave_bordersnorthsouth]

netmig_all = stack(
    migration_df, 
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
for s in ssps
    netmig_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"netmig_type:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_",s,"_mitig_update.png")))
end


################################################ Compare to without climate change ##################################
# Run models without climate change
# Current borders
m_ssp1_nocc = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp2_nocc, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp3_nocc, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp4_nocc, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp5_nocc, :socioeconomic, :runwithoutdamage, true)
run(m_ssp1_nocc; ntimesteps = 2100-1950+1)
run(m_ssp2_nocc; ntimesteps = 2100-1950+1)
run(m_ssp3_nocc; ntimesteps = 2100-1950+1)
run(m_ssp4_nocc; ntimesteps = 2100-1950+1)
run(m_ssp5_nocc; ntimesteps = 2100-1950+1)

# Closed borders between regions
m_ssp1_nocc_cb = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc_cb = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc_cb = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc_cb = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc_cb = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc_cb, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp2_nocc_cb, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp3_nocc_cb, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp4_nocc_cb, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp5_nocc_cb, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp1_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp2_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp3_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp4_nocc_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp5_nocc_cb, :policy, param_border[:policy_zero])
run(m_ssp1_nocc_cb; ntimesteps = 2100-1950+1)
run(m_ssp2_nocc_cb; ntimesteps = 2100-1950+1)
run(m_ssp3_nocc_cb; ntimesteps = 2100-1950+1)
run(m_ssp4_nocc_cb; ntimesteps = 2100-1950+1)
run(m_ssp5_nocc_cb; ntimesteps = 2100-1950+1)

# Increase in migrant flows of 100% compared to current policy
m_ssp1_nocc_ob = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc_ob = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc_ob = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc_ob = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc_ob = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc_ob, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp2_nocc_ob, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp3_nocc_ob, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp4_nocc_ob, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp5_nocc_ob, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp1_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp2_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp3_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp4_nocc_ob, :policy, param_border[:policy_2])
update_param!(m_ssp5_nocc_ob, :policy, param_border[:policy_2])
run(m_ssp1_nocc_ob; ntimesteps = 2100-1950+1)
run(m_ssp2_nocc_ob; ntimesteps = 2100-1950+1)
run(m_ssp3_nocc_ob; ntimesteps = 2100-1950+1)
run(m_ssp4_nocc_ob; ntimesteps = 2100-1950+1)
run(m_ssp5_nocc_ob; ntimesteps = 2100-1950+1)

# Current policies within Global North and Global South, closed between
m_ssp1_nocc_2w = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nocc_2w = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nocc_2w = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nocc_2w = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nocc_2w = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_nocc_2w, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp2_nocc_2w, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp3_nocc_2w, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp4_nocc_2w, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp5_nocc_2w, :socioeconomic, :runwithoutdamage, true)
update_param!(m_ssp1_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp2_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp3_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp4_nocc_2w, :policy, param_border[:policy_half])
update_param!(m_ssp5_nocc_2w, :policy, param_border[:policy_half])
run(m_ssp1_nocc_2w; ntimesteps = 2100-1950+1)
run(m_ssp2_nocc_2w; ntimesteps = 2100-1950+1)
run(m_ssp3_nocc_2w; ntimesteps = 2100-1950+1)
run(m_ssp4_nocc_2w; ntimesteps = 2100-1950+1)
run(m_ssp5_nocc_2w; ntimesteps = 2100-1950+1)

# Look at net migrant flows for different border policies
migration_nocc = migration_df[!,[:year, :scen, :fundregion, :leave_currentborders, :leave_closedborders, :leave_moreopen, :leave_bordersnorthsouth, :netmig_currentborders, :netmig_overallclosed, :netmig_bordersmoreopen, :netmig_northsouthclosed]]

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
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_ccshare_",s,"_mitig_update.png")))
end
