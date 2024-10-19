using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query

using Mimi, MimiFUND

include("main_mig.jl")


param_border = MimiFUND.load_default_parameters(joinpath(@__DIR__,"../data_borderpolicy"))

ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

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


########################################## Run models with zero CO2 fertilization ####################################################
param_damcalib = MimiFUND.load_default_parameters(joinpath(@__DIR__,"../data_damcalib"))

m_ssp2_nomig = getmigrationmodel(scen="SSP2",migyesno="nomig")
run(m_ssp2_nomig)

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
update_param!(m_ssp1_nofert, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp2_nofert, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp3_nofert, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp4_nofert, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp5_nofert, :socioeconomic, :consleak, 2.5)
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
update_param!(m_ssp1_nofert_cb, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp2_nofert_cb, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp3_nofert_cb, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp4_nofert_cb, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp5_nofert_cb, :socioeconomic, :consleak, 2.5)
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
update_param!(m_ssp1_nofert_ob, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp2_nofert_ob, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp3_nofert_ob, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp4_nofert_ob, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp5_nofert_ob, :socioeconomic, :consleak, 2.5)
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
update_param!(m_ssp1_nofert_2w, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp2_nofert_2w, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp3_nofert_2w, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp4_nofert_2w, :socioeconomic, :consleak, 2.5)
update_param!(m_ssp5_nofert_2w, :socioeconomic, :consleak, 2.5)
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

damages_nofert = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
dam_nofert_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nofert[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:damages_nofert_migFUND] = dam_nofert_migFUND
dam_nofert_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_cb[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_cb[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_cb[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_cb[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_cb[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:damages_nofert_migFUND_cb] = dam_nofert_migFUND_cb
dam_nofert_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_ob[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_ob[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_ob[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_ob[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_ob[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:damages_nofert_migFUND_ob] = dam_nofert_migFUND_ob
dam_nofert_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_2w[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_2w[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_2w[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_2w[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_2w[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:damages_nofert_migFUND_2w] = dam_nofert_migFUND_2w
gdp_nofert_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nofert[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:gdp_nofert_migFUND] = gdp_nofert_migFUND
gdp_nofert_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:gdp_nofert_migFUND_cb] = gdp_nofert_migFUND_cb
gdp_nofert_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:gdp_nofert_migFUND_ob] = gdp_nofert_migFUND_ob
gdp_nofert_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_nofert[:,:gdp_nofert_migFUND_2w] = gdp_nofert_migFUND_2w

damages_nofert[:,:damgdp_nofert_migFUND] = damages_nofert[:,:damages_nofert_migFUND] ./ (damages_nofert[:,:gdp_nofert_migFUND] .* 10^9)
damages_nofert[:,:damgdp_nofert_migFUND_cb] = damages_nofert[:,:damages_nofert_migFUND_cb] ./ (damages_nofert[:,:gdp_nofert_migFUND_cb] .* 10^9)
damages_nofert[:,:damgdp_nofert_migFUND_ob] = damages_nofert[:,:damages_nofert_migFUND_ob] ./ (damages_nofert[:,:gdp_nofert_migFUND_ob] .* 10^9)
damages_nofert[:,:damgdp_nofert_migFUND_2w] = damages_nofert[:,:damages_nofert_migFUND_2w] ./ (damages_nofert[:,:gdp_nofert_migFUND_2w] .* 10^9)
rename!(damages_nofert, :damages_nofert_migFUND => :dam_nofert_currentborders, :damages_nofert_migFUND_cb => :dam_nofert_closedborders, :damages_nofert_migFUND_ob => :dam_nofert_moreopen, :damages_nofert_migFUND_2w => :dam_nofert_bordersnorthsouth)
rename!(damages_nofert, :damgdp_nofert_migFUND => :damgdp_nofert_currentborders, :damgdp_nofert_migFUND_cb => :damgdp_nofert_closedborders, :damgdp_nofert_migFUND_ob => :damgdp_nofert_moreopen, :damgdp_nofert_migFUND_2w => :damgdp_nofert_bordersnorthsouth)

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
) |> save(joinpath(@__DIR__, "../results/damages/", string("FigS13_update.png")))


########################################## Run models with the residuals from gravity model based on the last 5-yr period (2010-2015) ####################################################
param_mig = MimiFUND.load_default_parameters(joinpath(@__DIR__,"../data_mig"))

# Run models
m_ssp1_1p = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_1p = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_1p = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_1p = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_1p = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_1p, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp2_1p, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp3_1p, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp4_1p, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp5_1p, :gravres, param_mig[:gravres_1p])
run(m_ssp1_1p)
run(m_ssp2_1p)
run(m_ssp3_1p)
run(m_ssp4_1p)
run(m_ssp5_1p)

# Closed borders between regions
m_ssp1_1p_cb = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_1p_cb = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_1p_cb = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_1p_cb = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_1p_cb = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_1p_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp2_1p_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp3_1p_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp4_1p_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp5_1p_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp1_1p_cb, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp2_1p_cb, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp3_1p_cb, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp4_1p_cb, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp5_1p_cb, :gravres, param_mig[:gravres_1p])
run(m_ssp1_1p_cb)
run(m_ssp2_1p_cb)
run(m_ssp3_1p_cb)
run(m_ssp4_1p_cb)
run(m_ssp5_1p_cb)

# Increase in migrant flows of 100% compared to current policy
m_ssp1_1p_ob = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_1p_ob = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_1p_ob = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_1p_ob = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_1p_ob = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_1p_ob, :policy, param_border[:policy_2])
update_param!(m_ssp2_1p_ob, :policy, param_border[:policy_2])
update_param!(m_ssp3_1p_ob, :policy, param_border[:policy_2])
update_param!(m_ssp4_1p_ob, :policy, param_border[:policy_2])
update_param!(m_ssp5_1p_ob, :policy, param_border[:policy_2])
update_param!(m_ssp1_1p_ob, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp2_1p_ob, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp3_1p_ob, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp4_1p_ob, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp5_1p_ob, :gravres, param_mig[:gravres_1p])
run(m_ssp1_1p_ob)
run(m_ssp2_1p_ob)
run(m_ssp3_1p_ob)
run(m_ssp4_1p_ob)
run(m_ssp5_1p_ob)

# Current policies within Global North and Global South, closed between
m_ssp1_1p_2w = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_1p_2w = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_1p_2w = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_1p_2w = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_1p_2w = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_1p_2w, :policy, param_border[:policy_half])
update_param!(m_ssp2_1p_2w, :policy, param_border[:policy_half])
update_param!(m_ssp3_1p_2w, :policy, param_border[:policy_half])
update_param!(m_ssp4_1p_2w, :policy, param_border[:policy_half])
update_param!(m_ssp5_1p_2w, :policy, param_border[:policy_half])
update_param!(m_ssp1_1p_2w, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp2_1p_2w, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp3_1p_2w, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp4_1p_2w, :gravres, param_mig[:gravres_1p])
update_param!(m_ssp5_1p_2w, :gravres, param_mig[:gravres_1p])
run(m_ssp1_1p_2w)
run(m_ssp2_1p_2w)
run(m_ssp3_1p_2w)
run(m_ssp4_1p_2w)
run(m_ssp5_1p_2w)


migration_1p = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
enter_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:enter_currentborders] = enter_currentborders
leave_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:leave_currentborders] = leave_currentborders

enter_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:enter_closedborders] = enter_closedborders
leave_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:leave_closedborders] = leave_closedborders

enter_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_1p_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:enter_moreopen] = enter_moreopen
leave_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_1p_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:leave_moreopen] = leave_moreopen

enter_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_1p_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:enter_bordersnorthsouth] = enter_bordersnorthsouth
leave_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_1p_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_1p[:,:leave_bordersnorthsouth] = leave_bordersnorthsouth


# Look at net migrant flows for different border policies
migration_1p[!,:netmig_currentborders] = migration_1p[!,:enter_currentborders] .- migration_1p[!,:leave_currentborders]
migration_1p[!,:netmig_overallclosed] = migration_1p[!,:enter_closedborders] .- migration_1p[!,:leave_closedborders]
migration_1p[!,:netmig_bordersmoreopen] = migration_1p[!,:enter_moreopen] .- migration_1p[!,:leave_moreopen]
migration_1p[!,:netmig_northsouthclosed] = migration_1p[!,:enter_bordersnorthsouth] .- migration_1p[!,:leave_bordersnorthsouth]

netmig_1p = stack(
    migration_1p, 
    [:netmig_currentborders,:netmig_overallclosed,:netmig_bordersmoreopen,:netmig_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(netmig_1p, :variable => :netmig_type, :value => :netmig)

netmig_1p = innerjoin(netmig_1p,regions_fullname, on=:fundregion)

# For SSP2, the below figure is Fig.S10 
for s in ssps
    netmig_1p |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"netmig_type:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_",s,"_mitig_1p_update.png")))
end


# Look at net remittances flows for different border policies
income_1p = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

receive_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:receive_currentborders] = receive_currentborders
receive_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:receive_closedborders] = receive_closedborders
receive_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_1p_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:receive_moreopen] = receive_moreopen
receive_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_1p_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:receive_bordersnorthsouth] = receive_bordersnorthsouth

send_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:send_currentborders] = send_currentborders
send_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_1p_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:send_closedborders] = send_closedborders
send_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_1p_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:send_moreopen] = send_moreopen
send_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_1p_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_1p_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_1p_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_1p_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_1p_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_1p[:,:send_bordersnorthsouth] = send_bordersnorthsouth

income_1p[!,:netrem_currentborders] = income_1p[!,:receive_currentborders] .- income_1p[!,:send_currentborders]
income_1p[!,:netrem_overallclosed] = income_1p[!,:receive_closedborders] .- income_1p[!,:send_closedborders]
income_1p[!,:netrem_bordersmoreopen] = income_1p[!,:receive_moreopen] .- income_1p[!,:send_moreopen]
income_1p[!,:netrem_northsouthclosed] = income_1p[!,:receive_bordersnorthsouth] .- income_1p[!,:send_bordersnorthsouth]

netrem_1p = stack(
    income_1p, 
    [:netrem_currentborders,:netrem_overallclosed,:netrem_bordersmoreopen,:netrem_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(netrem_1p, :variable => :netrem_type, :value => :netrem)
netrem_1p = innerjoin(netrem_1p,regions_fullname, on=:fundregion)

# For SSP2, the below figure is Fig.S11
for s in ssps
    netrem_1p |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netrem:q", title = nothing, axis={labelFontSize=16}},
        color={"netrem_type:o",scale={scheme=:darkmulti},legend={title=string("Net remittances, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("netrem_",s,"_mitig_1p_update.png")))
end


########################################## Run models without remittances ####################################################
# Run models
m_ssp1_norem = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_norem = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_norem = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_norem = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_norem = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_norem, :migration, :runwithoutrem, true)
update_param!(m_ssp2_norem, :migration, :runwithoutrem, true)
update_param!(m_ssp3_norem, :migration, :runwithoutrem, true)
update_param!(m_ssp4_norem, :migration, :runwithoutrem, true)
update_param!(m_ssp5_norem, :migration, :runwithoutrem, true)
run(m_ssp1_norem)
run(m_ssp2_norem)
run(m_ssp3_norem)
run(m_ssp4_norem)
run(m_ssp5_norem)

# Closed borders between regions
m_ssp1_norem_cb = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_norem_cb = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_norem_cb = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_norem_cb = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_norem_cb = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_norem_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp2_norem_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp3_norem_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp4_norem_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp5_norem_cb, :policy, param_border[:policy_zero])
update_param!(m_ssp1_norem_cb, :migration, :runwithoutrem, true)
update_param!(m_ssp2_norem_cb, :migration, :runwithoutrem, true)
update_param!(m_ssp3_norem_cb, :migration, :runwithoutrem, true)
update_param!(m_ssp4_norem_cb, :migration, :runwithoutrem, true)
update_param!(m_ssp5_norem_cb, :migration, :runwithoutrem, true)
run(m_ssp1_norem_cb)
run(m_ssp2_norem_cb)
run(m_ssp3_norem_cb)
run(m_ssp4_norem_cb)
run(m_ssp5_norem_cb)

# Increase in migrant flows of 100% compared to current policy
m_ssp1_norem_ob = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_norem_ob = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_norem_ob = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_norem_ob = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_norem_ob = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_norem_ob, :policy, param_border[:policy_2])
update_param!(m_ssp2_norem_ob, :policy, param_border[:policy_2])
update_param!(m_ssp3_norem_ob, :policy, param_border[:policy_2])
update_param!(m_ssp4_norem_ob, :policy, param_border[:policy_2])
update_param!(m_ssp5_norem_ob, :policy, param_border[:policy_2])
update_param!(m_ssp1_norem_ob, :migration, :runwithoutrem, true)
update_param!(m_ssp2_norem_ob, :migration, :runwithoutrem, true)
update_param!(m_ssp3_norem_ob, :migration, :runwithoutrem, true)
update_param!(m_ssp4_norem_ob, :migration, :runwithoutrem, true)
update_param!(m_ssp5_norem_ob, :migration, :runwithoutrem, true)
run(m_ssp1_norem_ob)
run(m_ssp2_norem_ob)
run(m_ssp3_norem_ob)
run(m_ssp4_norem_ob)
run(m_ssp5_norem_ob)

# Current policies within Global North and Global South, closed between
m_ssp1_norem_2w = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_norem_2w = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_norem_2w = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_norem_2w = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_norem_2w = getmigrationmodel(scen="SSP5",migyesno="nomig")
update_param!(m_ssp1_norem_2w, :policy, param_border[:policy_half])
update_param!(m_ssp2_norem_2w, :policy, param_border[:policy_half])
update_param!(m_ssp3_norem_2w, :policy, param_border[:policy_half])
update_param!(m_ssp4_norem_2w, :policy, param_border[:policy_half])
update_param!(m_ssp5_norem_2w, :policy, param_border[:policy_half])
update_param!(m_ssp1_norem_2w, :migration, :runwithoutrem, true)
update_param!(m_ssp2_norem_2w, :migration, :runwithoutrem, true)
update_param!(m_ssp3_norem_2w, :migration, :runwithoutrem, true)
update_param!(m_ssp4_norem_2w, :migration, :runwithoutrem, true)
update_param!(m_ssp5_norem_2w, :migration, :runwithoutrem, true)
run(m_ssp1_norem_2w)
run(m_ssp2_norem_2w)
run(m_ssp3_norem_2w)
run(m_ssp4_norem_2w)
run(m_ssp5_norem_2w)


migration_norem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
enter_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_norem[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:enter_currentborders] = enter_currentborders
leave_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_norem[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:leave_currentborders] = leave_currentborders

enter_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_norem_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_cb[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:enter_closedborders] = enter_closedborders
leave_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_norem_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:leave_closedborders] = leave_closedborders

enter_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_norem_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_ob[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:enter_moreopen] = enter_moreopen
leave_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_norem_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:leave_moreopen] = leave_moreopen

enter_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_norem_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_2w[:migration,:entermig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:enter_bordersnorthsouth] = enter_bordersnorthsouth
leave_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_norem_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_norem[:,:leave_bordersnorthsouth] = leave_bordersnorthsouth


# Look at net migrant flows for different border policies
migration_norem[!,:netmig_currentborders] = migration_norem[!,:enter_currentborders] .- migration_norem[!,:leave_currentborders]
migration_norem[!,:netmig_overallclosed] = migration_norem[!,:enter_closedborders] .- migration_norem[!,:leave_closedborders]
migration_norem[!,:netmig_bordersmoreopen] = migration_norem[!,:enter_moreopen] .- migration_norem[!,:leave_moreopen]
migration_norem[!,:netmig_northsouthclosed] = migration_norem[!,:enter_bordersnorthsouth] .- migration_norem[!,:leave_bordersnorthsouth]

netmig_norem = stack(
    migration_norem, 
    [:netmig_currentborders,:netmig_overallclosed,:netmig_bordersmoreopen,:netmig_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(netmig_norem, :variable => :netmig_type, :value => :netmig)

netmig_norem = innerjoin(netmig_norem,regions_fullname, on=:fundregion)

# For SSP2, the below figure is Fig.S14
for s in ssps
    netmig_norem |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"netmig_type:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_",s,"_norem_update.png")))
end


# Compare income in Mig-FUND for different border policy scenarios
income_norem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

gdp_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_norem[:,:gdp_migFUND] = gdp_migFUND
gdp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_norem[:,:gdp_migFUND_cb] = gdp_migFUND_cb
gdp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_norem[:,:gdp_migFUND_ob] = gdp_migFUND_ob
gdp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income_norem[:,:gdp_migFUND_2w] = gdp_migFUND_2w

rename!(income_norem, :gdp_migFUND => :gdp_currentborders, :gdp_migFUND_cb => :gdp_closedborders, :gdp_migFUND_ob => :gdp_moreopen, :gdp_migFUND_2w => :gdp_bordersnorthsouth)

# Look at gdp for different border policies
gdp_norem = stack(
    rename(income_norem, :gdp_closedborders => :gdp_overallclosed, :gdp_moreopen => :gdp_bordersmoreopen, :gdp_bordersnorthsouth => :gdp_northsouthclosed), 
    [:gdp_currentborders,:gdp_overallclosed,:gdp_bordersmoreopen,:gdp_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(gdp_norem, :variable => :gdp_type, :value => :gdp)
gdp_norem = innerjoin(gdp_norem,regions_fullname, on=:fundregion)

# For SSP2, the below figure is Fig.S15
for s in ssps
    gdp_norem |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"gdp:q", title = nothing, axis={labelFontSize=16}},
        color={"gdp_type:o",scale={scheme=:darkgreen},legend={title=string("GDP levels, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("gdp_",s,"_norem_update.png")))
end


# Calculate the proportion of migrants moving from a less to a more exposed_norem region (in terms of damages/GDP)
damages_norem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

dam_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_norem[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:damages_migFUND] = dam_migFUND
gdp_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:gdp_migFUND] = gdp_migFUND
damages_norem[:,:damgdp_migFUND] = damages_norem[:,:damages_migFUND] ./ (damages_norem[:,:gdp_migFUND] .* 10^9)

dam_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_norem_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:damages_migFUND_cb] = dam_migFUND_cb
dam_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_norem_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:damages_migFUND_ob] = dam_migFUND_ob
dam_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_norem_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:damages_migFUND_2w] = dam_migFUND_2w
gdp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:gdp_migFUND_cb] = gdp_migFUND_cb
gdp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:gdp_migFUND_ob] = gdp_migFUND_ob
gdp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages_norem[:,:gdp_migFUND_2w] = gdp_migFUND_2w

damages_norem[:,:damgdp_migFUND_cb] = damages_norem[:,:damages_migFUND_cb] ./ (damages_norem[:,:gdp_migFUND_cb] .* 10^9)
damages_norem[:,:damgdp_migFUND_ob] = damages_norem[:,:damages_migFUND_ob] ./ (damages_norem[:,:gdp_migFUND_ob] .* 10^9)
damages_norem[:,:damgdp_migFUND_2w] = damages_norem[:,:damages_migFUND_2w] ./ (damages_norem[:,:gdp_migFUND_2w] .* 10^9)

rename!(damages_norem, :damages_migFUND => :dam_currentborders, :damages_migFUND_cb => :dam_closedborders, :damages_migFUND_ob => :dam_moreopen, :damages_migFUND_2w => :dam_bordersnorthsouth)
rename!(damages_norem, :damgdp_migFUND => :damgdp_currentborders, :damgdp_migFUND_cb => :damgdp_closedborders, :damgdp_migFUND_ob => :damgdp_moreopen, :damgdp_migFUND_2w => :damgdp_bordersnorthsouth)


move_norem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

move_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_norem[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_norem[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_norem[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_norem[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_norem[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_norem[:,:move_currentborders] = move_currentborders
move_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_norem_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_norem_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_norem_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_norem_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_norem_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_norem[:,:move_closedborders] = move_closedborders
move_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_norem_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_norem_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_norem_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_norem_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_norem_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_norem[:,:move_moreopen] = move_moreopen
move_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_norem_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_norem_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_norem_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_norem_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_norem_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_norem[:,:move_bordersnorthsouth] = move_bordersnorthsouth

exposed_norem = innerjoin(move_norem[!,1:8], rename(rename(
    move_norem[!,1:8], 
    :origin=>:dest,
    :destination=>:origin,
    :move_currentborders=>:move_otherdir_currentborders,
    :move_closedborders=>:move_otherdir_closedborders,
    :move_moreopen=>:move_otherdir_moreopen,
    :move_bordersnorthsouth=>:move_otherdir_bordersnorthsouth
),:dest=>:destination), on = [:year,:scen,:origin,:destination])
for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed_norem[!,Symbol(string(:move_net,btype))] = exposed_norem[!,Symbol(string(:move,btype))] .- exposed_norem[!,Symbol(string(:move_otherdir,btype))]
end

exposed_norem = innerjoin(exposed_norem, rename(
    damages_norem, 
    :fundregion => :origin, 
    :damgdp_currentborders => :damgdp_or_currentborders, 
    :damgdp_closedborders => :damgdp_or_closedborders, 
    :damgdp_moreopen => :damgdp_or_moreopen, 
    :damgdp_bordersnorthsouth => :damgdp_or_bordersnorthsouth
)[:,[:year,:scen,:origin,:damgdp_or_currentborders,:damgdp_or_closedborders,:damgdp_or_moreopen,:damgdp_or_bordersnorthsouth]], on = [:year,:scen,:origin])
exposed_norem = innerjoin(exposed_norem, rename(
    damages_norem, 
    :fundregion => :destination, 
    :damgdp_currentborders => :damgdp_dest_currentborders, 
    :damgdp_closedborders => :damgdp_dest_closedborders, 
    :damgdp_moreopen => :damgdp_dest_moreopen, 
    :damgdp_bordersnorthsouth => :damgdp_dest_bordersnorthsouth
)[:,[:year,:scen,:destination,:damgdp_dest_currentborders,:damgdp_dest_closedborders,:damgdp_dest_moreopen,:damgdp_dest_bordersnorthsouth]], on = [:year,:scen,:destination])

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed_norem[!,Symbol(string(:exposure,btype))] = [exposed_norem[i,Symbol(string(:move_net,btype))] >0 ? (exposed_norem[i,Symbol(string(:damgdp_dest,btype))] > exposed_norem[i,Symbol(string(:damgdp_or,btype))] ? "increase" : "decrease") : (exposed_norem[i,Symbol(string(:move_net,btype))] <0 ? ("") : "nomove") for i in eachindex(exposed_norem[:,1])]
end

index_r = DataFrame(index=1:16,region=regions)
exposed_norem = innerjoin(exposed_norem,rename(index_r,:region=>:origin,:index=>:index_or),on=:origin)
exposed_norem = innerjoin(exposed_norem,rename(index_r,:region=>:destination,:index=>:index_dest),on=:destination)

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed_norem[!,Symbol(string(:damgdp_diff,btype))] = exposed_norem[!,Symbol(string(:damgdp_dest,btype))] .- exposed_norem[!,Symbol(string(:damgdp_or,btype))]
end

exposed_all_norem = DataFrame(
    scen = repeat(exposed_norem[(exposed_norem[!,:year].==2100),:scen],4),
    origin = repeat(exposed_norem[(exposed_norem[!,:year].==2100),:origin],4),
    destination = repeat(exposed_norem[(exposed_norem[!,:year].==2100),:destination],4),
    btype = vcat(repeat(["currentborders"],size(exposed_norem[(exposed_norem[!,:year].==2100),:],1)), repeat(["overallclosed"],size(exposed_norem[(exposed_norem[!,:year].==2100),:],1)), repeat(["bordersmoreopen"],size(exposed_norem[(exposed_norem[!,:year].==2100),:],1)), repeat(["northsouthclosed"],size(exposed_norem[(exposed_norem[!,:year].==2100),:],1))),
    move = vcat(exposed_norem[(exposed_norem[!,:year].==2100),:move_currentborders],exposed_norem[(exposed_norem[!,:year].==2100),:move_closedborders],exposed_norem[(exposed_norem[!,:year].==2100),:move_moreopen],exposed_norem[(exposed_norem[!,:year].==2100),:move_bordersnorthsouth]),
    damgdp_diff = vcat(exposed_norem[(exposed_norem[!,:year].==2100),:damgdp_diff_currentborders],exposed_norem[(exposed_norem[!,:year].==2100),:damgdp_diff_closedborders],exposed_norem[(exposed_norem[!,:year].==2100),:damgdp_diff_moreopen],exposed_norem[(exposed_norem[!,:year].==2100),:damgdp_diff_bordersnorthsouth])
)
for i in eachindex(exposed_all_norem[:,1])
    if exposed_all_norem[i,:move] == 0
        exposed_all_norem[i,:damgdp_diff] = 0
    end
end
exposed_all_norem = innerjoin(exposed_all_norem, rename(regions_fullname, :fundregion => :origin, :regionname => :originname), on= :origin)
exposed_all_norem = innerjoin(exposed_all_norem, rename(regions_fullname, :fundregion => :destination, :regionname => :destinationname), on= :destination)

exposed_all_norem[(exposed_all_norem[:,:btype].!="overallclosed"),:] |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_diff:q", axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    size= {"move:q", legend=nothing},
    color={"btype:o",scale={scheme=:dark2},legend={title=string("Migrant outflows"), titleFontSize=24, titleLimit=240, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages/", string("Fig17_update.png")))


# Compare emissions in Mig-FUND for different border policy scenarios
em_norem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

em_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_norem[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em_norem[:,:em_migFUND] = em_migFUND

em_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_norem_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em_norem[:,:em_migFUND_cb] = em_migFUND_cb
em_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_norem_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em_norem[:,:em_migFUND_ob] = em_migFUND_ob
em_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_norem_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_norem_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_norem_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_norem_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_norem_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em_norem[:,:em_migFUND_2w] = em_migFUND_2w

em_world_norem = combine(groupby(em_norem,[:year,:scen]),d->(worldem_migFUND=sum(d.em_migFUND),worldem_migFUND_cb=sum(d.em_migFUND_cb),worldem_migFUND_ob=sum(d.em_migFUND_ob),worldem_migFUND_2w=sum(d.em_migFUND_2w)))
em_world_norem_p = em_world_norem[(map(x->mod(x,10)==0,em_world_norem[:,:year])),:]
rename!(em_world_norem_p, :worldem_migFUND => :worldem_currentborders, :worldem_migFUND_cb => :worldem_closedborders, :worldem_migFUND_ob => :worldem_moreopen, :worldem_migFUND_2w => :worldem_bordersnorthsouth)

em_world_norem_stack = stack(em_world_norem_p,[:worldem_currentborders,:worldem_closedborders,:worldem_moreopen,:worldem_bordersnorthsouth],[:scen,:year])
rename!(em_world_norem_stack,:variable => :worldem_type, :value => :worldem)

em_world_norem_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=500, height=400, mark={:point, size=80}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, 
    y = {"worldem:q", title="World CO2 emissions, Mt CO2", axis={labelFontSize=16,titleFontSize=16}}, 
    #title = "Global emissions for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend=nothing}, 
    shape = {"worldem_type:o", scale={range=["circle","triangle-up", "square","cross"]}, legend=nothing}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, 
    y = {"worldem:q", aggregate=:mean,type=:quantitative,title="World CO2 emissions, Mt CO2", axis={labelFontSize=16,titleFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend=nothing},
    detail = "worldem_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions/", "FigS16a_update.png"))


# Compare temperature in Mig-FUND for different border policy scenarios
temp_norem = DataFrame(
    year = repeat(years, outer = length(ssps)),
    scen = repeat(ssps,inner = length(years)),
)

temp_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp_norem[:,:temp_migFUND] = temp_migFUND
temp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp_norem[:,:temp_migFUND_cb] = temp_migFUND_cb
temp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp_norem[:,:temp_migFUND_ob] = temp_migFUND_ob
temp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp_norem[:,:temp_migFUND_2w] = temp_migFUND_2w

temp_norem_p = temp_norem[(map(x->mod(x,10)==0,temp_norem[:,:year])),:]
rename!(temp_norem_p, :temp_migFUND => :temp_currentborders, :temp_migFUND_cb => :temp_closedborders, :temp_migFUND_ob => :temp_moreopen, :temp_migFUND_2w => :temp_bordersnorthsouth)

temp_norem_all = stack(temp_norem_p, [:temp_currentborders,:temp_closedborders,:temp_moreopen,:temp_bordersnorthsouth], [:scen, :year])
rename!(temp_norem_all, :variable => :temp_type, :value => :temp)
temp_norem_all[!,:border] = [SubString(String(temp_norem_all[i,:temp_type]), 6) for i in eachindex(temp_norem_all[:,1])]

temp_norem_all |> @filter(_.year <= 2100) |> @vlplot(
    width=500, height=400, 
    mark={:point, size=80}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", title="Temperature increase, degC", axis={labelFontSize=16,titleFontSize=16}}, 
    #title = "Global temperature for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Climate scenario", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}}, 
    shape = {"border:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={title="Border policy", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", aggregate=:mean,typ=:quantitative,title="Temperature increase, degC", axis={labelFontSize=16,titleFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}, legend={title="Climate scenario", titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=280}},
    detail = "border:o"
) |> save(joinpath(@__DIR__, "../results/temperature/", "FigS16b_update.png"))
