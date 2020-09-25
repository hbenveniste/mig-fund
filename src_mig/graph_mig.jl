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

# Compare migrant flows obtained with Mig-FUND to those in original SSP
mig_f = CSV.read(joinpath(@__DIR__, "../input_data/sspmig_fundregions.csv"), DataFrame)
ssps = ["SSP1","SSP2","SSP3","SSP4","SSP5"]
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
years = 2015:2100

migmodel = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
enter = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:entermig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:]))
)
migmodel[:,:enter] = enter
leave = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:migration,:leavemig][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:]))
)
migmodel[:,:leave] = leave
popu = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:population,:populationin1][MimiFUND.getindexfromyear(2015):MimiFUND.getindexfromyear(2100),:]))
)
migmodel[:,:pop] = popu

migmodel[:,:period] = migmodel[:,:year] .- map(x->mod(x,5),migmodel[:,:year])
migmodel_p = combine(d->(entermig = sum(d.enter)./10^3,leavemig = sum(d.leave)./10^3,pop=first(d.pop)./10^3), groupby(migmodel, [:scen,:fundregion,:period]))

comparemig = innerjoin(mig_f,migmodel_p,on=[:scen,:fundregion,:period])
rename!(comparemig, :popmig => :pop_SSP, :pop => :pop_migFUND, :entermig => :enter_migFUND, :leavemig => :leave_migFUND, :inmig =>:enter_SSP, :outmig =>:leave_SSP)

pop_all = stack(comparemig[:,[:period,:scen,:fundregion,:pop_migFUND,:pop_SSP]], [:pop_migFUND,:pop_SSP], [:scen, :fundregion, :period])
rename!(pop_all, :variable => :pop_type, :value => :pop)
for r in regions
    pop_all |> @filter(_.period < 2100 && _.fundregion==r) |> 
    @vlplot(
        width=300, height=250,
        mark={:point, size=60}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"pop:q", title=nothing, axis={labelFontSize=16}}, 
        title = string(r, "Population for Mig-FUND and original SSP"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"pop_type:o", scale={range=["triangle-up","circle"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"pop:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "pop_type:o"
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("pop_", r, "_mitig.png")))
end
pop_world = by(comparemig,[:period,:scen],d->(worldpop_SSP=sum(d.pop_SSP),worldpop_migFUND=sum(d.pop_migFUND)))
pop_world_stack = stack(pop_world,[:worldpop_SSP,:worldpop_migFUND],[:scen,:period])
rename!(pop_world_stack,:variable => :worldpop_type, :value => :worldpop)
pop_world_stack |> @filter(_.period < 2100) |> @vlplot(
    width=300, height=250,
    mark={:point, size=60}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"worldpop:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global population for Mig-FUND and original SSP", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldpop_type:o", scale={range=["triangle-up","circle"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"worldpop:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldpop_type:o"
) |> save(joinpath(@__DIR__, "../results/migflow/", "pop_world_mitig.png"))

enter_all = stack(comparemig[:,[:period,:scen,:fundregion,:enter_SSP,:enter_migFUND]], [:enter_SSP,:enter_migFUND], [:scen, :fundregion, :period])
rename!(enter_all, :variable => :enter_type, :value => :enter)
for r in regions
    enter_all |> @filter(_.period < 2100 && _.fundregion==r) |> 
    @vlplot(
        width=300, height=250,
        mark={:point, size=60}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"enter:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Migrant flows into ",r," for Mig-FUND and original SSP"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"enter_type:o", scale={range=["triangle-up","circle"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"enter:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "enter_type:o"
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("enter_", r, "_mitig.png")))
end
leave_all = stack(comparemig[:,[:period,:scen,:fundregion,:leave_SSP,:leave_migFUND]], [:leave_SSP,:leave_migFUND], [:scen, :fundregion, :period])
rename!(leave_all, :variable => :leave_type, :value => :leave)
for r in regions
    leave_all |> @filter(_.period < 2100 && _.fundregion==r) |> 
    @vlplot(
        width=300, height=250,
        mark={:point, size=80}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"leave:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Migrant flows out of ",r," for Mig-FUND and original SSP"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"leave_type:o", scale={range=["triangle-up","circle"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"period:o", axis={labelFontSize=16}, title=nothing}, y = {"leave:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "leave_type:o"
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_", r, "_mitig.png")))
end


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
popu_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_currentborders] = popu_currentborders

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
popu_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_closedborders] = popu_closedborders

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
popu_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_moreopen] = popu_moreopen

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
popu_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_bordersnorthsouth] = popu_bordersnorthsouth

migration_p = migration[(map(x->mod(x,10)==0,migration[:,:year])),:]

pop_all = stack(migration_p, [:pop_currentborders,:pop_closedborders,:pop_moreopen,:pop_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(pop_all, :variable => :pop_type, :value => :pop)
for r in regions
    pop_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> 
    @vlplot(
        width=300, height=250,
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"pop:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Population in ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"pop_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"pop:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "pop_type:o"
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("pop_", r, "_borders_mitig.png")))
end


pop_all = stack(
    rename(migration, :pop_closedborders => :pop_overallclosed, :pop_moreopen => :pop_bordersmoreopen, :pop_bordersnorthsouth => :pop_northsouthclosed), 
    [:pop_currentborders,:pop_overallclosed,:pop_bordersmoreopen,:pop_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(pop_all, :variable => :pop_type, :value => :pop)
for s in ssps
    pop_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"pop:q", title = nothing, axis={labelFontSize=16}},
        color={"pop_type:o",scale={scheme=:darkmulti},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("pop_",s,"_mitig.png")))
end
pop_all[!,:scen_pop_type] = [string(pop_all[i,:scen],"_",SubString(string(pop_all[i,:pop_type]),4)) for i in 1:size(pop_all,1)]
pop_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"pop:q", title = nothing, axis={labelFontSize=16}},
    title = "Income per capita for world regions, SSP narratives and various border policies",
    color={"scen_pop_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow/", string("pop_mitig.png")))


worldpop = DataFrame(
    year = repeat(years, outer = length(ssps)),
    scen = repeat(ssps,inner = length(years)),
)
worldpop_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp2[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp3[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp4[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_fundssp5[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_sspFUND] = worldpop_sspFUND
worldpop_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_migFUND] = worldpop_migFUND
worldpop_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_currentborders] = worldpop_currentborders
worldpop_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_closedborders] = worldpop_closedborders
worldpop_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_moreopen] = worldpop_moreopen
worldpop_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:population,:globalpopulation][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100)]))
)
worldpop[:,:worldpop_bordersnorthsouth] = worldpop_bordersnorthsouth

worldpop_p = worldpop[(map(x->mod(x,10)==0,worldpop[:,:year])),:]

worldpop_stack = stack(worldpop_p,[:worldpop_currentborders,:worldpop_closedborders,:worldpop_moreopen,:worldpop_bordersnorthsouth],[:scen,:year])
rename!(worldpop_stack,:variable => :worldpop_type, :value => :worldpop)
worldpop_stack |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    width=300, height=250,
    mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"worldpop:q", title=nothing, axis={labelFontSize=16}}, 
    title = "Global population for Mig-FUND with various border policies", 
    color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
    shape = {"worldpop_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
) + @vlplot(
    mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"worldpop:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
    color = {"scen:n", scale={scheme=:category10}},
    detail = "worldpop_type:o"
) |> save(joinpath(@__DIR__, "../results/migflow/", "pop_world_borders_mitig.png"))

enter_all = stack(migration_p, [:enter_currentborders,:enter_closedborders,:enter_moreopen,:enter_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(enter_all, :variable => :enter_type, :value => :enter)
for r in regions
    enter_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> 
    @vlplot(
        width=300, height=250,
        mark={:point, size=50}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"enter:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Migrant flows into ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"enter_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"enter:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "enter_type:o"
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("enter_", r, "_borders_mitig.png")))
end

leave_all = stack(migration_p, [:leave_currentborders,:leave_closedborders,:leave_moreopen,:leave_bordersnorthsouth], [:scen, :fundregion, :year])
rename!(leave_all, :variable => :leave_type, :value => :leave)
for r in regions
    leave_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.fundregion==r) |> 
    @vlplot(
        width=300, height=250,
        mark={:point, size=80}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"leave:q", title=nothing, axis={labelFontSize=16}}, 
        title = string("Migrant flows out of ",r," for Mig-FUND with various border policies"), 
        color = {"scen:n", scale={scheme=:category10}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}, 
        shape = {"leave_type:o", scale={range=["circle", "triangle-up", "square","cross"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, x = {"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing}, y = {"leave:q", aggregate=:mean,type=:quantitative,title=nothing, axis={labelFontSize=16}}, 
        color = {"scen:n", scale={scheme=:category10}},
        detail = "leave_type:o"
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_", r, "_borders_mitig.png")))
end


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
netmig_all = join(netmig_all,regions_fullname, on=:fundregion)

for s in ssps
    netmig_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = "Net migrants", axis={labelFontSize=16,titleFontSize=16}},
        color={"netmig_type:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_",s,"_mitig.png")))
end
netmig_all[!,:scen_netmig_type] = [string(netmig_all[i,:scen],"_",SubString(string(netmig_all[i,:netmig_type]),8)) for i in 1:size(netmig_all,1)]
netmig_all |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250, columns=8, wrap="fundregion:o", 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"netmig:q", title = nothing, axis={labelFontSize=16}},
    title = "Net migration flows for world regions, SSP narratives and various border policies",
    color={"scen_netmig_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_mitig.png")))

mig_all = stack(
    rename(migration, :enter_closedborders => :enter_overallclosed, :enter_moreopen => :enter_bordersmoreopen, :enter_bordersnorthsouth => :enter_northsouthclosed, :leave_closedborders => :leave_overallclosed, :leave_moreopen => :leave_bordersmoreopen, :leave_bordersnorthsouth => :leave_northsouthclosed), 
    [:enter_currentborders, :enter_overallclosed, :enter_bordersmoreopen, :enter_northsouthclosed, :leave_currentborders, :leave_overallclosed, :leave_bordersmoreopen, :leave_northsouthclosed], 
    [:scen, :fundregion, :year]
)
rename!(mig_all, :variable => :mig_type, :value => :mig)
mig_all[!,:mig] = [in(mig_all[i,:mig_type], [:leave_currentborders,:leave_overallclosed,:leave_bordersmoreopen,:leave_northsouthclosed]) ? mig_all[i,:mig] * (-1) : mig_all[i,:mig] for i in 1:size(mig_all,1)]
mig_all = join(mig_all,regions_fullname, on=:fundregion)
for s in ssps
    mig_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=8, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"mig:q", title = nothing, axis={labelFontSize=16}},
        color={
            "mig_type:o",
            scale={scheme="category20c"},
            legend={
                title=nothing, 
                symbolSize=60, 
                labelFontSize=20, labelLimit=220,
                #orient=:bottom
                #values=[(:enter_bordersmoreopen, "Enter, more open"),(:enter_currentborders, "Enter, current borders"),(:enter_northsouthclosed,"Enter, North-South"),(:enter_overallclosed,"Enter, closed borders"),(:leave_bordersmoreopen,"Leave, more open"),(:leave_currentborders, "Leave, current borders"),(:leave_northsouthclosed, "Leave, North-South"),(:leave_overallclosed, "Leave, closed borders")]
            }
        },
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("mig_",s,"_mitig.png")))
end


# Look at regional contributions to population for original FUND, FUND with original SSP, and Mig-FUND with SSP scenarios zero migration
popu_sspFUND = vcat(
    collect(Iterators.flatten(m_fundssp1[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp2[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp3[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp4[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_fundssp5[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_sspFUND] = popu_sspFUND
popu_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:population,:populationin1][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration[:,:pop_migFUND] = popu_migFUND

migration = join(migration, worldpop, on = [:year,:scen])
migration[!,:regsharepop_sspFUND] = migration[!,:pop_sspFUND] ./ migration[!,:worldpop_sspFUND]
migration[!,:regsharepop_migFUND] = migration[!,:pop_migFUND] ./ migration[!,:worldpop_migFUND]

migration |> @filter(_.year >= 1990 && _.year <= 2100 && _.scen == "SSP2") |> @vlplot(
    repeat={column=[:regsharepop_sspFUND, :regsharepop_migFUND]}
) + @vlplot(
    :area, width=300,
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={field={repeat=:column}, type = :quantitative, stack=:normalize, axis={labelFontSize=16}},
    color={"fundregion:o",scale={scheme="tableau20"}},
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_mig_SSP2_mitig.png"))

migration |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300,
    row = {"scen:n", axis=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharepop_origFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of population for FUND with original scenarios"
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_origFUND_mitig.png"))

migration |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharepop_sspFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of population for FUND with SSP scenarios"
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_sspFUND_mitig.png"))

migration |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharepop_migFUND:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of population for Mig-FUND"
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_migFUND_mitig.png"))


# Look at regional contributions to population for Mig-FUND with various border policies
migration[:,:regsharepop_currentborders] = migration[:,:pop_currentborders] ./ migration[:,:worldpop_currentborders]
migration[:,:regsharepop_closedborders] = migration[:,:pop_closedborders] ./ migration[:,:worldpop_closedborders]
migration[:,:regsharepop_moreopen] = migration[:,:pop_moreopen] ./ migration[:,:worldpop_moreopen]
migration[:,:regsharepop_bordersnorthsouth] = migration[:,:pop_bordersnorthsouth] ./ migration[:,:worldpop_bordersnorthsouth]

migration |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharepop_currentborders:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of population for current borders"
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_currentborders_mitig.png"))

migration |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharepop_closedborders:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of population for closed borders"
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_closedborders_mitig.png"))

migration |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharepop_moreopen:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of population for more open borders"
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_moreopen_mitig.png"))

migration |> @filter(_.year >= 1990 && _.year <= 2100) |> @vlplot(
    :area, width=300, 
    row = {"scen:n", axis={labelFontSize=16}, title=nothing},
    x={"year:o", axis={labelFontSize=16, values = 1990:10:2100}, title=nothing},
    y={"regsharepop_bordersnorthsouth:q", axis={labelFontSize=16}, title=nothing, stack=:normalize},
    color={"fundregion:o",scale={scheme="tableau20"}},
    title = "Regional shares of population for closed borders between North and South"
) |> save(joinpath(@__DIR__, "../results/migflow/", "regpop_bordersnorthsouth_mitig.png"))


# Plot heat tables and geographical maps of migrant flows in 2100 and 2100
move = DataFrame(
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
move[:,:move_currentborders] = move_currentborders
move_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_cb[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move[:,:move_closedborders] = move_closedborders
move_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_ob[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move[:,:move_moreopen] = move_moreopen
move_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp2_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp3_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp4_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:])),
    collect(Iterators.flatten(m_ssp5_nomig_2w[:migration,:move][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:,:]))
)
move[:,:move_bordersnorthsouth] = move_bordersnorthsouth

move = join(
    move, 
    rename(
        migration, 
        :fundregion => :origin, 
        :leave_currentborders => :leave_or_currentborders, 
        :pop_currentborders => :pop_or_currentborders, 
        :leave_closedborders => :leave_or_closedborders, 
        :pop_closedborders => :pop_or_closedborders, 
        :leave_moreopen => :leave_or_moreopen, 
        :pop_moreopen => :pop_or_moreopen, 
        :leave_bordersnorthsouth => :leave_or_bordersnorthsouth,
        :pop_bordersnorthsouth => :pop_or_bordersnorthsouth
    )[:,[:year,:scen,:origin,:leave_or_currentborders,:pop_or_currentborders,:leave_or_closedborders,:pop_or_closedborders,:leave_or_moreopen,:pop_or_moreopen,:leave_or_bordersnorthsouth,:pop_or_bordersnorthsouth]],
    on = [:year,:scen,:origin]
)
move = join(
    move, 
    rename(
        migration, 
        :fundregion => :destination, 
        :enter_currentborders => :enter_dest_currentborders, 
        :pop_currentborders => :pop_dest_currentborders, 
        :enter_closedborders => :enter_dest_closedborders, 
        :pop_closedborders => :pop_dest_closedborders, 
        :enter_moreopen => :enter_dest_moreopen, 
        :pop_moreopen => :pop_dest_moreopen, 
        :enter_bordersnorthsouth => :enter_dest_bordersnorthsouth,
        :pop_bordersnorthsouth => :pop_dest_bordersnorthsouth
    )[:,[:year,:scen,:destination,:enter_dest_currentborders,:pop_dest_currentborders,:enter_dest_closedborders,:pop_dest_closedborders,:enter_dest_moreopen,:pop_dest_moreopen,:enter_dest_bordersnorthsouth,:pop_dest_bordersnorthsouth]],
    on = [:year,:scen,:destination]
)
move[:,:migshare_or_currentborders] = move[:,:move_currentborders] ./ move[:,:leave_or_currentborders]
move[:,:migshare_or_closedborders] = move[:,:move_closedborders] ./ move[:,:leave_or_closedborders]
move[:,:migshare_or_moreopen] = move[:,:move_moreopen] ./ move[:,:leave_or_moreopen]
move[:,:migshare_or_bordersnorthsouth] = move[:,:move_bordersnorthsouth] ./ move[:,:leave_or_bordersnorthsouth]
move[:,:migshare_dest_currentborders] = move[:,:move_currentborders] ./ move[:,:enter_dest_currentborders]
move[:,:migshare_dest_closedborders] = move[:,:move_closedborders] ./ move[:,:enter_dest_closedborders]
move[:,:migshare_dest_moreopen] = move[:,:move_moreopen] ./ move[:,:enter_dest_moreopen]
move[:,:migshare_dest_bordersnorthsouth] = move[:,:move_bordersnorthsouth] ./ move[:,:enter_dest_bordersnorthsouth]
for i in 1:size(move,1)
    if move[i,:leave_or_currentborders] == 0 ; move[i,:migshare_or_currentborders] = 0 end
    if move[i,:leave_or_closedborders] == 0 ; move[i,:migshare_or_closedborders] = 0 end
    if move[i,:leave_or_moreopen] == 0 ; move[i,:migshare_or_moreopen] = 0 end
    if move[i,:leave_or_bordersnorthsouth] == 0 ; move[i,:migshare_or_bordersnorthsouth] = 0 end
    if move[i,:enter_dest_currentborders] == 0 ; move[i,:migshare_dest_currentborders] = 0 end
    if move[i,:enter_dest_closedborders] == 0 ; move[i,:migshare_dest_closedborders] = 0 end
    if move[i,:enter_dest_moreopen] == 0 ; move[i,:migshare_dest_moreopen] = 0 end
    if move[i,:enter_dest_bordersnorthsouth] == 0 ; move[i,:migshare_dest_bordersnorthsouth] = 0 end
end

for d in [2100, 2100]
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y="origin:n", x="destination:n", column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"move_currentborders:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Current borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_", d,"_currentborders_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_or_currentborders:q", scale={domain=[0,1], scheme=:goldred}},title = string("Current borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_or", d,"_currentborders_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_dest_currentborders:q", scale={domain=[0,1], scheme=:goldred}},title = string("Current borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_dest", d,"_currentborders_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"move_closedborders:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Closed borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_", d,"_closedborders_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_or_closedborders:q", scale={domain=[0,1], scheme=:goldred}},title = string("Closed borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_or", d,"_closedborders_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_dest_closedborders:q", scale={domain=[0,1], scheme=:goldred}},title = string("Closed borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_dest", d,"_closedborders_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"move_moreopen:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("More open borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_", d,"_moreopen_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_or_moreopen:q", scale={domain=[0,1], scheme=:goldred}},title = string("More open borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_or", d,"_moreopen_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_dest_moreopen:q", scale={domain=[0,1], scheme=:goldred}},title = string("More open borders, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_dest", d,"_moreopen_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"move_bordersnorthsouth:q", scale={domain=[0,2*10^5], scheme=:goldred}},title = string("Borders closed between Global North and Global South, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_", d,"_bordersnorthsouth_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_or_bordersnorthsouth:q", scale={domain=[0,1], scheme=:goldred}},title = string("Borders closed between Global North and Global South, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_or", d,"_bordersnorthsouth_mitig.png")))
    move |> @filter(_.year == d) |> @vlplot(
        :rect, y=:origin, x=:destination, column = {"scen:o", axis={labelFontSize=16}, title=nothing},
        color={"migshare_dest_bordersnorthsouth:q", scale={domain=[0,1], scheme=:goldred}},title = string("Borders closed between Global North and Global South, ", d)
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("migflow_share_dest", d,"_bordersnorthsouth_mitig.png")))
end


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"))
migration_maps = join(migration, isonum_fundregion, on = :fundregion, kind = :left)
migration_maps[!,:popdiff_closedborders] = migration_maps[!,:pop_closedborders] ./ migration_maps[!,:pop_currentborders] .- 1
migration_maps[!,:popdiff_moreopen] = migration_maps[!,:pop_moreopen] ./ migration_maps[!,:pop_currentborders] .- 1
migration_maps[!,:popdiff_bordersnorthsouth] = migration_maps[!,:pop_bordersnorthsouth] ./ migration_maps[!,:pop_currentborders] .- 1

for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_maps), key=:isonum, fields=[string(:pop_currentborders)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Population levels by 2100 for current borders, ", s),fontSize=20}, 
        color = {:pop_currentborders, type=:quantitative, scale={scheme=:blues}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("pop_currentborders_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_maps), key=:isonum, fields=[string(:popdiff,:_closedborders)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Relative changes in population by 2100 for closed vs current borders, ", s),fontSize=20}, 
        color = {Symbol(string(:popdiff,:_closedborders)), type=:quantitative, scale={domain=[-0.05,0.05], scheme=:redblue}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("popdiff",:_closedborders,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_maps), key=:isonum, fields=[string(:popdiff,:_moreopen)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Relative changes in population by 2100 for more open vs current borders, ", s),fontSize=20}, 
        color = {Symbol(string(:popdiff,:_moreopen)), type=:quantitative, scale={domain=[-0.05,0.05], scheme=:redblue}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("popdiff",:_moreopen,"_", s, "_mitig.png")))
end
for s in ssps
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, migration_maps), key=:isonum, fields=[string(:popdiff,:_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, #title = {text=string("Relative changes in population by 2100 for North-South closed vs current borders, ", s),fontSize=20}, 
        color = {Symbol(string(:popdiff,:_bordersnorthsouth)), type=:quantitative, scale={domain=[-0.05,0.05], scheme=:redblue}, legend={title=nothing, symbolSize=40, labelFontSize=16}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("popdiff",:_bordersnorthsouth,"_", s, "_mitig.png")))
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

# Plot both net migration with and without climate change
netmig_nocc_all = rename(stack(
    migration_nocc, 
    [:netmig_currentborders,:netmig_overallclosed,:netmig_bordersmoreopen,:netmig_northsouthclosed, :netmig_nocc_currentborders,:netmig_nocc_overallclosed,:netmig_nocc_bordersmoreopen,:netmig_nocc_northsouthclosed], 
    [:scen, :fundregion, :year]
), :variable => :netmig_type, :value => :netmig)
netmig_nocc_all[!,:border] = [(netmig_nocc_all[i,:netmig_type] == Symbol("netmig_currentborders") || netmig_nocc_all[i,:netmig_type] == Symbol("netmig_nocc_currentborders")) ? "currentborders" : ((netmig_nocc_all[i,:netmig_type] == Symbol("netmig_overallclosed") || netmig_nocc_all[i,:netmig_type] == Symbol("netmig_nocc_overallclosed")) ? "overallclosed" : ((netmig_nocc_all[i,:netmig_type] == Symbol("netmig_bordersmoreopen") || netmig_nocc_all[i,:netmig_type] == Symbol("netmig_nocc_bordersmoreopen")) ? "bordersmoreopen" : "bordersnorthsouth")) for i in 1:size(netmig_nocc_all,1)]
netmig_nocc_all[!,:ccornot] = [(SubString(String(netmig_nocc_all[i,:netmig_type]), 1:11) == "netmig_nocc") ? "nocc" : "cc" for i in 1:size(netmig_nocc_all,1)] 
netmig_nocc_all = join(netmig_nocc_all,regions_fullname, on=:fundregion)
for s in ssps
    netmig_nocc_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:point, size = 50}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = nothing, axis={labelFontSize=16}},
        color={"border:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        shape = {"ccornot:o", scale={range=["circle", "triangle-up"]}, legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
        resolve = {scale={y=:independent}}
    ) + @vlplot(
        mark={:line, strokeDash=[1,2]}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig:q", title = nothing, axis={labelFontSize=16}},
        color={"border:o",scale={scheme=:darkmulti}},
        detail="ccornot:o",
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_nocc_",s,"_mitig.png")))
end

# Plot differences in net migration with and without climate change
netmig_nocc_both = rename(stack(
    migration_nocc, 
    [:netmig_currentborders,:netmig_overallclosed,:netmig_bordersmoreopen,:netmig_northsouthclosed], 
    [:scen, :fundregion, :year]
), :variable => :netmig_type, :value => :netmig)
netmig_nocc = rename(stack(
    migration_nocc, 
    [:netmig_nocc_currentborders,:netmig_nocc_overallclosed,:netmig_nocc_bordersmoreopen,:netmig_nocc_northsouthclosed],
    [:scen, :fundregion, :year]
), :variable => :netmig_nocc_type, :value => :netmig_nocc)
sort!(netmig_nocc_both, [:scen,:fundregion,:year])
sort!(netmig_nocc, [:scen,:fundregion,:year])
netmig_nocc_both[!,:netmig_nocc] = netmig_nocc[:,:netmig_nocc]
netmig_nocc_both[!,:border] = [SubString(String(netmig_nocc_both[i,:netmig_type]), 8) for i in 1:size(netmig_nocc_both,1)]
netmig_nocc_both = join(netmig_nocc_both,regions_fullname, on=:fundregion)
netmig_nocc_both[!,:netmig_diff] = netmig_nocc_both[:,:netmig] .- netmig_nocc_both[:,:netmig_nocc]

for s in ssps
    netmig_nocc_both |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netmig_diff:q", title = nothing, axis={labelFontSize=16}},
        color={"border:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("netmig_ccdiff_",s,"_mitig.png")))
end

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
leave_nocc_both[!,:border] = [SubString(String(leave_nocc_both[i,:leave_type]), 7) for i in 1:size(leave_nocc_both,1)]
leave_nocc_both = join(leave_nocc_both,regions_fullname, on=:fundregion)
leave_nocc_both[!,:leave_diff] = leave_nocc_both[:,:leave] .- leave_nocc_both[:,:leave_nocc]

for s in ssps
    leave_nocc_both |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_diff:q", title = nothing, axis={labelFontSize=16}},
        color={"border:o",scale={scheme=:darkmulti},legend={title=string("Net migration, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_ccdiff_reg_",s,"_mitig.png")))
end

leave_nocc_tot = by(leave_nocc_both, [:scen,:year,:border], d->(leave_diff=sum(d.leave_diff),leave=sum(d.leave)))
leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250,  
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_diff:q", title = nothing, axis={labelFontSize=16}},
    color={"scen_ccshare_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_ccdiff_mitig.png")))
for s in ssps
    leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_diff:q", title = "Number of additional migrants with climate change", axis={labelFontSize=16}, scale={domain=[0.0,400000]}},
        color={"border:o",scale={scheme=:darkmulti},legend={title=string("Border policy, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_ccdiff_",s,"_mitig.png")))
end

leave_nocc_tot[!,:ccshare] = leave_nocc_tot[:,:leave_diff] ./ leave_nocc_tot[:,:leave]
for i in 1:size(leave_nocc_tot,1) ; if leave_nocc_tot[i,:leave] == 0.0 ; leave_nocc_tot[i,:ccshare] = 0 end end
leave_nocc_tot[.&(leave_nocc_tot[:,:year].==2100),:]
by(leave_nocc_tot[.&(leave_nocc_tot[:,:year].>=2020,leave_nocc_tot[:,:year].<=2040),:], [:scen,:border], d->sum(d.leave))
# SSP2 in 2100: 13.8 millions international migrants, which is 0.5% more with climate change than without
# Plot results
leave_nocc_tot[!,:scen_ccshare_type] = [string(leave_nocc_tot[i,:scen],"_",string(leave_nocc_tot[i,:border])) for i in 1:size(leave_nocc_tot,1)]
leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250,  
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"ccshare:q", title = nothing, axis={labelFontSize=16}},
    color={"scen_ccshare_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_ccshare_mitig.png")))
for s in ssps
    leave_nocc_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"ccshare:q", title = "Effect of climate change on global migration flows", axis={labelFontSize=16, titleFontSize=14,values = -0.012:0.004:0.012}, scale={domain=[-0.012,0.012]}},
        color={"border:o",scale={scheme=:darkmulti},legend={title=string("Border policy, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_ccshare_",s,"_mitig.png")))
end


########################################## Compare to other papers ####################################################
# Burzynsli et al. 3.2 millions additional people in 2100 for medium CC scenario.
# Shayegh et al. 4.5 millions additional people in 2100 in SSP5 vs SSP1.
# With usual FUND calibration we find: 75,000 additional people in 2100 for SSP2 current border policy compared to no CC; 
# but 9.4 millions additional people in SSP5 vs SSP1 in 2100.

# What we need to change in FUND damages calibrations to find their estimations of migrant numbers: 
# First: what if CO2 fertilization effect turned to zero.
zerofert = DataFrame(region = regions, co2fert = zeros(length(regions)))
CSV.write(joinpath(@__DIR__,"../data_damcalib/co2fert_zero.csv"), zerofert; writeheader=false)

tinyfert = DataFrame(region = regions, co2fert = repeat([0.01],length(regions)))
CSV.write(joinpath(@__DIR__,"../data_damcalib/co2fert_tiny.csv"), tinyfert; writeheader=false)

param_damcalib = MimiFUND.load_default_parameters(joinpath(@__DIR__,"../data_damcalib"))

# Run models with zero CO2 fertilization
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

migration_fert = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)),
    fundregion = repeat(regions, outer = length(ssps), inner=length(years)),
)
leave_nofert_currentborders = vcat(
    collect(Iterators.flatten(m_ssp1_nofert[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_fert[:,:leave_nofert_currentborders] = leave_nofert_currentborders
leave_nofert_closedborders = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_cb[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_fert[:,:leave_nofert_closedborders] = leave_nofert_closedborders
leave_nofert_moreopen = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_ob[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_fert[:,:leave_nofert_moreopen] = leave_nofert_moreopen
leave_nofert_bordersnorthsouth = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_2w[:migration,:leavemig][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
migration_fert[:,:leave_nofert_bordersnorthsouth] = leave_nofert_bordersnorthsouth

migration_fert[:,:leave_nocc_currentborders] = leave_nocc_currentborders
migration_fert[:,:leave_nocc_closedborders] = leave_nocc_closedborders
migration_fert[:,:leave_nocc_moreopen] = leave_nocc_moreopen
migration_fert[:,:leave_nocc_bordersnorthsouth] = leave_nocc_bordersnorthsouth


# Look at differences in migration (people leaving a place) with CC but without CO2 fertilization and without climate change
leave_nofert_both = rename(stack(
    rename(migration_fert, :leave_nofert_closedborders=>:leave_nofert_overallclosed, :leave_nofert_moreopen=>:leave_nofert_bordersmoreopen,:leave_nofert_bordersnorthsouth=>:leave_nofert_northsouthclosed), 
    [:leave_nofert_currentborders,:leave_nofert_overallclosed,:leave_nofert_bordersmoreopen,:leave_nofert_northsouthclosed], 
    [:scen, :fundregion, :year]
), :variable => :leave_nofert_type, :value => :leave_nofert)
leave_nocc = rename(stack(
    rename(migration_fert, :leave_nocc_closedborders=>:leave_nocc_overallclosed, :leave_nocc_moreopen=>:leave_nocc_bordersmoreopen,:leave_nocc_bordersnorthsouth=>:leave_nocc_northsouthclosed), 
    [:leave_nocc_currentborders,:leave_nocc_overallclosed,:leave_nocc_bordersmoreopen,:leave_nocc_northsouthclosed],
    [:scen, :fundregion, :year]
), :variable => :leave_nocc_type, :value => :leave_nocc)
sort!(leave_nofert_both, [:scen,:fundregion,:year])
sort!(leave_nocc, [:scen,:fundregion,:year])
leave_nofert_both[!,:leave_nocc] = leave_nocc[:,:leave_nocc]
leave_nofert_both[!,:border] = [SubString(String(leave_nofert_both[i,:leave_nofert_type]), 14) for i in 1:size(leave_nofert_both,1)]
leave_nofert_both = join(leave_nofert_both,regions_fullname, on=:fundregion)
leave_nofert_both[!,:leave_nofert_diff] = leave_nofert_both[:,:leave_nofert] .- leave_nofert_both[:,:leave_nocc]

leave_nofert_tot = by(leave_nofert_both, [:scen,:year,:border], d->(leave_nofert_diff=sum(d.leave_nofert_diff),leave_nofert=sum(d.leave_nofert)))
leave_nofert_tot[.&(leave_nofert_tot[:,:year].==2100),:]

leave_nofert_tot[!,:scen_type] = [string(leave_nofert_tot[i,:scen],"_",string(leave_nofert_tot[i,:border])) for i in 1:size(leave_nofert_tot,1)]
# Interesting: removing CO2 fertilization effect decreases migration flows with CC compared to without CC by 2100.
leave_nofert_tot |> @filter(_.year >= 2015 && _.year <= 2100) |> @vlplot(
    mark={:line, strokeWidth = 4}, width=300, height=250,  
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"leave_nofert_diff:q", title = nothing, axis={labelFontSize=16}},
    color={"scen_type:o",scale={scheme=:category20c},legend={titleFontSize=16, symbolSize=40, labelFontSize=16}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_fertdiff_mitig.png")))
for s in ssps
    leave_nofert_tot |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"leave_nofert_diff:q", title = "Number of additional migrants with climate change", axis={labelFontSize=16}, scale={domain=[0.0,1000000]}},
        color={"border:o",scale={scheme=:darkmulti},legend={title=string("Border policy, ",s), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/migflow/", string("leave_fertdiff_",s,"_mitig.png")))
end


# Check whether damages/exposure findings still hold when changing calibrations
# First: region-specific impacts decomposition
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

damages_nofert_p = damages_nofert[(map(x->mod(x,10)==0,damages_nofert[:,:year])),:]
dam_nofert_impact = damages_nofert[:,[:year, :scen, :fundregion, :dam_nofert_currentborders, :dam_nofert_closedborders, :dam_nofert_moreopen, :dam_nofert_bordersnorthsouth]]

dam_nofert_impact[!,:dam_nofert_migFUND] = dam_nofert_impact[!,:dam_nofert_currentborders]
for imp in [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost]
    imp_curr = vcat(
        collect(Iterators.flatten(m_ssp1_nofert[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nofert[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nofert[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nofert[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nofert[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_nofert_impact[:,Symbol(string(imp,"_currentborders"))] = imp_curr
    imp_closed = vcat(
        collect(Iterators.flatten(m_ssp1_nofert_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nofert_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nofert_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nofert_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nofert_cb[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_nofert_impact[:,Symbol(string(imp,"_closedborders"))] = imp_closed
    imp_more = vcat(
        collect(Iterators.flatten(m_ssp1_nofert_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nofert_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nofert_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nofert_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nofert_ob[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_nofert_impact[:,Symbol(string(imp,"_moreopen"))] = imp_more
    imp_ns = vcat(
        collect(Iterators.flatten(m_ssp1_nofert_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp2_nofert_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp3_nofert_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp4_nofert_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
        collect(Iterators.flatten(m_ssp5_nofert_2w[:impactaggregation,imp][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
    )
    dam_nofert_impact[:,Symbol(string(imp,"_bordersnorthsouth"))] = imp_ns
end
# We count as climate change damage only those attributed to differences in income resulting from climate change impacts
imp_curr = vcat(
    collect(Iterators.flatten(m_ssp1_nofert[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_curr = vcat(
    collect(Iterators.flatten(m_ssp1_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_nofert_impact[:,Symbol(string(:deadmigcost,"_currentborders"))] = imp_curr - imp_nocc_curr
imp_closed = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_closed = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_cb[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_nofert_impact[:,Symbol(string(:deadmigcost,"_closedborders"))] = imp_closed - imp_nocc_closed
imp_more = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_more = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_ob[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_nofert_impact[:,Symbol(string(:deadmigcost,"_moreopen"))] = imp_more - imp_nocc_more
imp_ns = vcat(
    collect(Iterators.flatten(m_ssp1_nofert_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nofert_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nofert_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nofert_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nofert_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
imp_nocc_ns = vcat(
    collect(Iterators.flatten(m_ssp1_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nocc_2w[:migration,:deadmigcost][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
dam_nofert_impact[:,Symbol(string(:deadmigcost,"_bordersnorthsouth"))] = imp_ns - imp_nocc_ns
# Impacts coded as negative if damaging: recode as positive
for imp in [:water,:forests,:heating,:cooling,:agcost]
    for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
        dam_nofert_impact[!,Symbol(string(imp,btype))] .*= -1
    end
end
for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    for imp in [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]
        dam_nofert_impact[!,Symbol(string("share_",imp,btype))] = dam_nofert_impact[!,Symbol(string(imp,btype))] ./ dam_nofert_impact[!,Symbol(string("dam_nofert",btype))] .* 1000000000
    end
end

dam_nofert_impact_stacked = stack(dam_nofert_impact, map(x -> Symbol(string(x,"_currentborders")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_nofert_impact_stacked, :variable => :impact, :value => :impact_dam)
dam_nofert_impact_stacked[!,:borders] = repeat(["_currentborders"],size(dam_nofert_impact_stacked,1))
dam_nofert_impact_stacked[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-15)), dam_nofert_impact_stacked[!,:impact])

dam_nofert_impact_stacked_cb = stack(dam_nofert_impact, map(x -> Symbol(string(x,"_closedborders")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_nofert_impact_stacked_cb, :variable => :impact, :value => :impact_dam)
dam_nofert_impact_stacked_cb[!,:borders] = repeat(["_closedborders"],size(dam_nofert_impact_stacked_cb,1))
dam_nofert_impact_stacked_cb[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-14)), dam_nofert_impact_stacked_cb[!,:impact])

dam_nofert_impact_stacked_ob = stack(dam_nofert_impact, map(x -> Symbol(string(x,"_moreopen")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_nofert_impact_stacked_ob, :variable => :impact, :value => :impact_dam)
dam_nofert_impact_stacked_ob[!,:borders] = repeat(["_moreopen"],size(dam_nofert_impact_stacked_ob,1))
dam_nofert_impact_stacked_ob[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-9)), dam_nofert_impact_stacked_ob[!,:impact])

dam_nofert_impact_stacked_2w = stack(dam_nofert_impact, map(x -> Symbol(string(x,"_bordersnorthsouth")), [:water,:forests,:heating,:cooling,:agcost,:drycost,:protcost,:hurrdam,:extratropicalstormsdam,:eloss_other,:species,:deadcost,:morbcost,:wetcost,:deadmigcost]),[:year,:scen,:fundregion])
rename!(dam_nofert_impact_stacked_2w, :variable => :impact, :value => :impact_dam)
dam_nofert_impact_stacked_2w[!,:borders] = repeat(["_bordersnorthsouth"],size(dam_nofert_impact_stacked_2w,1))
dam_nofert_impact_stacked_2w[!,:impact] = map(x -> SubString(String(x),1:(length(String(x))-18)), dam_nofert_impact_stacked_2w[!,:impact])

dam_nofert_impact_stacked = vcat(dam_nofert_impact_stacked, dam_nofert_impact_stacked_cb, dam_nofert_impact_stacked_ob, dam_nofert_impact_stacked_2w)
dam_nofert_impact_stacked = join(dam_nofert_impact_stacked, regions_fullname, on=:fundregion)

for s in ssps
    dam_nofert_impact_stacked |> @filter(_.year ==2100 && _.scen == s && _.borders == "_currentborders") |> @vlplot(
        mark={:bar}, width=350, height=300,
        x={"fundregion:o", axis={labelFontSize=16, labelAngle=-90}, ticks=false, domain=false, title=nothing, minExtent=80, scale={paddingInner=0.2,paddingOuter=0.2}},
        y={"impact_dam:q", aggregate = :sum, stack = true, title = "Billion USD2005", axis={titleFontSize=18, labelFontSize=16}},
        color={"impact:n",scale={scheme="category20c"},legend={title=string("Impact type"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=18, labelLimit=220}},
        resolve = {scale={y=:independent}}, title={text=string("Damages in 2100, current borders, ", s), fontSize=20}
    ) |> save(joinpath(@__DIR__, "../results/damages/", string("impdam_nofert_",s,"_mitig.png")))
end

# Second: change in exposure when migrating
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

exposed_nofert = join(move_nofert, rename(rename(
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

exposed_nofert = join(exposed_nofert, rename(
    damages_nofert, 
    :fundregion => :origin, 
    :damgdp_nofert_currentborders => :damgdp_nofert_or_currentborders, 
    :damgdp_nofert_closedborders => :damgdp_nofert_or_closedborders, 
    :damgdp_nofert_moreopen => :damgdp_nofert_or_moreopen, 
    :damgdp_nofert_bordersnorthsouth => :damgdp_nofert_or_bordersnorthsouth
)[:,[:year,:scen,:origin,:damgdp_nofert_or_currentborders,:damgdp_nofert_or_closedborders,:damgdp_nofert_or_moreopen,:damgdp_nofert_or_bordersnorthsouth]], on = [:year,:scen,:origin])
exposed_nofert = join(exposed_nofert, rename(
    damages_nofert, 
    :fundregion => :destination, 
    :damgdp_nofert_currentborders => :damgdp_nofert_dest_currentborders, 
    :damgdp_nofert_closedborders => :damgdp_nofert_dest_closedborders, 
    :damgdp_nofert_moreopen => :damgdp_nofert_dest_moreopen, 
    :damgdp_nofert_bordersnorthsouth => :damgdp_nofert_dest_bordersnorthsouth
)[:,[:year,:scen,:destination,:damgdp_nofert_dest_currentborders,:damgdp_nofert_dest_closedborders,:damgdp_nofert_dest_moreopen,:damgdp_nofert_dest_bordersnorthsouth]], on = [:year,:scen,:destination])

for btype in [:_currentborders,:_closedborders,:_moreopen,:_bordersnorthsouth]
    exposed_nofert[!,Symbol(string(:exposure_nofert,btype))] = [exposed_nofert[i,Symbol(string(:move_nofert_net,btype))] >0 ? (exposed_nofert[i,Symbol(string(:damgdp_nofert_dest,btype))] > exposed_nofert[i,Symbol(string(:damgdp_nofert_or,btype))] ? "increase" : "decrease") : (exposed_nofert[i,Symbol(string(:move_nofert_net,btype))] <0 ? ("") : "nomove") for i in 1:size(exposed_nofert,1)]
end

index_r = DataFrame(index=1:16,region=regions)
exposed_nofert = join(exposed_nofert,rename(index_r,:region=>:origin,:index=>:index_or),on=:origin)
exposed_nofert = join(exposed_nofert,rename(index_r,:region=>:destination,:index=>:index_dest),on=:destination)

exposure_nofert_currentborders = by(exposed_nofert, [:year,:scen,:exposure_nofert_currentborders], d -> (popexpo=sum(d.move_nofert_net_currentborders)))
exposure_nofert_closedborders = by(exposed_nofert, [:year,:scen,:exposure_nofert_closedborders], d -> (popexpo=sum(d.move_nofert_net_closedborders)))
exposure_nofert_moreopen = by(exposed_nofert, [:year,:scen,:exposure_nofert_moreopen], d -> (popexpo=sum(d.move_nofert_net_moreopen)))
exposure_nofert_bordersnorthsouth = by(exposed_nofert, [:year,:scen,:exposure_nofert_bordersnorthsouth], d -> (popexpo=sum(d.move_nofert_net_bordersnorthsouth)))
rename!(exposure_nofert_currentborders,:x1=>:popmig_currentborders,:exposure_nofert_currentborders=>:exposure_nofert)
rename!(exposure_nofert_closedborders,:x1=>:popmig_closedborders,:exposure_nofert_closedborders=>:exposure_nofert)
rename!(exposure_nofert_moreopen,:x1=>:popmig_moreopen,:exposure_nofert_moreopen=>:exposure_nofert)
rename!(exposure_nofert_bordersnorthsouth,:x1=>:popmig_bordersnorthsouth,:exposure_nofert_bordersnorthsouth=>:exposure_nofert)
exposure_nofert = join(exposure_nofert_currentborders, exposure_nofert_closedborders, on = [:year,:scen,:exposure_nofert],kind=:outer)
exposure_nofert = join(exposure_nofert, exposure_nofert_moreopen, on = [:year,:scen,:exposure_nofert],kind=:outer)
exposure_nofert = join(exposure_nofert, exposure_nofert_bordersnorthsouth, on = [:year,:scen,:exposure_nofert],kind=:outer)
for name in [:popmig_currentborders,:popmig_closedborders,:popmig_moreopen,:popmig_bordersnorthsouth]
    for i in 1:size(exposure_nofert,1)
        if ismissing(exposure_nofert[i,name])
            exposure_nofert[i,name] = 0.0
        end
    end
end
sort!(exposure_nofert,[:scen,:year,:exposure_nofert])
exposure_nofert[.&(exposure_nofert[!,:year].==2100),:]

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
for i in 1:size(exposed_nofert_all,1)
    if exposed_nofert_all[i,:move] == 0
        exposed_nofert_all[i,:damgdp_nofert_diff] = 0
    end
end
exposed_nofert_all = join(exposed_nofert_all, rename(regions_fullname, :fundregion => :origin, :regionname => :originname), on= :origin)
exposed_nofert_all = join(exposed_nofert_all, rename(regions_fullname, :fundregion => :destination, :regionname => :destinationname), on= :destination)
exposed_nofert_all[!,:scen_btype] = [string(exposed_nofert_all[i,:scen],"_",exposed_nofert_all[i,:btype]) for i in 1:size(exposed_nofert_all,1)]

exposed_nofert_all |> @vlplot(
    mark={:point, size=80}, width=220, columns=4, wrap={"originname:o", title=nothing, header={labelFontSize=24}}, 
    y={"damgdp_nofert_diff:q", axis={labelFontSize=16, titleFontSize=16}, title="Change in exposure, % point"},
    x={"scen:o", title = nothing, axis={labelFontSize=16}},
    size= {"move:q", legend=nothing},
    color={"btype:o",scale={scheme=:dark2},legend={title=string("Migrant outflows"), titleFontSize=24, titleLimit=240, symbolSize=100, labelFontSize=24, labelLimit=260, offset=10}},
    shape="btype:o",
    resolve = {scale={size=:independent}}
) |> save(joinpath(@__DIR__, "../results/damages/", string("exposure_nofert_allscen_mitig.png")))

