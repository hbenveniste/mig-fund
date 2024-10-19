using DelimitedFiles, CSV, VegaLite, VegaDatasets, FileIO, FilePaths
using Statistics, DataFrames, Query

using MimiFUND

include("main_mig.jl")
include("fund_ssp.jl")

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

ssps=["SSP1","SSP2","SSP3","SSP4","SSP5"]
migyesno=["mig","nomig"]
for s in ssps
    for myn in migyesno
        m=getsspmodel(scen=s,migyesno=myn)
        run(m)
        scc = MimiFUND.compute_scco2(m,year=2020, equity_weights=true)
        println("FUND with equity weights and scenario ", s, " ", myn, " SCC=", scc)
    end
end
for s in ssps
    for myn in migyesno
        m=getmigrationmodel(scen=s,migyesno=myn)
        run(m)
        scc = MimiFUND.compute_scco2(m,year=2020,equity_weights=true)
        println("Mig-FUND with equity weights and scenario ", s, " ", myn, " SCC=", scc)
    end
end


# Compare damages in absolute terms and in % of GDP in Mig-FUND and in FUND with SSP
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

damages = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

dam_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_migFUND] = dam_migFUND

gdp_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migFUND] = gdp_migFUND
damages[:,:damgdp_migFUND] = damages[:,:damages_migFUND] ./ (damages[:,:gdp_migFUND] .* 10^9)


# Compare damages in Mig-FUND for different border policy scenarios
# Closed borders between regions
param_border = MimiFUND.load_default_parameters(joinpath(@__DIR__,"../data_borderpolicy"))
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

dam_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_migFUND_cb] = dam_migFUND_cb
dam_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_migFUND_ob] = dam_migFUND_ob
dam_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:addimpact,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_migFUND_2w] = dam_migFUND_2w
gdp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migFUND_cb] = gdp_migFUND_cb
gdp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migFUND_ob] = gdp_migFUND_ob
gdp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migFUND_2w] = gdp_migFUND_2w

damages[:,:damgdp_migFUND_cb] = damages[:,:damages_migFUND_cb] ./ (damages[:,:gdp_migFUND_cb] .* 10^9)
damages[:,:damgdp_migFUND_ob] = damages[:,:damages_migFUND_ob] ./ (damages[:,:gdp_migFUND_ob] .* 10^9)
damages[:,:damgdp_migFUND_2w] = damages[:,:damages_migFUND_2w] ./ (damages[:,:gdp_migFUND_2w] .* 10^9)
rename!(damages, :damages_migFUND => :dam_currentborders, :damages_migFUND_cb => :dam_closedborders, :damages_migFUND_ob => :dam_moreopen, :damages_migFUND_2w => :dam_bordersnorthsouth)
rename!(damages, :damgdp_migFUND => :damgdp_currentborders, :damgdp_migFUND_cb => :damgdp_closedborders, :damgdp_migFUND_ob => :damgdp_moreopen, :damgdp_migFUND_2w => :damgdp_bordersnorthsouth)


# Plot composition of damages per impact for each border policy, SSP and region
dam_impact = damages[:,[:year, :scen, :fundregion, :dam_currentborders, :dam_closedborders, :dam_moreopen, :dam_bordersnorthsouth]]
for imp in [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost]
    imp_curr = vcat(
        collect(Iterators.flatten(m_ssp1_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_currentborders"))] = imp_curr
    imp_closed = vcat(
        collect(Iterators.flatten(m_ssp1_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_closedborders"))] = imp_closed
    imp_more = vcat(
        collect(Iterators.flatten(m_ssp1_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_moreopen"))] = imp_more
    imp_ns = vcat(
        collect(Iterators.flatten(m_ssp1_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_bordersnorthsouth"))] = imp_ns
end
# We count as climate change damage only those attributed to differences in income resulting from climate change impacts
imp_curr = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_curr = vcat(
    collect(Iterators.flatten(m_ssp1_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_currentborders"))] = imp_curr - imp_nocc_curr
imp_closed = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_closed = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_closedborders"))] = imp_closed - imp_nocc_closed
imp_more = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_more = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_moreopen"))] = imp_more - imp_nocc_more
imp_ns = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_ns = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_bordersnorthsouth"))] = imp_ns - imp_nocc_ns
# Impacts coded as negative if damaging: recode as positive
for imp in [:water,:forests,:heating,:cooling,:agcost]
    for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
        dam_impact[!,Symbol(string(imp,btype))] .*= -1
    end
end
for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    for imp in [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]
        dam_impact[!,Symbol(string("share_",imp,btype))] = dam_impact[!,Symbol(string(imp,btype))] ./ dam_impact[!,Symbol(string("dam",btype))] .* 1000000000
    end
end

dam_impact_stacked = stack(dam_impact, map(x -> Symbol(string(x,"_currentborders")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_impact_stacked, :variable => :impact, :value => :impact_dam)
dam_impact_stacked[!,:borders] = repeat(["_currentborders"],size(dam_impact_stacked,1))
dam_impact_stacked[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-15)), dam_impact_stacked[!,:impact])

dam_impact_stacked_cb = stack(dam_impact, map(x -> Symbol(string(x,"_closedborders")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_impact_stacked_cb, :variable => :impact, :value => :impact_dam)
dam_impact_stacked_cb[!,:borders] = repeat(["_closedborders"],size(dam_impact_stacked_cb,1))
dam_impact_stacked_cb[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-14)), dam_impact_stacked_cb[!,:impact])

dam_impact_stacked_ob = stack(dam_impact, map(x -> Symbol(string(x,"_moreopen")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_impact_stacked_ob, :variable => :impact, :value => :impact_dam)
dam_impact_stacked_ob[!,:borders] = repeat(["_moreopen"],size(dam_impact_stacked_ob,1))
dam_impact_stacked_ob[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-9)), dam_impact_stacked_ob[!,:impact])

dam_impact_stacked_2w = stack(dam_impact, map(x -> Symbol(string(x,"_bordersnorthsouth")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_impact_stacked_2w, :variable => :impact, :value => :impact_dam)
dam_impact_stacked_2w[!,:borders] = repeat(["_bordersnorthsouth"],size(dam_impact_stacked_2w,1))
dam_impact_stacked_2w[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-18)), dam_impact_stacked_2w[!,:impact])

dam_impact_stacked = vcat(dam_impact_stacked, dam_impact_stacked_cb, dam_impact_stacked_ob, dam_impact_stacked_2w)

regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe", "Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union", "Middle East", "Central America", "South America","South Asia","Southeast Asia","China plus", "North Africa","Sub-Saharan Africa","Small Island States"]
)
dam_impact_stacked = innerjoin(dam_impact_stacked, regions_fullname, on=:fundregion)

# Combined, these 5 graphs are Fig.S7
for s in ssps
    dam_impact_stacked |> @filter(_.year ==2100 && _.scen == s && _.borders == "_currentborders") |> @vlplot(
        mark={:bar}, width=350, height=300,
        x={"fundregion:o", axis={labelFontSize=16, labelAngle=-90}, ticks=false, domain=false, title=nothing, minExtent=80, scale={paddingInner=0.2,paddingOuter=0.2}},
        y={"impact_dam:q", aggregate = :sum, stack = true, title = "Billion USD2005", axis={titleFontSize=18, labelFontSize=16}},
        color={"impact:n",scale={scheme="category20c"},legend={title=string("Impact type"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=220}},
        resolve = {scale={y=:independent}}, title={text=string("Damages in 2100, current borders, ", s), fontSize=20}
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("impdam_",s,"_mitig_update.png")))
end


# Calculate the proportion of migrants moving from a less to a more exposed region (in terms of damages/GDP)
move_all = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

move_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_all[:,:move_currentborders] = move_currentborders
move_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_all[:,:move_closedborders] = move_closedborders
move_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_all[:,:move_moreopen] = move_moreopen
move_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move_all[:,:move_bordersnorthsouth] = move_bordersnorthsouth

exposed = innerjoin(move_all[!,1:8], rename(rename(
    move_all[!,1:8], 
    :origin=>:dest,
    :destination=>:origin,
    :move_currentborders=>:move_otherdir_currentborders,
    :move_closedborders=>:move_otherdir_closedborders,
    :move_moreopen=>:move_otherdir_moreopen,
    :move_bordersnorthsouth=>:move_otherdir_bordersnorthsouth
),:dest=>:destination), on = [:year,:scen,:origin,:destination])
for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed[!,Symbol(string(:move_net,btype))] = exposed[!,Symbol(string(:move,btype))] .- exposed[!,Symbol(string(:move_otherdir,btype))]
end

exposed = innerjoin(exposed, rename(
    damages, 
    :fundregion => :origin, 
    :damgdp_currentborders => :damgdp_or_currentborders, 
    :damgdp_closedborders => :damgdp_or_closedborders, 
    :damgdp_moreopen => :damgdp_or_moreopen, 
    :damgdp_bordersnorthsouth => :damgdp_or_bordersnorthsouth
)[:,[:year,:scen,:origin,:damgdp_or_currentborders,:damgdp_or_closedborders,:damgdp_or_moreopen,:damgdp_or_bordersnorthsouth]], on = [:year,:scen,:origin])
exposed = innerjoin(exposed, rename(
    damages, 
    :fundregion => :destination, 
    :damgdp_currentborders => :damgdp_dest_currentborders, 
    :damgdp_closedborders => :damgdp_dest_closedborders, 
    :damgdp_moreopen => :damgdp_dest_moreopen, 
    :damgdp_bordersnorthsouth => :damgdp_dest_bordersnorthsouth
)[:,[:year,:scen,:destination,:damgdp_dest_currentborders,:damgdp_dest_closedborders,:damgdp_dest_moreopen,:damgdp_dest_bordersnorthsouth]], on = [:year,:scen,:destination])

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed[!,Symbol(string(:exposure,btype))] = [exposed[i,Symbol(string(:move_net,btype))] >0 ? (exposed[i,Symbol(string(:damgdp_dest,btype))] > exposed[i,Symbol(string(:damgdp_or,btype))] ? "increase" : "decrease") : (exposed[i,Symbol(string(:move_net,btype))] <0 ? ("") : "nomove") for i in eachindex(exposed[:,1])]
end

index_r = DataFrame(index=1:16,region=regions)
exposed = innerjoin(exposed,rename(index_r,:region=>:origin,:index=>:index_or),on=:origin)
exposed = innerjoin(exposed,rename(index_r,:region=>:destination,:index=>:index_dest),on=:destination)

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed[!,Symbol(string(:damgdp_diff,btype))] = exposed[!,Symbol(string(:damgdp_dest,btype))] .- exposed[!,Symbol(string(:damgdp_or,btype))]
end
regions_fullname = DataFrame(
    fundregion=regions,
    regionname = ["United States","Canada","Western Europe","Japan & South Korea","Australia & New Zealand","Central & Eastern Europe","Former Soviet Union","Middle East","Central America","South America","South Asia","Southeast Asia","China plus","North Africa","Sub-Saharan Africa","Small Island States"]
)
exposed_all = DataFrame(
    scen = repeat(exposed[(exposed[!,:year].==2100),:scen],4),
    origin = repeat(exposed[(exposed[!,:year].==2100),:origin],4),
    destination = repeat(exposed[(exposed[!,:year].==2100),:destination],4),
    btype = vcat(repeat(["currentborders"],size(exposed[(exposed[!,:year].==2100),:],1)), repeat(["overallclosed"],size(exposed[(exposed[!,:year].==2100),:],1)), repeat(["bordersmoreopen"],size(exposed[(exposed[!,:year].==2100),:],1)), repeat(["northsouthclosed"],size(exposed[(exposed[!,:year].==2100),:],1))),
    move = vcat(exposed[(exposed[!,:year].==2100),:move_currentborders],exposed[(exposed[!,:year].==2100),:move_closedborders],exposed[(exposed[!,:year].==2100),:move_moreopen],exposed[(exposed[!,:year].==2100),:move_bordersnorthsouth]),
    damgdp_diff = vcat(exposed[(exposed[!,:year].==2100),:damgdp_diff_currentborders],exposed[(exposed[!,:year].==2100),:damgdp_diff_closedborders],exposed[(exposed[!,:year].==2100),:damgdp_diff_moreopen],exposed[(exposed[!,:year].==2100),:damgdp_diff_bordersnorthsouth])
)
for i in eachindex(exposed_all[:,1])
    if exposed_all[i,:move] == 0
        exposed_all[i,:damgdp_diff] = 0
    end
end
exposed_all = innerjoin(exposed_all, rename(regions_fullname, :fundregion => :origin, :regionname => :originname), on= :origin)
exposed_all = innerjoin(exposed_all, rename(regions_fullname, :fundregion => :destination, :regionname => :destinationname), on= :destination)

exposed_all[(exposed_all[:,:btype].!="overallclosed"),:] |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_diff:q", axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    size= {"move:q", legend=nothing},
    color={"btype:o",scale={scheme=:dark2},legend={title=string("Migrant outflows"), titleFontSize=24, titleLimit=240, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages/", string("Fig2_update.png")))
# Also Fig.S17 for runs without remittances


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)

damgdp_maps = leftjoin(damages, isonum_fundregion, on = :fundregion)
for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    damgdp_maps[!,Symbol(:damgdp,btype)] .*= 100
end
damgdp_maps[!,:damgdpdiff_closedborders] = (damgdp_maps[!,:damgdp_closedborders] ./ map(x->abs(x), damgdp_maps[!,:damgdp_currentborders]) .- 1) .* 100
damgdp_maps[!,:damgdpdiff_moreopen] = (damgdp_maps[!,:damgdp_moreopen] ./ map(x->abs(x), damgdp_maps[!,:damgdp_currentborders]) .- 1) .* 100
damgdp_maps[!,:damgdpdiff_bordersnorthsouth] = (damgdp_maps[!,:damgdp_bordersnorthsouth] ./ map(x->abs(x), damgdp_maps[!,:damgdp_currentborders]) .- 1) .* 100

# Combined, these 5 graphs are Fig.S8
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_currentborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, current borders, 2100, ", s),fontSize=24}, 
        color = {:damgdp_currentborders, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdp_currentborders_", s, "_mitig_update.png")))
end


# Register regional damages for period 1990-2015. We focus on SSP2 and current borders (virtually no difference with other scenarios)
damcalib = damages[.&(damages[:,:year].>=1990,damages[:,:year].<=2015,map(x->mod(x,5)==0,damages[:,:year]),damages[:,:scen].=="SSP2"),[:year,:fundregion,:damgdp_currentborders]]
CSV.write(joinpath(@__DIR__,"../input_data/damcalib.csv"),damcalib;writeheader=false)