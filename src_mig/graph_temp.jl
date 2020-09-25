using DelimitedFiles, CSV, VegaLite, Query
using Statistics, DataFrames

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


# Compare temperature in Mig-FUND, in FUND with SSP and in FUND with original scenarios
ssps = ["SSP1-RCP1.9","SSP2-RCP4.5","SSP3-RCP7.0","SSP4-RCP6.0","SSP5-RCP8.5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 1951:2100

temp = DataFrame(
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
temp[:,:temp_migFUND] = temp_migFUND
temp_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_sspFUND] = temp_sspFUND
temp_origFUND = vcat(collect(Iterators.flatten(m_fund[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),missings(length(years)*4))
temp[:,:temp_origFUND] = temp_origFUND

temp_p = temp[(map(x->mod(x,10)==0,temp[:,:year])),:]

temp_all = stack(temp_p, [:temp_sspFUND,:temp_migFUND,:temp_origFUND], [:scen, :year])
rename!(temp_all, :variable => :temp_type, :value => :temp)
data_ssp = temp_all |> @filter(_.year <= 2100 && _.temp_type != :temp_origFUND) 
data_fund = temp_all[:,Not(:scen)] |> @filter(_.year <= 2100 && _.temp_type == :temp_origFUND) 
@vlplot() + @vlplot(
    width=500, height=400, 
    data = data_ssp, mark={:point, size=50}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", title=nothing, axis={labelFontSize=16}}, 
    #title = "Global temperature for FUND with original scenarios and SSP, and Mig-FUND", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"temp_type:o", scale={range=["circle", "triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, data = data_ssp, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", aggregate=:mean,typ=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "temp_type:o"
) + @vlplot(
    data = data_fund, mark={:line, strokeDash=[1,2], color = :black}, 
    x = {"year:o", axis={labelFontSize=16, values = 1950:10:2100}, title=nothing}, y = {"temp:q", aggregate=:mean,typ=:quantitative, title=nothing, axis={labelFontSize=16}}, 
    detail = "temp_type:o"
) |> save(joinpath(@__DIR__, "../results/temperature/", "temp_world_mitig.png"))


# Compare temperature in Mig-FUND for different border policy scenarios
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

temp_migFUND_cb = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_migFUND_cb] = temp_migFUND_cb

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

temp_migFUND_ob = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_migFUND_ob] = temp_migFUND_ob

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

temp_migFUND_2w = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:climatedynamics,:temp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
temp[:,:temp_migFUND_2w] = temp_migFUND_2w

temp_p = temp[(map(x->mod(x,10)==0,temp[:,:year])),:]
rename!(temp_p, :temp_migFUND => :temp_currentborders, :temp_migFUND_cb => :temp_closedborders, :temp_migFUND_ob => :temp_moreopen, :temp_migFUND_2w => :temp_bordersnorthsouth)

temp_all = stack(temp_p, [:temp_currentborders,:temp_closedborders,:temp_moreopen,:temp_bordersnorthsouth], [:scen, :year])
rename!(temp_all, :variable => :temp_type, :value => :temp)
temp_all[!,:border] = [SubString(String(temp_all[i,:temp_type]), 6) for i in 1:size(temp_all,1)]
temp_all |> @filter(_.year <= 2100) |> @vlplot(
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
) |> save(joinpath(@__DIR__, "../results/temperature/", "temp_world_borders_mitig.pdf"))