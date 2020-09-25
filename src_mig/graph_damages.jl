using DelimitedFiles, CSV, VegaLite, VegaDatasets, FileIO, FilePaths
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
dam_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:damages_sspFUND] = dam_sspFUND
damages_origFUND = vcat(collect(Iterators.flatten(m_fund[:impactaggregation,:loss][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
damages[:,:damages_origFUND] = damages_origFUND

damages_p = damages[(map(x->mod(x,10)==0,damages[:,:year])),:]

dam_all = stack(damages_p, [:damages_sspFUND,:damages_migFUND,:damages_origFUND], [:scen, :fundregion, :year])
rename!(dam_all, :variable => :damages_type, :value => :damages)
for r in regions
    data_ssp = dam_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.damages_type != :damages_origFUND) 
    data_fund = dam_all[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.damages_type == :damages_origFUND) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp, 
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damages:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Damages of region ",r," for FUND with original SSP and Mig-FUND"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"damages_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damages:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "damages_type:o"
    ) + @vlplot(
        data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
        x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damages:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
        detail = "damages_type:o"
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("damages_", r, "_mitig.png")))
end
dam_world = by(damages,[:year,:scen],d->(worlddamages_sspFUND=sum(d.damages_sspFUND),worlddamages_migFUND=sum(d.damages_migFUND),worlddamages_origFUND=sum(d.damages_origFUND)))
dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
dam_world_stack = stack(dam_world_p,[:worlddamages_sspFUND,:worlddamages_migFUND,:worlddamages_origFUND],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamages_type, :value => :worlddamages)
data_ssp = dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamages_type != :worlddamages_origFUND) 
data_fund = dam_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamages_type == :worlddamages_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data = data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages for FUND with original SSP and Mig-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamages_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamages_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worlddamages_type:o"
) |> save(joinpath(@__DIR__, "../results/damages/", "damages_world_mitig.png"))


gdp_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_migFUND] = gdp_migFUND
gdp_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
damages[:,:gdp_sspFUND] = gdp_sspFUND
gdp_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
damages[:,:gdp_origFUND] = gdp_origFUND
damages[:,:damgdp_migFUND] = damages[:,:damages_migFUND] ./ (damages[:,:gdp_migFUND] .* 10^9)
damages[:,:damgdp_sspFUND] = damages[:,:damages_sspFUND] ./ (damages[:,:gdp_sspFUND] .* 10^9)
damages[:,:damgdp_origFUND] = damages[:,:damages_origFUND] ./ (damages[:,:gdp_origFUND] .* 10^9)

damages_p = damages[(map(x->mod(x,10)==0,damages[:,:year])),:]

damgdp_all = stack(damages_p, [:damgdp_sspFUND,:damgdp_migFUND,:damgdp_origFUND], [:scen, :fundregion, :year])
rename!(damgdp_all, :variable => :damgdp_type, :value => :damgdp)
for r in regions
    data_ssp = damgdp_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.damgdp_type != :damgdp_origFUND) 
    data_fund = damgdp_all[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.damgdp_type == :damgdp_origFUND) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp,
        mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damgdp:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Damages as share of GDP of region ",r," for FUND with original SSP and Mig-FUND"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"damgdp_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "damgdp_type:o"
    ) + @vlplot(
        data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
        x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damgdp:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
        detail = "damgdp_type:o"
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("damgdp_", r, "_mitig.png")))
end

damages |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:damgdp_sspFUND, :damgdp_migFUND]}
    ) + @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/damages/", "damgdp_mig_SSP2_mitig.png"))

worldgdp_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_migFUND] = worldgdp_migFUND
worldgdp_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp2[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp3[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp4[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp5[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_sspFUND] = worldgdp_sspFUND
worldgdp_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
dam_world[:,:worldgdp_origFUND] = worldgdp_origFUND
dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
dam_world_p[:,:worlddamgdp_migFUND] = dam_world_p[:,:worlddamages_migFUND] ./ (dam_world_p[:,:worldgdp_migFUND] .* 10^9)
dam_world_p[:,:worlddamgdp_sspFUND] = dam_world_p[:,:worlddamages_sspFUND] ./ (dam_world_p[:,:worldgdp_sspFUND] .* 10^9)
dam_world_p[:,:worlddamgdp_origFUND] = dam_world_p[:,:worlddamages_origFUND] ./ (dam_world_p[:,:worldgdp_origFUND] .* 10^9)
dam_world_stack = stack(dam_world_p,[:worlddamgdp_sspFUND,:worlddamgdp_migFUND,:worlddamgdp_origFUND],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamgdp_type, :value => :worlddamgdp)
data_ssp = dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamgdp_type != :worlddamgdp_origFUND) 
data_fund = dam_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worlddamgdp_type == :worlddamgdp_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data=data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages as share of GDP for FUND with original SSP and Mig-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamgdp_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data=data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamgdp_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worlddamgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/damages/", "damgdp_world_mitig.png"))


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

damages_p = damages[(map(x->mod(x,10)==0,damages[:,:year])),:]

dam_all = stack(damages_p, [:dam_currentborders,:dam_closedborders,:dam_moreopen,:dam_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(dam_all, :variable => :damages_type, :value => :damages)
for r in regions
    dam_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> @vlplot() + @vlplot(
        width=300, height=250, 
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damages:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Damages of region ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"damages_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damages:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "damages_type:o"
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("damages_", r, "_borders_mitig.png")))
end

damgdp_all = stack(damages_p, [:damgdp_currentborders,:damgdp_closedborders, :damgdp_moreopen,:damgdp_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(damgdp_all, :variable => :damgdp_type, :value => :damgdp)
for r in regions
    damgdp_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> @vlplot() + @vlplot(
        width=300, height=250, 
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damgdp:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Damages as share of GDP of region ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"damgdp_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"damgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "damgdp_type:o"
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("damgdp_", r, "_borders_mitig.png")))
end

rename!(damages, :damages_origFUND => :dam_origFUND, :damages_sspFUND => :dam_sspFUND)

dam_world = by(damages,[:year,:scen],d->(worlddam_sspFUND=sum(d.dam_sspFUND),worlddam_currentborders=sum(d.dam_currentborders),worlddam_origFUND=sum(d.dam_origFUND),worlddam_closedborders=sum(d.dam_closedborders),worlddam_moreopen=sum(d.dam_moreopen),worlddam_bordersnorthsouth=sum(d.dam_bordersnorthsouth)))
dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
dam_world_stack = stack(dam_world_p,[:worlddam_currentborders,:worlddam_closedborders,:worlddam_moreopen,:worlddam_bordersnorthsouth],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamages_type, :value => :worlddamages)
dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot() + @vlplot(
    width=300, height=250, 
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamages_type:o", scale={range=["circle","triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamages:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamages_type:o"
) |> save(joinpath(@__DIR__, "../results/damages/", "damages_world_borders_mitig.png"))

worldgdp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_migFUND_cb] = worldgdp_migFUND_cb
worldgdp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_migFUND_ob] = worldgdp_migFUND_ob
worldgdp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
dam_world[:,:worldgdp_migFUND_2w] = worldgdp_migFUND_2w

dam_world_p = dam_world[(map(x->mod(x,10)==0,dam_world[:,:year])),:]
rename!(dam_world_p, :worldgdp_migFUND => :worldgdp_currentborders, :worldgdp_migFUND_cb => :worldgdp_closedborders, :worldgdp_migFUND_ob => :worldgdp_moreopen, :worldgdp_migFUND_2w => :worldgdp_bordersnorthsouth)

dam_world_p[:,:worlddamgdp_currentborders] = dam_world_p[:,:worlddam_currentborders] ./ (dam_world_p[:,:worldgdp_currentborders] .* 10^9)
dam_world_p[:,:worlddamgdp_closedborders] = dam_world_p[:,:worlddam_closedborders] ./ (dam_world_p[:,:worldgdp_closedborders] .* 10^9)
dam_world_p[:,:worlddamgdp_moreopen] = dam_world_p[:,:worlddam_moreopen] ./ (dam_world_p[:,:worldgdp_moreopen] .* 10^9)
dam_world_p[:,:worlddamgdp_bordersnorthsouth] = dam_world_p[:,:worlddam_bordersnorthsouth] ./ (dam_world_p[:,:worldgdp_bordersnorthsouth] .* 10^9)

dam_world_stack = stack(dam_world_p,[:worlddamgdp_currentborders,:worlddamgdp_closedborders,:worlddamgdp_moreopen,:worlddamgdp_bordersnorthsouth],[:scen,:year])
rename!(dam_world_stack,:variable => :worlddamgdp_type, :value => :worlddamgdp)
dam_world_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot() + @vlplot(
    width=300, height=250, 
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global damages as share of GDP for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worlddamgdp_type:o", scale={range=["circle","triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worlddamgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worlddamgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/damages/", "damgdp_world_borders_mitig.png"))


# Look at regional contributions to damages for original FUND, FUND with original SSP, and Mig-FUND with SSP scenarios zero migration
reg_dam = join(damages[:,[:year, :scen, :fundregion, :dam_currentborders, :dam_sspFUND, :dam_origFUND, :dam_closedborders, :dam_moreopen, :dam_bordersnorthsouth]], dam_world_p[:,[:year, :scen, :worlddam_sspFUND, :worlddam_currentborders, :worlddam_origFUND, :worlddam_closedborders, :worlddam_moreopen, :worlddam_bordersnorthsouth]], on = [:year,:scen])
reg_dam[:,:regsharedam_origFUND] = reg_dam[:,:dam_origFUND] ./ reg_dam[:,:worlddam_origFUND]
reg_dam[:,:regsharedam_sspFUND] = reg_dam[:,:dam_sspFUND] ./ reg_dam[:,:worlddam_sspFUND]
reg_dam[:,:regsharedam_migFUND] = reg_dam[:,:dam_currentborders] ./ reg_dam[:,:worlddam_currentborders]
reg_dam[:,:regsharedam_currentborders] = reg_dam[:,:dam_currentborders] ./ reg_dam[:,:worlddam_currentborders]
reg_dam[:,:regsharedam_closedborders] = reg_dam[:,:dam_closedborders] ./ reg_dam[:,:worlddam_closedborders]
reg_dam[:,:regsharedam_moreopen] = reg_dam[:,:dam_moreopen] ./ reg_dam[:,:worlddam_moreopen]
reg_dam[:,:regsharedam_bordersnorthsouth] = reg_dam[:,:dam_bordersnorthsouth] ./ reg_dam[:,:worlddam_bordersnorthsouth]

reg_dam |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300,
    row = {"scen:n", axis=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharedam_origFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of damages for FUND with original scenarios"
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_origFUND_mitig.png"))

reg_dam |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharedam_sspFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of damages for FUND with SSP scenarios"
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_sspFUND_mitig.png"))

reg_dam |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharedam_migFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of damages for Mig-FUND"
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_migFUND_mitig.png"))

# Just for SSP2
reg_dam |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:regsharedam_sspFUND, :regsharedam_migFUND]}
) + @vlplot(
    :area, width=300, 
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, stack=:normalize, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_mig_SSP2_mitig.png"))

# Look at regional contributions to damages for Mig-FUND with various border policies
reg_dam |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharedam_currentborders:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of damages for current borders"
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_currentborders_mitig.png"))

reg_dam |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharedam_closedborders:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of damages for closed borders"
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_closedborders_mitig.png"))

reg_dam |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharedam_moreopen:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of damages for more open borders"
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_moreopen_mitig.png"))

reg_dam |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharedam_bordersnorthsouth:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of damages for closed borders between North and South"
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_bordersnorthsouth_mitig.png"))

# Just for SSP2
reg_dam |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:regsharedam_currentborders, :regsharedam_closedborders]}
) + @vlplot(
    :area, width=300, 
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, stack=:normalize, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_borders_cc_SSP2_mitig.png"))
reg_dam |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:regsharedam_moreopen, :regsharedam_bordersnorthsouth]}
) + @vlplot(
    :area, width=300, 
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, stack=:normalize, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/damages/", "regdam_borders_o2_SSP2_mitig.png"))


# Plot composition of damages per impact for each border policy, SSP and region
dam_impact = reg_dam[:,1:9]
dam_impact[!,:dam_migFUND] = dam_impact[!,:dam_currentborders]
for imp in [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost]
    imp_curr = vcat(
        collect(Iterators.flatten(m_ssp1_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_currentborders"))] = imp_curr
    imp_closed = vcat(
        collect(Iterators.flatten(m_ssp1_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_closedborders"))] = imp_closed
    imp_more = vcat(
        collect(Iterators.flatten(m_ssp1_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_moreopen"))] = imp_more
    imp_ns = vcat(
        collect(Iterators.flatten(m_ssp1_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nomig_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
    )
    dam_impact[:,Symbol(string(imp,"_bordersnorthsouth"))] = imp_ns
end
# We count as climate change damage only those attributed to differences in income resulting from climate change impacts
imp_curr = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_curr = vcat(
    collect(Iterators.flatten(m_ssp1_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_currentborders"))] = imp_curr - imp_nocc_curr
imp_closed = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_closed = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_closedborders"))] = imp_closed - imp_nocc_closed
imp_more = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_more = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
)
dam_impact[:,Symbol(string(:deadmigcost,"_moreopen"))] = imp_more - imp_nocc_more
imp_ns = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_ns = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1960):10:MimiFUND.getindexfromyear(2100),:]))
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
dam_impact_stacked = join(dam_impact_stacked, regions_fullname, on=:fundregion)
for r in regions
    for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
        dam_impact_stacked |> @filter(_.year >= 1990 && _.year <= 2100 && _.borders == string(btype) && _.fundregion == r) |> @vlplot(
            :area, width=300, 
            x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
            y={:impact_dam, aggregate = :sum, type = :quantitative, axis={labelFontSize=16}},
            row = {"scen:n", axis={labelFontSize=16}, title=nothing},
            color={"impact:n",scale={scheme="category20c"}},
        ) |> save(joinpath(@__DIR__, "../results/damages/", string("impdam_",r,btype,"_mitig.png")))
    end
end

for s in ssps
    dam_impact_stacked |> @filter(_.year ==2100 && _.scen == s && _.borders == "_currentborders") |> @vlplot(
        mark={:bar}, width=350, height=300,
        x={"fundregion:o", axis={labelFontSize=16, labelAngle=-90}, ticks=false, domain=false, title=nothing, minExtent=80, scale={paddingInner=0.2,paddingOuter=0.2}},
        y={"impact_dam:q", aggregate = :sum, stack = true, title = "Billion USD2005", axis={titleFontSize=18, labelFontSize=16}},
        color={"impact:n",scale={scheme="category20c"},legend={title=string("Impact type"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=220}},
        resolve = {scale={y=:independent}}, title={text=string("Damages in 2100, current borders, ", s), fontSize=20}
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("impdam_",s,"_mitig.png")))
end


# Calculate the proportion of migrants moving from a less to a more exposed region (in terms of damages/GDP)
exposed = join(move[:,1:8], rename(rename(
    move[:,1:8], 
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

exposed = join(exposed, rename(
    damages, 
    :fundregion => :origin, 
    :damgdp_currentborders => :damgdp_or_currentborders, 
    :damgdp_closedborders => :damgdp_or_closedborders, 
    :damgdp_moreopen => :damgdp_or_moreopen, 
    :damgdp_bordersnorthsouth => :damgdp_or_bordersnorthsouth
)[:,[:year,:scen,:origin,:damgdp_or_currentborders,:damgdp_or_closedborders,:damgdp_or_moreopen,:damgdp_or_bordersnorthsouth]], on = [:year,:scen,:origin])
exposed = join(exposed, rename(
    damages, 
    :fundregion => :destination, 
    :damgdp_currentborders => :damgdp_dest_currentborders, 
    :damgdp_closedborders => :damgdp_dest_closedborders, 
    :damgdp_moreopen => :damgdp_dest_moreopen, 
    :damgdp_bordersnorthsouth => :damgdp_dest_bordersnorthsouth
)[:,[:year,:scen,:destination,:damgdp_dest_currentborders,:damgdp_dest_closedborders,:damgdp_dest_moreopen,:damgdp_dest_bordersnorthsouth]], on = [:year,:scen,:destination])

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed[!,Symbol(string(:exposure,btype))] = [exposed[i,Symbol(string(:move_net,btype))] >0 ? (exposed[i,Symbol(string(:damgdp_dest,btype))] > exposed[i,Symbol(string(:damgdp_or,btype))] ? "increase" : "decrease") : (exposed[i,Symbol(string(:move_net,btype))] <0 ? ("") : "nomove") for i in 1:size(exposed,1)]
end

index_r = DataFrame(index=1:16,region=regions)
exposed = join(exposed,rename(index_r,:region=>:origin,:index=>:index_or),on=:origin)
exposed = join(exposed,rename(index_r,:region=>:destination,:index=>:index_dest),on=:destination)

exposure_currentborders = by(exposed, [:year,:scen,:exposure_currentborders], d -> (popexpo=sum(d.move_net_currentborders)))
exposure_closedborders = by(exposed, [:year,:scen,:exposure_closedborders], d -> (popexpo=sum(d.move_net_closedborders)))
exposure_moreopen = by(exposed, [:year,:scen,:exposure_moreopen], d -> (popexpo=sum(d.move_net_moreopen)))
exposure_bordersnorthsouth = by(exposed, [:year,:scen,:exposure_bordersnorthsouth], d -> (popexpo=sum(d.move_net_bordersnorthsouth)))
rename!(exposure_currentborders,:x1=>:popmig_currentborders,:exposure_currentborders=>:exposure)
rename!(exposure_closedborders,:x1=>:popmig_closedborders,:exposure_closedborders=>:exposure)
rename!(exposure_moreopen,:x1=>:popmig_moreopen,:exposure_moreopen=>:exposure)
rename!(exposure_bordersnorthsouth,:x1=>:popmig_bordersnorthsouth,:exposure_bordersnorthsouth=>:exposure)
exposure = join(exposure_currentborders, exposure_closedborders, on = [:year,:scen,:exposure],kind=:outer)
exposure = join(exposure, exposure_moreopen, on = [:year,:scen,:exposure],kind=:outer)
exposure = join(exposure, exposure_bordersnorthsouth, on = [:year,:scen,:exposure],kind=:outer)
for name in [:popmig_currentborders,:popmig_closedborders,:popmig_moreopen,:popmig_bordersnorthsouth]
    for i in 1:size(exposure,1)
        if ismissing(exposure[i,name])
            exposure[i,name] = 0.0
        end
    end
end
sort!(exposure,[:scen,:year,:exposure])
exposure[.&(exposure[!,:year].==2100),:]

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed[!,Symbol(string(:damgdp_diff,btype))] = exposed[!,Symbol(string(:damgdp_dest,btype))] .- exposed[!,Symbol(string(:damgdp_or,btype))]
end
for d in [2100,2100]
    for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
        exposed |> @filter(_.year == d) |> @vlplot(
            :bar, width=300, 
            x={Symbol(string(:damgdp_diff,btype)), type=:ordinal, bin={step = 0.02}, axis={labelFontSize=16}},
            y={Symbol(string(:move,btype)), aggregate=:sum, axis={labelFontSize=16}, title=nothing},
            row = {"scen:n", axis=nothing},
            color={"origin:o",scale={scheme="tableau20"}}
        ) |> save(joinpath(@__DIR__, "../results/damages/", string("exposure",btype,"_",d,"_mitig.png")))
    end
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
for i in 1:size(exposed_all,1)
    if exposed_all[i,:move] == 0
        exposed_all[i,:damgdp_diff] = 0
    end
end
exposed_all = join(exposed_all, rename(regions_fullname, :fundregion => :origin, :regionname => :originname), on= :origin)
exposed_all = join(exposed_all, rename(regions_fullname, :fundregion => :destination, :regionname => :destinationname), on= :destination)
for s in ssps
    exposed_all |> @filter(_.scen == s) |> @vlplot(
        mark={:point, size=60}, width=300, columns=8, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
        x={"damgdp_diff:q", axis={labelFontSize=16}, title="Change in Exposure, % point", titleFontSize=20},
        y={"move:q", title = "Number of Emigrants", axis={labelFontSize=16}, titleFontSize=20},
        color={"btype:o",scale={scheme=:darkmulti},legend={title=string("Exposure Change, ",s), titleFontSize=18, titleLimit=220, symbolSize=60, labelFontSize=20, labelLimit=220, offset=2}},
        shape="btype:o",
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("exposure_",s,"_mitig.png")))
end
exposed_all[!,:scen_btype] = [string(exposed_all[i,:scen],"_",exposed_all[i,:btype]) for i in 1:size(exposed_all,1)]
exposed_all |> @vlplot(
    mark={:point, size=60}, width=300, height=250, columns=8, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    x={"damgdp_diff:q", axis={labelFontSize=16}, title="Change in Exposure, % point", titleFontSize=20},
    y={"move:q", title = "Number of Emigrants", axis={labelFontSize=16}, titleFontSize=20},
    color={"scen_btype:o",scale={scheme=:category20c},legend={title=string("Exposure Change"), titleFontSize=18, titleLimit=220, symbolSize=60, labelFontSize=20, labelLimit=220, offset=2}},
    shape="scen_btype:o",
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages/", string("exposure_mitig.png")))

exposed_all[(exposed_all[:,:btype].!="overallclosed"),:] |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_diff:q", axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    size= {"move:q", legend=nothing},
    color={"btype:o",scale={scheme=:dark2},legend={title=string("Migrant outflows"), titleFontSize=24, titleLimit=240, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages/", string("exposure_allscen_mitig.pdf")))

exp_sum = by(exposed_all, [:scen,:origin,:btype], d->sum(d.move))
exposed_all = join(exposed_all, rename(exp_sum, :x1 => :leave), on=[:scen,:origin,:btype])
exposed_all[!,:move_share] = exposed_all[!,:move] ./ exposed_all[!,:leave]
for i in 1:size(exposed_all,1) ; if exposed_all[i,:move] == 0.0 && exposed_all[i,:leave] == 0 ; exposed_all[i,:move_share] = 0 end end
exposed_average = by(exposed_all, [:scen,:origin,:originname,:btype,:scen_btype], d->sum(d.damgdp_diff .* d.move_share))
rename!(exposed_average, :x1 => :damgdp_diff_av)
exposed_average |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_diff_av:q", scale={domain=[-0.08,0.08]}, axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    color={"btype:o",scale={scheme=:darkmulti},legend={title=string("Emigrants"), titleFontSize=24, titleLimit=220, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages/", string("exposure_averaged_mitig.png")))

exposed_average |> @filter(_.scen == "SSP2" && (_.origin == "MAF" || _.origin == "CAM" || _.origin == "SEA" || _.origin == "SAS" || _.origin == "SSA")) |> @vlplot(
    mark={:point, size=80}, width=400, 
    y={"damgdp_diff_av:q", scale={domain=[-0.05,0.05]}, axis={labelFontSize=16, titleFontSize=16}, title="Change in Exposure, % pt"},
    x={"originname:o", title = nothing, axis={labelFontSize=16,labelAngle=-60}},
    color={"btype:o",scale={scheme=:darkmulti},legend={title=string("Emigrants"), titleFontSize=16, titleLimit=220, symbolSize=100, labelFontSize=16, labelLimit=260, offset=10}},
    shape="btype:o"
) |> save(joinpath(@__DIR__, "../results/damages/", string("exposure_averaged_select_mitig.png")))

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    damages|> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, 
        x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
        y={Symbol(string(:damgdp,btype)), type=:quantitative, axis={labelFontSize=16}, title=nothing},
        row = {"scen:n", axis=nothing},
        color={"fundregion:o",scale={scheme="tableau20"}}
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("regdamgdp",btype,"_mitig.png")))
end


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"))

damages_maps = join(damages, isonum_fundregion, on = :fundregion, kind = :left)
damages_maps[!,:damdiff_closedborders] = (damages_maps[!,:dam_closedborders] ./ map(x->abs(x), damages_maps[!,:dam_currentborders]) .- 1) .* 100
damages_maps[!,:damdiff_moreopen] = (damages_maps[!,:dam_moreopen] ./ map(x->abs(x), damages_maps[!,:dam_currentborders]) .- 1) .* 100
damages_maps[!,:damdiff_bordersnorthsouth] = (damages_maps[!,:dam_bordersnorthsouth] ./ map(x->abs(x), damages_maps[!,:dam_currentborders]) .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damages_maps), key=:isonum, fields=[string(:dam_currentborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Damages, current borders, 2100, ", s),fontSize=24}, 
        color = {:dam_currentborders, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-10^12,10^12]}, legend={title=string("USD2005"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("dam_currentborders_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damages_maps), key=:isonum, fields=[string(:damdiff,:_closedborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Closed borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:damdiff,:_closedborders)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damdiff",:_closedborders,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damages_maps), key=:isonum, fields=[string(:damdiff,:_moreopen)]}}],
        projection={type=:naturalEarth1}, title = {text=string("More open borders, 2100, ", s),fontSize=20}, 
        color = {Symbol(string(:damdiff,:_moreopen)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damdiff",:_moreopen,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damages_maps), key=:isonum, fields=[string(:damdiff,:_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, title = {text=string("North/South borders, 2100, ", s),fontSize=20}, 
        color = {Symbol(string(:damdiff,:_bordersnorthsouth)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damdiff",:_bordersnorthsouth,"_", s, "_mitig.png")))
end


damgdp_maps = join(damages, isonum_fundregion, on = :fundregion, kind = :left)
for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    damgdp_maps[!,Symbol(:damgdp,btype)] .*= 100
end
damgdp_maps[!,:damgdpdiff_closedborders] = (damgdp_maps[!,:damgdp_closedborders] ./ map(x->abs(x), damgdp_maps[!,:damgdp_currentborders]) .- 1) .* 100
damgdp_maps[!,:damgdpdiff_moreopen] = (damgdp_maps[!,:damgdp_moreopen] ./ map(x->abs(x), damgdp_maps[!,:damgdp_currentborders]) .- 1) .* 100
damgdp_maps[!,:damgdpdiff_bordersnorthsouth] = (damgdp_maps[!,:damgdp_bordersnorthsouth] ./ map(x->abs(x), damgdp_maps[!,:damgdp_currentborders]) .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_currentborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, current borders, 2100, ", s),fontSize=24}, 
        color = {:damgdp_currentborders, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdp_currentborders_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_closedborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, closed borders, 2100, ", s),fontSize=24}, 
        color = {:damgdp_closedborders, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdp_closedborders_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_moreopen)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, more open borders, 2100, ", s),fontSize=24}, 
        color = {:damgdp_moreopen, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdp_moreopen_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdp_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Exposure, North/South borders, 2100, ", s),fontSize=24}, 
        color = {:damgdp_bordersnorthsouth, type=:quantitative, scale={scheme=:pinkyellowgreen,domain=[-5,5]}, legend={title=string("% GDP"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdp_bordersnorthsouth_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdpdiff,:_closedborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Closed borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:damgdpdiff,:_closedborders)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdpdiff",:_closedborders,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdpdiff,:_moreopen)]}}],
        projection={type=:naturalEarth1}, title = {text=string("More open borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:damgdpdiff,:_moreopen)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdpdiff",:_moreopen,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, damgdp_maps), key=:isonum, fields=[string(:damgdpdiff,:_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, title = {text=string("North/South borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:damgdpdiff,:_bordersnorthsouth)), type=:quantitative, scale={domain=[-200,200], scheme=:blueorange}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("damgdpdiff",:_bordersnorthsouth,"_", s, "_mitig.png")))
end

# Register regional damages for period 1990-2015. We focus on SSP2 and current borders (virtually no difference with other scenarios)
damcalib = damages[.&(damages[:,:year].>=1990,damages[:,:year].<=2015,map(x->mod(x,5)==0,damages[:,:year]),damages[:,:scen].=="SSP2"),[:year,:fundregion,:damgdp_currentborders]]
CSV.write(joinpath(@__DIR__,"../input_data/damcalib.csv"),damcalib;writeheader=false)