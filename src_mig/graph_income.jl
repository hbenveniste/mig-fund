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


# Compare income in absolute terms and in per capita in Mig-FUND and in FUND with SSP
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

income = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)

gdp_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_migFUND] = gdp_migFUND
gdp_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_sspFUND] = gdp_sspFUND
gdp_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
income[:,:gdp_origFUND] = gdp_origFUND

income_p = income[(map(x->mod(x,10)==0,income[:,:year])),:]

gdp_all = stack(income_p, [:gdp_sspFUND,:gdp_migFUND,:gdp_origFUND], [:scen, :fundregion, :year])
rename!(gdp_all, :variable => :gdp_type, :value => :gdp)
for r in regions
    data_ssp = gdp_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.gdp_type != :gdp_origFUND) 
    data_fund = gdp_all[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.gdp_type == :gdp_origFUND) 
    @vlplot() + @vlplot(
        width=300, height=250, data = data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gdp:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Income of region ",r," for FUND with original SSP and Mig-FUND"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"gdp_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "gdp_type:o"
    ) + @vlplot(
        data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
        x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gdp:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
        detail = "gdp_type:o"
    ) |> save(joinpath(@__DIR__, "../results/income/", string("gdp_", r, "_mitig.png")))
end

income_world = by(income,[:year,:scen],d->(worldgdp_sspFUND=sum(d.gdp_sspFUND),worldgdp_migFUND=sum(d.gdp_migFUND),worldgdp_origFUND=sum(d.gdp_origFUND)))
income_world_p = income_world[(map(x->mod(x,10)==0,income_world[:,:year])),:]
income_world_stack = stack(income_world_p,[:worldgdp_sspFUND,:worldgdp_migFUND,:worldgdp_origFUND],[:scen,:year])
rename!(income_world_stack,:variable => :worldgdp_type, :value => :worldgdp)
data_ssp = income_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldgdp_type != :worldgdp_origFUND) 
data_fund = income_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldgdp_type == :worldgdp_origFUND) 
@vlplot() + @vlplot(
    width=300, height=250, data = data_ssp,
    mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income for FUND with original SSP and Mig-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldgdp_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldgdp_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/income/", "gdp_world_mitig.png"))


ypc_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migFUND] = ypc_migFUND
ypc_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_sspFUND] = ypc_sspFUND
ypc_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*length(regions)*4))
income[:,:ypc_origFUND] = ypc_origFUND

income_p = income[(map(x->mod(x,10)==0,income[:,:year])),:]

ypc_all = stack(income_p, [:ypc_sspFUND,:ypc_migFUND,:ypc_origFUND], [:scen, :fundregion, :year])
rename!(ypc_all, :variable => :ypc_type, :value => :ypc)
for r in regions
    data_ssp = ypc_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.ypc_type != :ypc_origFUND) 
    data_fund = ypc_all[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r && _.ypc_type == :ypc_origFUND) 
    @vlplot()+@vlplot(
        width=300, height=250,data=data_ssp,
        mark={:point, size=30}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"ypc:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Income per capita of region ",r," for FUND with original SSP and Mig-FUND"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"ypc_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, data=data_ssp,x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"ypc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "ypc_type:o"
    ) + @vlplot(
        data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
        x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"ypc:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
        detail = "ypc_type:o"
    ) |> save(joinpath(@__DIR__, "../results/income/", string("ypc_", r, "_mitig.png")))
end

worldypc_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_migFUND] = worldypc_migFUND
worldypc_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp2[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp3[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp4[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp5[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_sspFUND] = worldypc_sspFUND
worldypc_origFUND = vcat(collect(Iterators.flatten(m_fund[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
income_world[:,:worldypc_origFUND] = worldypc_origFUND
income_world_p = income_world[(map(x->mod(x,10)==0,income_world[:,:year])),:]
income_world_stack = stack(income_world_p,[:worldypc_sspFUND,:worldypc_migFUND,:worldypc_origFUND],[:scen,:year])
rename!(income_world_stack,:variable => :worldypc_type, :value => :worldypc)
data_ssp = income_world_stack |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldypc_type != :worldypc_origFUND) 
data_fund = income_world_stack[:,Not(:scen)] |> @filter(_.year >= 2015 && _.year <= 2100 && _.worldypc_type == :worldypc_origFUND) 
@vlplot()+@vlplot(
    width=300, height=250,data=data_ssp,
    mark={:point, size=60}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income per capita for FUND with original SSP and Mig-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldypc_type:o", scale={range=["circle","triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data=data_ssp,x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldypc_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", aggregate=:mean,type=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "worldypc_type:o"
) |> save(joinpath(@__DIR__, "../results/income/", "ypc_world_mitig.png"))


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

gdp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_migFUND_cb] = gdp_migFUND_cb
gdp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_migFUND_ob] = gdp_migFUND_ob
gdp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:socioeconomic,:income][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:gdp_migFUND_2w] = gdp_migFUND_2w
ypc_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migFUND_cb] = ypc_migFUND_cb
ypc_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migFUND_ob] = ypc_migFUND_ob
ypc_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migFUND_2w] = ypc_migFUND_2w

income_p = income[(map(x->mod(x,10)==0,income[:,:year])),:]
rename!(income_p, :ypc_migFUND => :ypc_currentborders, :ypc_migFUND_cb => :ypc_closedborders, :ypc_migFUND_ob => :ypc_moreopen, :ypc_migFUND_2w => :ypc_bordersnorthsouth)
rename!(income_p, :gdp_migFUND => :gdp_currentborders, :gdp_migFUND_cb => :gdp_closedborders, :gdp_migFUND_ob => :gdp_moreopen, :gdp_migFUND_2w => :gdp_bordersnorthsouth)

gdp_all = stack(income_p, [:gdp_currentborders,:gdp_closedborders,:gdp_moreopen,:gdp_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(gdp_all, :variable => :gdp_type, :value => :gdp)
for r in regions
    gdp_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> @vlplot() + @vlplot(
        width=300, height=250, 
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gdp:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Income of region ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"gdp_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"gdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "gdp_type:o"
    ) |> save(joinpath(@__DIR__, "../results/income/", string("gdp_", r, "_borders_mitig.png")))
end

ypc_all = stack(income_p, [:ypc_currentborders,:ypc_closedborders,:ypc_moreopen,:ypc_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(ypc_all, :variable => :ypc_type, :value => :ypc)
for r in regions
    ypc_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> @vlplot()+@vlplot(
        width=300, height=250,
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"ypc:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Income per capita of region ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"ypc_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"ypc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "ypc_type:o"
    ) |> save(joinpath(@__DIR__, "../results/income/", string("ypc_", r, "_borders_mitig.png")))
end

worldgdp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldgdp_migFUND_cb] = worldgdp_migFUND_cb
worldgdp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldgdp_migFUND_ob] = worldgdp_migFUND_ob
worldgdp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:socioeconomic,:globalincome][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldgdp_migFUND_2w] = worldgdp_migFUND_2w
worldypc_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_migFUND_cb] = worldypc_migFUND_cb
worldypc_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_migFUND_ob] = worldypc_migFUND_ob
worldypc_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:socioeconomic,:globalypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
income_world[:,:worldypc_migFUND_2w] = worldypc_migFUND_2w

income_world_p = income_world[(map(x->mod(x,10)==0,income_world[:,:year])),:]
rename!(income_world_p, :worldypc_migFUND => :worldypc_currentborders, :worldypc_migFUND_cb => :worldypc_closedborders, :worldypc_migFUND_ob => :worldypc_moreopen, :worldypc_migFUND_2w => :worldypc_bordersnorthsouth)
rename!(income_world_p, :worldgdp_migFUND => :worldgdp_currentborders, :worldgdp_migFUND_cb => :worldgdp_closedborders, :worldgdp_migFUND_ob => :worldgdp_moreopen, :worldgdp_migFUND_2w => :worldgdp_bordersnorthsouth)

gdp_world_stack = stack(income_world_p,[:worldgdp_currentborders,:worldgdp_closedborders,:worldgdp_moreopen,:worldgdp_bordersnorthsouth],[:scen,:year])
rename!(gdp_world_stack,:variable => :worldgdp_type, :value => :worldgdp)
gdp_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income per capita for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldgdp_type:o", scale={range=["circle","triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldgdp:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldgdp_type:o"
) |> save(joinpath(@__DIR__, "../results/income/", "gdp_world_borders_mitig.png"))

income_world_stack = stack(income_world_p,[:worldypc_currentborders,:worldypc_closedborders,:worldypc_moreopen,:worldypc_bordersnorthsouth],[:scen,:year])
rename!(income_world_stack,:variable => :worldypc_type, :value => :worldypc)
income_world_stack |> @filter(_.year >= 2015 && _.year <= 2100)  |> @vlplot()+@vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global income per capita for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldypc_type:o", scale={range=["circle","triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16}, title=nothing}, y = {"worldypc:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldypc_type:o"
) |> save(joinpath(@__DIR__, "../results/income/", "ypc_world_borders_mitig.png"))

# Look at regional comparisons in ypc for original FUND, FUND with original SSP, and Mig-FUND with SSP scenarios zero migration
income |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    row = {"scen:n", axis=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"ypc_origFUND:q", axis={labelFontSize=16}, title=nothing},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional per capita GDP for FUND with original scenarios"
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_origFUND_mitig.png"))

income |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"ypc_sspFUND:q", axis={labelFontSize=16}, title=nothing},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional per capita GDP for FUND with SSP scenarios"
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_sspFUND_mitig.png"))

income |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"ypc_currentborders:q", axis={labelFontSize=16}, title=nothing},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional per capita GDP for Mig-FUND"
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_migFUND_mitig.png"))

# Per SSP
for s in ssps
    income |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == s) |> @vlplot(
        repeat={column=[:ypc_sspFUND, :ypc_migFUND]}
        ) + @vlplot(
        mark={:line, strokeWidth = 4}, width=300,
        x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
        y={field={repeat=:column}, type = :quantitative, scale={domain=[0,180000]}, axis={labelFontSize=16}},
        color={"fundregion:o",scale={scheme="tableau20"}},
    ) |> save(joinpath(@__DIR__, "../results/income/", string("regypc_mig_",s,"_mitig.png")))
end

# Look at regional comparisons in ypc for Mig-FUND with various border policies
rename!(income, :ypc_migFUND => :ypc_currentborders, :ypc_migFUND_cb => :ypc_closedborders, :ypc_migFUND_ob => :ypc_moreopen, :ypc_migFUND_2w => :ypc_bordersnorthsouth)
rename!(income, :gdp_migFUND => :gdp_currentborders, :gdp_migFUND_cb => :gdp_closedborders, :gdp_migFUND_ob => :gdp_moreopen, :gdp_migFUND_2w => :gdp_bordersnorthsouth)

income |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"ypc_currentborders:q", axis={labelFontSize=16}, title=nothing},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional per capita GDP for current borders"
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_currentborders_mitig.png"))

income |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"ypc_closedborders:q", axis={labelFontSize=16}, title=nothing},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional per capita GDP for closed borders"
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_closedborders_mitig.png"))

income |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"ypc_moreopen:q", axis={labelFontSize=16}, title=nothing},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional per capita GDP for more open borders"
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_moreopen_mitig.png"))

income |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"ypc_bordersnorthsouth:q", axis={labelFontSize=16}, title=nothing},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional per capita GDP for closed borders between North and South"
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_bordersnorthsouth_mitig.png"))

# Just for SSP2
income |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:ypc_currentborders, :ypc_closedborders]}
    ) + @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, scale={domain=[0,180000]}, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_borders_cc_SSP2_mitig.png"))
income |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:ypc_moreopen,:ypc_bordersnorthsouth]}
    ) + @vlplot(
    mark={:line, strokeWidth = 4}, width=300,
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, scale={domain=[0,180000]}, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/income/", "regypc_borders_o2_SSP2_mitig.png"))


# Look at gdp and ypc for different border policies
gdp_all = stack(
    rename(income, :gdp_closedborders => :gdp_overallclosed, :gdp_moreopen => :gdp_bordersmoreopen, :gdp_bordersnorthsouth => :gdp_northsouthclosed), 
    [:gdp_currentborders,:gdp_overallclosed,:gdp_bordersmoreopen,:gdp_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(gdp_all, :variable => :gdp_type, :value => :gdp)
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
gdp_all = join(gdp_all,regions_fullname, on=:fundregion)
for s in ssps
    gdp_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"gdp:q", title = nothing, axis={labelFontSize=16}},
        color={"gdp_type:o",scale={scheme=:darkgreen},legend={title=string("GDP levels, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("gdp_",s,"_mitig.png")))
end
gdp_all[!,:scen_gdp_type] = [string(gdp_all[i,:scen],"_",SubString(string(gdp_all[i,:gdp_type]),4)) for i in 1:size(gdp_all,1)]
gdp_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"gdp:q", title = nothing, axis={labelFontSize=16}},
    title = "Income per capita for world regions, SSP narratives and various border policies",
    color={"scen_gdp_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income/", string("gdp_mitig.png")))

ypc_all = stack(
    rename(income, :ypc_closedborders => :ypc_overallclosed, :ypc_moreopen => :ypc_bordersmoreopen, :ypc_bordersnorthsouth => :ypc_northsouthclosed), 
    [:ypc_currentborders,:ypc_overallclosed,:ypc_bordersmoreopen,:ypc_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(ypc_all, :variable => :ypc_type, :value => :ypc)
for s in ssps
    ypc_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"ypc:q", title = nothing, axis={labelFontSize=16}},
        color={"ypc_type:o",scale={scheme=:darkgreen},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("ypc_",s,"_mitig.png")))
end
ypc_all[!,:scen_ypc_type] = [string(ypc_all[i,:scen],"_",SubString(string(ypc_all[i,:ypc_type]),4)) for i in 1:size(ypc_all,1)]
ypc_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"ypc:q", title = nothing, axis={labelFontSize=16}},
    title = "Income per capita for world regions, SSP narratives and various border policies",
    color={"scen_ypc_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income/", string("ypc_mitig.png")))


# Look at regional contributions to income for original FUND, FUND with original SSP, and Mig-FUND with SSP scenarios zero migration
reg_gdp = join(income[:,[:year, :scen, :fundregion, :gdp_currentborders, :gdp_sspFUND, :gdp_origFUND, :gdp_closedborders, :gdp_moreopen, :gdp_bordersnorthsouth]], income_world_p[:,[:year, :scen, :worldgdp_sspFUND, :worldgdp_currentborders, :worldgdp_origFUND, :worldgdp_closedborders, :worldgdp_moreopen, :worldgdp_bordersnorthsouth]], on = [:year,:scen])
reg_gdp[:,:regsharegdp_origFUND] = reg_gdp[:,:gdp_origFUND] ./ reg_gdp[:,:worldgdp_origFUND]
reg_gdp[:,:regsharegdp_sspFUND] = reg_gdp[:,:gdp_sspFUND] ./ reg_gdp[:,:worldgdp_sspFUND]
reg_gdp[:,:regsharegdp_migFUND] = reg_gdp[:,:gdp_currentborders] ./ reg_gdp[:,:worldgdp_currentborders]
reg_gdp[:,:regsharegdp_currentborders] = reg_gdp[:,:gdp_currentborders] ./ reg_gdp[:,:worldgdp_currentborders]
reg_gdp[:,:regsharegdp_closedborders] = reg_gdp[:,:gdp_closedborders] ./ reg_gdp[:,:worldgdp_closedborders]
reg_gdp[:,:regsharegdp_moreopen] = reg_gdp[:,:gdp_moreopen] ./ reg_gdp[:,:worldgdp_moreopen]
reg_gdp[:,:regsharegdp_bordersnorthsouth] = reg_gdp[:,:gdp_bordersnorthsouth] ./ reg_gdp[:,:worldgdp_bordersnorthsouth]

reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300,
    row = {"scen:n", axis=nothing},
    x={"year:o", axis={labelFontSize=16}, title=nothing},
    y={"regsharegdp_origFUND:q", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of income for FUND with original scenarios"
) |> save(joinpath(@__DIR__, "../results/income/", "reggdp_origFUND_mitig.png"))

reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharegdp_sspFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of income for FUND with SSP scenarios"
) |> save(joinpath(@__DIR__, "../results/income/", "reggdp_sspFUND_mitig.png"))

reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharegdp_migFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of income for Mig-FUND"
) |> save(joinpath(@__DIR__, "../results/income/", "reggdp_migFUND_mitig.png"))

# Per SSP
for s in ssps
    reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == s) |> @vlplot(
        repeat={column=[:regsharegdp_sspFUND, :regsharegdp_migFUND]}
    ) + @vlplot(
        :area, width=300, 
        x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
        y={field={repeat=:column}, type = :quantitative, stack=:normalize, axis={labelFontSize=16}},
        color={"fundregion:o",scale={scheme="tableau20"}},
    ) |> save(joinpath(@__DIR__, "../results/income/", string("reggdp_mig_",s,"_mitig.png")))
end

# Look at regional contributions to income for Mig-FUND with various border policies
reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharegdp_currentborders:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of income for current borders"
) |> save(joinpath(@__DIR__, "../results/income/", "reggdp_currentborders_mitig.png"))

reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharegdp_closedborders:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of income for closed borders"
) |> save(joinpath(@__DIR__, "../results/income/", "reggdp_closedborders_mitig.png"))

reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharegdp_moreopen:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of income for more open borders"
) |> save(joinpath(@__DIR__, "../results/income/", "reggdp_moreopen_mitig.png"))

reg_gdp |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharegdp_bordersnorthsouth:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of income for closed borders between North and South"
) |> save(joinpath(@__DIR__, "../results/income/", "reggdp_bordersnorthsouth_mitig.png"))


# Plot heat tables and geographical maps of remittances flows in 2100 and 2100
rem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

rem_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[:,:rem_currentborders] = rem_currentborders
rem_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[:,:rem_closedborders] = rem_closedborders
rem_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[:,:rem_moreopen] = rem_moreopen
rem_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:rem][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[:,:rem_bordersnorthsouth] = rem_bordersnorthsouth

receive_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:receive_currentborders] = receive_currentborders
receive_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:receive_closedborders] = receive_closedborders
receive_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:receive_moreopen] = receive_moreopen
receive_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:receive][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:receive_bordersnorthsouth] = receive_bordersnorthsouth

send_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:send_currentborders] = send_currentborders
send_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:send_closedborders] = send_closedborders
send_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:send_moreopen] = send_moreopen
send_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:send][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:send_bordersnorthsouth] = send_bordersnorthsouth

rem = join(
    rem, 
    rename(
        income, 
        :fundregion => :origin, 
        :receive_currentborders => :receive_or_currentborders, 
        :gdp_currentborders => :gdp_or_currentborders, 
        :receive_closedborders => :receive_or_closedborders, 
        :gdp_closedborders => :gdp_or_closedborders, 
        :receive_moreopen => :receive_or_moreopen, 
        :gdp_moreopen => :gdp_or_moreopen, 
        :receive_bordersnorthsouth => :receive_or_bordersnorthsouth,
        :gdp_bordersnorthsouth => :gdp_or_bordersnorthsouth
    )[:,Not([:send_currentborders,:send_closedborders,:send_moreopen,:send_bordersnorthsouth])],
    on = [:year,:scen,:origin]
)
rem = join(
    rem, 
    rename(
        income, 
        :fundregion => :destination, 
        :send_currentborders => :send_dest_currentborders, 
        :gdp_currentborders => :gdp_dest_currentborders, 
        :send_closedborders => :send_dest_closedborders, 
        :gdp_closedborders => :gdp_dest_closedborders, 
        :send_moreopen => :send_dest_moreopen, 
        :gdp_moreopen => :gdp_dest_moreopen, 
        :send_bordersnorthsouth => :send_dest_bordersnorthsouth,
        :gdp_bordersnorthsouth => :gdp_dest_bordersnorthsouth
    )[:,Not([:receive_currentborders,:receive_closedborders,:receive_moreopen,:receive_bordersnorthsouth,:gdp_sspFUND, :gdp_origFUND, :ypc_currentborders, :ypc_sspFUND, :ypc_origFUND, :ypc_closedborders, :ypc_moreopen , :ypc_bordersnorthsouth])],
    on = [:year,:scen,:destination]
)
rem[:,:remshare_or_currentborders] = rem[:,:rem_currentborders] ./ rem[:,:receive_or_currentborders]
rem[:,:remshare_or_closedborders] = rem[:,:rem_closedborders] ./ rem[:,:receive_or_closedborders]
rem[:,:remshare_or_moreopen] = rem[:,:rem_moreopen] ./ rem[:,:receive_or_moreopen]
rem[:,:remshare_or_bordersnorthsouth] = rem[:,:rem_bordersnorthsouth] ./ rem[:,:receive_or_bordersnorthsouth]
rem[:,:remshare_dest_currentborders] = rem[:,:rem_currentborders] ./ rem[:,:send_dest_currentborders]
rem[:,:remshare_dest_closedborders] = rem[:,:rem_closedborders] ./ rem[:,:send_dest_closedborders]
rem[:,:remshare_dest_moreopen] = rem[:,:rem_moreopen] ./ rem[:,:send_dest_moreopen]
rem[:,:remshare_dest_bordersnorthsouth] = rem[:,:rem_bordersnorthsouth] ./ rem[:,:send_dest_bordersnorthsouth]
for i in 1:size(rem,1)
    if rem[i,:receive_or_currentborders] == 0 ; rem[i,:remshare_or_currentborders] = 0 end
    if rem[i,:receive_or_closedborders] == 0 ; rem[i,:remshare_or_closedborders] = 0 end
    if rem[i,:receive_or_moreopen] == 0 ; rem[i,:remshare_or_moreopen] = 0 end
    if rem[i,:receive_or_bordersnorthsouth] == 0 ; rem[i,:remshare_or_bordersnorthsouth] = 0 end
    if rem[i,:send_dest_currentborders] == 0 ; rem[i,:remshare_dest_currentborders] = 0 end
    if rem[i,:send_dest_closedborders] == 0 ; rem[i,:remshare_dest_closedborders] = 0 end
    if rem[i,:send_dest_moreopen] == 0 ; rem[i,:remshare_dest_moreopen] = 0 end
    if rem[i,:send_dest_bordersnorthsouth] == 0 ; rem[i,:remshare_dest_bordersnorthsouth] = 0 end
end

for d in [2100, 2100]
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"rem_currentborders:q", scale={domain=[0,500]}},title = string("Current borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_", d,"_currentborders_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_or_currentborders:q", scale={domain=[0,1]}},title = string("Current borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_or", d,"_currentborders_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_dest_currentborders:q", scale={domain=[0,1]}},title = string("Current borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_dest", d,"_currentborders_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"rem_closedborders:q", scale={domain=[0,500]}},title = string("Closed borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_", d,"_closedborders_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_or_closedborders:q", scale={domain=[0,1]}},title = string("Closed borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_or", d,"_closedborders_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_dest_closedborders:q", scale={domain=[0,1]}},title = string("Closed borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_dest", d,"_closedborders_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"rem_moreopen:q", scale={domain=[0,500]}},title = string("More open borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_", d,"_moreopen_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_or_moreopen:q", scale={domain=[0,1]}},title = string("More open borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_or", d,"_moreopen_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_dest_moreopen:q", scale={domain=[0,1]}},title = string("More open borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_dest", d,"_moreopen_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"rem_bordersnorthsouth:q", scale={domain=[0,500]}},title = string("Borders closed between Global North and Global South, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_", d,"_bordersnorthsouth_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_or_bordersnorthsouth:q", scale={domain=[0,1]}},title = string("Borders closed between Global North and Global South, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_or", d,"_bordersnorthsouth_mitig.png")))
    rem |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"remshare_dest_bordersnorthsouth:q", scale={domain=[0,1]}},title = string("Borders closed between Global North and Global South, ", d)
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remflow_share_dest", d,"_bordersnorthsouth_mitig.png")))
end


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"))
income_maps = join(income, isonum_fundregion, on = :fundregion, kind = :left)
income_maps[!,:ypcdiff_closedborders] = (income_maps[!,:ypc_closedborders] ./ income_maps[!,:ypc_currentborders] .- 1) .* 100
income_maps[!,:ypcdiff_moreopen] = (income_maps[!,:ypc_moreopen] ./ income_maps[!,:ypc_currentborders] .- 1) .* 100
income_maps[!,:ypcdiff_bordersnorthsouth] = (income_maps[!,:ypc_bordersnorthsouth] ./ income_maps[!,:ypc_currentborders] .- 1) .* 100

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypc_currentborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("GDP per capita levels by 2100 for current borders, ", s),fontSize=24}, 
        color = {"ypc_currentborders:q", scale={scheme=:greens}, legend={title=string("USD2005/cap"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypc_currentborders_", s, "_mitig.pdf")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_closedborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Closed borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_closedborders)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypcdiff",:_closedborders,"_", s, "_mitig.pdf")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_moreopen)]}}],
        projection={type=:naturalEarth1}, title = {text=string("More open borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_moreopen)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypcdiff",:_moreopen,"_", s, "_mitig.pdf")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, title = {text=string("North/South borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_bordersnorthsouth)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypcdiff",:_bordersnorthsouth,"_", s, "_mitig.pdf")))
end


###################################### Look at net remittances flows for different border policies ############################################
income[!,:netrem_currentborders] = income[!,:receive_currentborders] .- income[!,:send_currentborders]
income[!,:netrem_overallclosed] = income[!,:receive_closedborders] .- income[!,:send_closedborders]
income[!,:netrem_bordersmoreopen] = income[!,:receive_moreopen] .- income[!,:send_moreopen]
income[!,:netrem_northsouthclosed] = income[!,:receive_bordersnorthsouth] .- income[!,:send_bordersnorthsouth]

netrem_all = stack(
    income, 
    [:netrem_currentborders,:netrem_overallclosed,:netrem_bordersmoreopen,:netrem_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(netrem_all, :variable => :netrem_type, :value => :netrem)
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
netrem_all = join(netrem_all,regions_fullname, on=:fundregion)
for s in ssps
    netrem_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netrem:q", title = nothing, axis={labelFontSize=16}},
        color={"netrem_type:o",scale={scheme=:darkmulti},legend={title=string("Net remittances, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("netrem_",s,"_mitig.png")))
end
netrem_all[!,:scen_netrem_type] = [string(netrem_all[i,:scen],"_",SubString(string(netrem_all[i,:netrem_type]),8)) for i in 1:size(netrem_all,1)]
netrem_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"netrem:q", title = nothing, axis={labelFontSize=16}},
    title = "Net remittances flow for world regions, SSP narratives and various border policies",
    color={"scen_netrem_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income/", string("netrem_mitig.png")))

rem_all = stack(
    rename(income, :receive_closedborders => :receive_overallclosed, :receive_moreopen => :receive_bordersmoreopen, :receive_bordersnorthsouth => :receive_northsouthclosed, :send_closedborders => :send_overallclosed, :send_moreopen => :send_bordersmoreopen, :send_bordersnorthsouth => :send_northsouthclosed), 
    [:receive_currentborders, :receive_overallclosed, :receive_bordersmoreopen, :receive_northsouthclosed, :send_currentborders, :send_overallclosed, :send_bordersmoreopen, :send_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(rem_all, :variable => :rem_type, :value => :rem)
rem_all[!,:rem] = [in(rem_all[i,:rem_type], [:send_currentborders,:send_overallclosed,:send_bordersmoreopen,:send_northsouthclosed]) ? rem_all[i,:rem] * (-1) : rem_all[i,:rem] for i in 1:size(rem_all,1)]
for s in ssps
    rem_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"rem:q", title = nothing, axis={labelFontSize=16}},
        color={"rem_type:o",scale={scheme="category20c"},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("rem_",s,"_mitig.png")))
end


################################################### Plot share of income sent as remittances #################################################
remshare_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[!,:remshare_currentborders] = remshare_currentborders
remshare_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[!,:remshare_overallclosed] = remshare_closedborders
remshare_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[!,:remshare_bordersmoreopen] = remshare_moreopen
remshare_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:remshare][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
rem[!,:remshare_northsouthclosed] = remshare_bordersnorthsouth

remshare_all = stack(
    rem, 
    [:remshare_currentborders,:remshare_overallclosed,:remshare_bordersmoreopen,:remshare_northsouthclosed], 
    [:scen, :origin, :destination, :year]
)
rename!(remshare_all, :variable => :remshare_type, :value => :remshare)
remshare_all = join(remshare_all,rename(regions_fullname,:fundregion=>:origin,:regionname=>:originname), on=:origin)
remshare_all = join(remshare_all,rename(regions_fullname,:fundregion=>:destination,:regionname=>:destinationname), on=:destination)

# !!!!!!!!!! Weird: no difference from border policies !!!!!!!!!!

for s in ssps
    remshare_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point, size=60}, width=300, height=250, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"remshare:q", title = nothing, axis={labelFontSize=16}},
        color={"remshare_type:o",scale={scheme=:darkmulti},legend={title=string("Share of income sent as remittances, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("remshare_",s,"_mitig.png")))
end
remshare_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.remshare_type == Symbol("remshare_currentborders")) |> @vlplot(
    mark={:errorband, extent=:ci}, width=300, height=250, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24, titleFontSize=20}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"remshare:q", title = "Share of migrant income", axis={labelFontSize=16,titleFontSize=20,}},
    color={"scen:o",scale={scheme=:category10},legend={title=string("Remshare"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income/", string("remshare_currentborders_mitig.png")))