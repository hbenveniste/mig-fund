using DelimitedFiles, CSV, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, DataFrames, Query

using MimiFUND

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

em_world = combine(groupby(em,[:year,:scen]),d->(worldem_migFUND=sum(d.em_migFUND),worldem_migFUND_cb=sum(d.em_migFUND_cb),worldem_migFUND_ob=sum(d.em_migFUND_ob),worldem_migFUND_2w=sum(d.em_migFUND_2w)))
em_world_p = em_world[(map(x->mod(x,10)==0,em_world[:,:year])),:]
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
) |> save(joinpath(@__DIR__, "../results/emissions/", "Fig3a.png"))
# Also Fig.S16a for runs without remittances


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)
em_maps = leftjoin(em, isonum_fundregion, on = :fundregion)
em_maps[!,:emdiff_closedborders] = (em_maps[!,:em_migFUND_cb] ./ em_maps[!,:em_migFUND] .- 1) .* 100
em_maps[!,:emdiff_moreopen] = (em_maps[!,:em_migFUND_ob] ./ em_maps[!,:em_migFUND] .- 1) .* 100
em_maps[!,:emdiff_bordersnorthsouth] = (em_maps[!,:em_migFUND_2w] ./ em_maps[!,:em_migFUND] .- 1) .* 100

# Combined, these 20 graphs are Fig.S9
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
