using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query

using MimiFUND

include("main_mig.jl")
include("fund_ssp.jl")

# Compare original FUND model with original scenarios, FUND with SSP scenarios, and Mig-FUND with SSP scenarios zero migration.

# Run models
m_ssp1_nomig = getmigrationmodel(scen="SSP1",migyesno="nomig")
m_ssp2_nomig = getmigrationmodel(scen="SSP2",migyesno="nomig")
m_ssp3_nomig = getmigrationmodel(scen="SSP3",migyesno="nomig")
m_ssp4_nomig = getmigrationmodel(scen="SSP4",migyesno="nomig")
m_ssp5_nomig = getmigrationmodel(scen="SSP5",migyesno="nomig")

m_fundssp1 = getsspmodel(scen="SSP1",migyesno="mig")
m_fundssp2 = getsspmodel(scen="SSP2",migyesno="mig")
m_fundssp3 = getsspmodel(scen="SSP3",migyesno="mig")
m_fundssp4 = getsspmodel(scen="SSP4",migyesno="mig")
m_fundssp5 = getsspmodel(scen="SSP5",migyesno="mig")

m_fund = getfund()

run(m_ssp1_nomig)
run(m_ssp2_nomig)
run(m_ssp3_nomig)
run(m_ssp4_nomig)
run(m_ssp5_nomig)
run(m_fundssp1)
run(m_fundssp2)
run(m_fundssp3)
run(m_fundssp4)
run(m_fundssp5)
run(m_fund)


# Compare emissions in Mig-FUND, in FUND with SSP and in FUND with original scenarios
ssps = ["SSP1-RCP1.9","SSP2-RCP4.5","SSP3-RCP7.0","SSP4-RCP6.0","SSP5-RCP8.5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

em = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

em_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_migFUND] = em_migFUND
em_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_sspFUND] = em_sspFUND
em_origFUND = vcat(collect(Iterators.flatten(m_fund[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
em[:,:em_origFUND] = em_origFUND

em_p = em[(map(x->mod(x,10)==0,em[:,:year])),:]

em_all = stack(em_p, [:em_sspFUND,:em_migFUND,:em_origFUND], [:scen, :fundregion, :year])
rename!(em_all, :variable => :em_type, :value => :em)
for r in regions
    data_ssp = em_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.em_type != :em_origFUND) 
    data_fund = em_all[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.em_type == :em_origFUND) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"em:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Emissions of region ",r," for FUND with original SSP and Mig-FUND"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"em_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"em:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "em_type:o"
    ) + @vlplot(
        data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
        x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"em:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
        detail = "em_type:o"
    ) |> save(joinpath(@__DIR__, "../results/emissions/", string("em_", r, "_mitig.png")))
end

em_world = by(em,[:year,:scen],d->(worldem_sspFUND=sum(d.em_sspFUND),worldem_migFUND=sum(d.em_migFUND),worldem_origFUND=sum(d.em_origFUND)))
em_world_p = em_world[(map(x->mod(x,10)==0,em_world[:,:year])),:]
em_world_stack = stack(em_world_p,[:worldem_sspFUND,:worldem_migFUND,:worldem_origFUND],[:scen,:year])
rename!(em_world_stack,:variable => :worldem_type, :value => :worldem)
data_ssp = em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldem_type != :worldem_origFUND) 
data_fund = em_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldem_type == :worldem_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data = data_ssp,
    mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldem:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global emissions for FUND with original SSP and Mig-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldem_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldem:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldem_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldem:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldem_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions/", "em_world_mitig.png"))


pop_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_migFUND] = pop_migFUND
pop_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_sspFUND] = pop_sspFUND
pop_origFUND = vcat(collect(Iterators.flatten(m_fund[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
em[:,:pop_origFUND] = pop_origFUND

em[!,:empc_migFUND] = em[!,:em_migFUND] ./ em[!,:pop_migFUND] .* 10^6           # Emissions in MtCO2
em[!,:empc_sspFUND] = em[!,:em_sspFUND] ./ em[!,:pop_sspFUND] .* 10^6
em[!,:empc_origFUND] = em[!,:em_origFUND] ./ em[!,:pop_origFUND] .* 10^6

em_p = em[(map(x->mod(x,10)==0,em[:,:year])),:]

empc_all = stack(em_p, [:empc_sspFUND,:empc_migFUND,:empc_origFUND], [:scen, :fundregion, :year])
rename!(empc_all, :variable => :empc_type, :value => :empc)
for r in regions
    data_ssp = empc_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.empc_type != :empc_origFUND) 
    data_fund = empc_all[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.empc_type == :empc_origFUND) 
    @vlplot()+@vlplot(
        width=300, height=250,data=data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"empc:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Emissions per capita of region ",r," for FUND with original SSP and Mig-FUND"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"empc_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data=data_ssp,x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"empc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "empc_type:o"
    ) + @vlplot(
        data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
        x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"empc:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
        detail = "empc_type:o"
    ) |> save(joinpath(@__DIR__, "../results/emissions/", string("empc_", r, "_mitig.png")))
end

worldpop_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_migFUND] = worldpop_migFUND
worldpop_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp2[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp3[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp4[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp5[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_sspFUND] = worldpop_sspFUND
worldpop_origFUND = vcat(collect(Iterators.flatten(m_fund[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
em_world[:,:worldpop_origFUND] = worldpop_origFUND

em_world[!,:worldempc_migFUND] = em_world[!,:worldem_migFUND] ./ em_world[!,:worldpop_migFUND] .* 10^6           # Emissions in MtCO2
em_world[!,:worldempc_sspFUND] = em_world[!,:worldem_sspFUND] ./ em_world[!,:worldpop_sspFUND] .* 10^6
em_world[!,:worldempc_origFUND] = em_world[!,:worldem_origFUND] ./ em_world[!,:worldpop_origFUND] .* 10^6

em_world_p = em_world[(map(x->mod(x,10)==0,em_world[:,:year])),:]
em_world_stack = stack(em_world_p,[:worldempc_sspFUND,:worldempc_migFUND,:worldempc_origFUND],[:scen,:year])
rename!(em_world_stack,:variable => :worldempc_type, :value => :worldempc)
data_ssp = em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldempc_type != :worldempc_origFUND) 
data_fund = em_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldempc_type == :worldempc_origFUND) 
@vlplot()+@vlplot(
    width=300, height=250,data=data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global emissions per capita for FUND with original SSP and Mig-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldempc_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data=data_ssp,x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldempc_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldempc_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions/", "empc_world_mitig.png"))


# Compare income in Mig-FUND for different border policy scenarios
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

em_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_migFUND_cb] = em_migFUND_cb
em_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_migFUND_ob] = em_migFUND_ob
em_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:emissions,:emission][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:em_migFUND_2w] = em_migFUND_2w
pop_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_migFUND_cb] = pop_migFUND_cb
pop_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_migFUND_ob] = pop_migFUND_ob
pop_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
em[:,:pop_migFUND_2w] = pop_migFUND_2w

em[!,:empc_migFUND_cb] = em[!,:em_migFUND_cb] ./ em[!,:pop_migFUND_cb] .* 10^6           # Emissions in MtCO2
em[!,:empc_migFUND_ob] = em[!,:em_migFUND_ob] ./ em[!,:pop_migFUND_ob] .* 10^6
em[!,:empc_migFUND_2w] = em[!,:em_migFUND_2w] ./ em[!,:pop_migFUND_2w] .* 10^6

em_p = em[(map(x->mod(x,10)==0,em[:,:year])),:]
rename!(em_p, :empc_migFUND => :empc_currentborders, :empc_migFUND_cb => :empc_closedborders, :empc_migFUND_ob => :empc_moreopen, :empc_migFUND_2w => :empc_bordersnorthsouth)
rename!(em_p, :em_migFUND => :em_currentborders, :em_migFUND_cb => :em_closedborders, :em_migFUND_ob => :em_moreopen, :em_migFUND_2w => :em_bordersnorthsouth)

em_all = stack(em_p, [:em_currentborders,:em_closedborders,:em_moreopen,:em_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(em_all, :variable => :em_type, :value => :em)
for r in regions
    em_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> @vlplot() + @vlplot(
        width=300, height=250, 
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"em:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Emissions of region ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"em_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"em:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "em_type:o"
    ) |> save(joinpath(@__DIR__, "../results/emissions/", string("em_", r, "_borders_mitig.png")))
end

empc_all = stack(em_p, [:empc_currentborders,:empc_closedborders,:empc_moreopen,:empc_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(empc_all, :variable => :empc_type, :value => :empc)
for r in regions
    empc_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> @vlplot()+@vlplot(
        width=300, height=250,
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"empc:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Emissions per capita of region ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"empc_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"empc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "empc_type:o"
    ) |> save(joinpath(@__DIR__, "../results/emissions/", string("empc_", r, "_borders_mitig.png")))
end

em_world = by(em,[:year,:scen],d->(worldem_migFUND=sum(d.em_migFUND),worldem_migFUND_cb=sum(d.em_migFUND_cb),worldem_migFUND_ob=sum(d.em_migFUND_ob),worldem_migFUND_2w=sum(d.em_migFUND_2w)))

worldpop_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_migFUND_cb] = worldpop_migFUND_cb
worldpop_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_migFUND_ob] = worldpop_migFUND_ob
worldpop_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
em_world[:,:worldpop_migFUND_2w] = worldpop_migFUND_2w

em_world[:,:worldempc_migFUND_cb] = em_world[!,:worldem_migFUND_cb] ./ em_world[!,:worldpop_migFUND_cb] .* 10^6  
em_world[:,:worldempc_migFUND_ob] = em_world[!,:worldem_migFUND_ob] ./ em_world[!,:worldpop_migFUND_ob] .* 10^6
em_world[:,:worldempc_migFUND_2w] = em_world[!,:worldem_migFUND_2w] ./ em_world[!,:worldpop_migFUND_2w] .* 10^6

em_world_p = em_world[(map(x->mod(x,10)==0,em_world[:,:year])),:]
rename!(em_world_p, :worldempc_migFUND => :worldempc_currentborders, :worldempc_migFUND_cb => :worldempc_closedborders, :worldempc_migFUND_ob => :worldempc_moreopen, :worldempc_migFUND_2w => :worldempc_bordersnorthsouth)
rename!(em_world_p, :worldem_migFUND => :worldem_currentborders, :worldem_migFUND_cb => :worldem_closedborders, :worldem_migFUND_ob => :worldem_moreopen, :worldem_migFUND_2w => :worldem_bordersnorthsouth)

em_world_stack = stack(em_world_p,[:worldem_currentborders,:worldem_closedborders,:worldem_moreopen,:worldem_bordersnorthsouth],[:scen,:year])
rename!(em_world_stack,:variable => :worldem_type, :value => :worldem)
em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
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
) |> save(joinpath(@__DIR__, "../results/emissions/", "em_world_borders_mitig.pdf"))

em_world_stack = stack(em_world_p,[:worldempc_currentborders,:worldempc_closedborders,:worldempc_moreopen,:worldempc_bordersnorthsouth],[:scen,:year])
rename!(em_world_stack,:variable => :worldempc_type, :value => :worldempc)
em_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global emissions per capita for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldempc_type:o", scale={range=["circle","triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldempc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldempc_type:o"
) |> save(joinpath(@__DIR__, "../results/emissions/", "empc_world_borders_mitig.png"))


# Look at empc for different border policies
empc_all = stack(
    rename(em, :empc_migFUND => :empc_currentborders, :empc_migFUND_cb => :empc_overallclosed, :empc_migFUND_ob => :empc_bordersmoreopen, :empc_migFUND_2w => :empc_northsouthclosed), 
    [:empc_currentborders,:empc_overallclosed,:empc_bordersmoreopen,:empc_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(empc_all, :variable => :empc_type, :value => :empc)
for s in ssps
    empc_all |> @filter(_.year >= 2010 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"empc:q", title = nothing, axis={labelFontSize=16}},
        color={"empc_type:o",scale={scheme=:darkgreen},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/emissions/", string("empc_",s,"_mitig.png")))
end
empc_all[!,:scen_empc_type] = [string(empc_all[i,:scen],"_",SubString(string(empc_all[i,:empc_type]),4)) for i in 1:size(empc_all,1)]
empc_all |> @filter(_.year >= 2010 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"empc:q", title = nothing, axis={labelFontSize=16}},
    title = "Emissions per capita for world regions, SSP narratives and various border policies",
    color={"scen_empc_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/emissions/", string("empc_mitig.png")))


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"))
em_maps = join(em, isonum_fundregion, on = :fundregion, kind = :left)
em_maps[!,:emdiff_closedborders] = (em_maps[!,:em_migFUND_cb] ./ em_maps[!,:em_migFUND] .- 1) .* 100
em_maps[!,:emdiff_moreopen] = (em_maps[!,:em_migFUND_ob] ./ em_maps[!,:em_migFUND] .- 1) .* 100
em_maps[!,:emdiff_bordersnorthsouth] = (em_maps[!,:em_migFUND_2w] ./ em_maps[!,:em_migFUND] .- 1) .* 100
em_maps[!,:empcdiff_closedborders] = (em_maps[!,:empc_migFUND_cb] ./ em_maps[!,:empc_migFUND] .- 1) .* 100
em_maps[!,:empcdiff_moreopen] = (em_maps[!,:empc_migFUND_ob] ./ em_maps[!,:empc_migFUND] .- 1) .* 100
em_maps[!,:empcdiff_bordersnorthsouth] = (em_maps[!,:empc_migFUND_2w] ./ em_maps[!,:empc_migFUND] .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:em_migFUND)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Emissions levels by 2100 for current borders, ", s),fontSize=24}, 
        color = {:em_migFUND, type=:quantitative, scale={scheme=:greens,domain=[-1000,9000]}, legend={title=string("MtCO2"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("em_currentborders_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:emdiff,:_closedborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Closed borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:emdiff,:_closedborders)), type=:quantitative, scale={domain=[-20,20], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("emdiff",:_closedborders,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:emdiff,:_moreopen)]}}],
        projection={type=:naturalEarth1}, title = {text=string("More open borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:emdiff,:_moreopen)), type=:quantitative, scale={domain=[-20,20], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("emdiff",:_moreopen,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:emdiff,:_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, title = {text=string("North/South borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:emdiff,:_bordersnorthsouth)), type=:quantitative, scale={domain=[-20,20], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("emdiff",:_bordersnorthsouth,"_", s, "_mitig.png")))
end

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:empc_migFUND)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Emissions per capita levels by 2100 for current borders, ", s),fontSize=24}, 
        color = {:empc_migFUND, type=:quantitative, scale={scheme=:greens,domain=[-5,25]}, legend={title=string("MtCO2/cap"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("empc_currentborders_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:empcdiff,:_closedborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Closed borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:empcdiff,:_closedborders)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("empcdiff",:_closedborders,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:empcdiff,:_moreopen)]}}],
        projection={type=:naturalEarth1}, title = {text=string("More open borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:empcdiff,:_moreopen)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("empcdiff",:_moreopen,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, em_maps), key=:isonum, fields=[string(:empcdiff,:_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, title = {text=string("North/South borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:empcdiff,:_bordersnorthsouth)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("empcdiff",:_bordersnorthsouth,"_", s, "_mitig.png")))
end

