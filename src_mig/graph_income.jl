using DelimitedFiles, CSV, VegaLite, VegaDatasets, FileIO, FilePaths
using Statistics, DataFrames, Query

using MimiFUND

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

ypc_migFUND = vcat(
    collect(Iterators.flatten(m_ssp1_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp2_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp3_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp4_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:])),
    collect(Iterators.flatten(m_ssp5_nomig[:socioeconomic,:ypc][MimiFUND.getindexfromyear(1951):MimiFUND.getindexfromyear(2100),:]))
)
income[:,:ypc_migFUND] = ypc_migFUND


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

rename!(income, :ypc_migFUND => :ypc_currentborders, :ypc_migFUND_cb => :ypc_closedborders, :ypc_migFUND_ob => :ypc_moreopen, :ypc_migFUND_2w => :ypc_bordersnorthsouth)
rename!(income, :gdp_migFUND => :gdp_currentborders, :gdp_migFUND_cb => :gdp_closedborders, :gdp_migFUND_ob => :gdp_moreopen, :gdp_migFUND_2w => :gdp_bordersnorthsouth)

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
gdp_all = innerjoin(gdp_all,regions_fullname, on=:fundregion)

# For SSP2, the below figure is Fig.S6 for the main specification
for s in ssps
    gdp_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"gdp:q", title = nothing, axis={labelFontSize=16}},
        color={"gdp_type:o",scale={scheme=:darkgreen},legend={title=string("GDP levels, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("gdp_",s,"_mitig_update.png")))
end


###################################### Plot geographical maps #####################################
world110m = dataset("world-110m")

isonum_fundregion = CSV.read(joinpath(@__DIR__,"../input_data/isonum_fundregion.csv"), DataFrame)
income_maps = leftjoin(income, isonum_fundregion, on = :fundregion)
income_maps[!,:ypcdiff_closedborders] = (income_maps[!,:ypc_closedborders] ./ income_maps[!,:ypc_currentborders] .- 1) .* 100
income_maps[!,:ypcdiff_moreopen] = (income_maps[!,:ypc_moreopen] ./ income_maps[!,:ypc_currentborders] .- 1) .* 100
income_maps[!,:ypcdiff_bordersnorthsouth] = (income_maps[!,:ypc_bordersnorthsouth] ./ income_maps[!,:ypc_currentborders] .- 1) .* 100

# For SSP2, the combination of the four below gives Fig.1.
for s in ["SSP2"]
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypc_currentborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("GDP per capita levels by 2100 for current borders, ", s),fontSize=24}, 
        color = {"ypc_currentborders:q", scale={scheme=:greens}, legend={title=string("USD2005/cap"), titleFontSize=20, titleLimit=220, symbolSize=60, labelFontSize=24, labelLimit=220, offset=2}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypc_currentborders_", s, "_mitig_update.png")))
end
for s in ["SSP2"]
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_closedborders)]}}],
        projection={type=:naturalEarth1}, title = {text=string("Closed borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_closedborders)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypcdiff",:_closedborders,"_", s, "_mitig_update.png")))
end
for s in ["SSP2"]
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_moreopen)]}}],
        projection={type=:naturalEarth1}, title = {text=string("More open borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_moreopen)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypcdiff",:_moreopen,"_", s, "_mitig_update.png")))
end
for s in ["SSP2"]
    @vlplot(width=800, height=600) + @vlplot(mark={:geoshape, stroke = :lightgray}, 
        data={values=world110m, format={type=:topojson, feature=:countries}}, 
        transform = [{lookup=:id, from={data=filter(row -> row[:scen] == s && row[:year] == 2100, income_maps), key=:isonum, fields=[string(:ypcdiff,:_bordersnorthsouth)]}}],
        projection={type=:naturalEarth1}, title = {text=string("North/South borders, 2100, ", s),fontSize=24}, 
        color = {Symbol(string(:ypcdiff,:_bordersnorthsouth)), type=:quantitative, scale={domain=[-2,2], scheme=:redblue}, legend={title="% vs current", titleFontSize=20, symbolSize=60, labelFontSize=24}}
    ) |> save(joinpath(@__DIR__, "../results/world_maps/", string("ypcdiff",:_bordersnorthsouth,"_", s, "_mitig_update.png")))
end


###################################### Look at net remittances flows for different border policies ############################################
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
netrem_all = innerjoin(netrem_all,regions_fullname, on=:fundregion)

# For SSP2, the below figure is Fig.S5 for the main specification
for s in ssps
    netrem_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.scen == s) |> @vlplot(
        mark={:line, strokeWidth = 4}, width=300, height=250, columns=4, wrap={"regionname:o", title=nothing, header={labelFontSize=24}}, 
        x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
        y={"netrem:q", title = nothing, axis={labelFontSize=16}},
        color={"netrem_type:o",scale={scheme=:darkmulti},legend={title=string("Net remittances, ",s), titleFontSize=20, titleLimit=240, symbolSize=60, labelFontSize=24, labelLimit=280, offset=2}},
        resolve = {scale={y=:independent}}
    ) |> save(joinpath(@__DIR__, "../results/income/", string("netrem_",s,"_mitig_update.png")))
end


################################################### Plot share of income sent as remittances #################################################
rem = DataFrame(
    year = repeat(years, outer = length(ssps)*length(regions)*length(regions)),
    scen = repeat(ssps,inner = length(regions)*length(years)*length(regions)),
    origin = repeat(regions, outer = length(ssps)*length(regions), inner=length(years)),
    destination = repeat(regions, outer = length(ssps), inner=length(years)*length(regions))
)

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
remshare_all = innerjoin(remshare_all,rename(regions_fullname,:fundregion=>:origin,:regionname=>:originname), on=:origin)
remshare_all = innerjoin(remshare_all,rename(regions_fullname,:fundregion=>:destination,:regionname=>:destinationname), on=:destination)

remshare_all |> @filter(_.year >= 2015 && _.year <= 2100 && _.remshare_type == String("remshare_currentborders")) |> @vlplot(
    mark={:errorband, extent=:ci}, width=300, height=250, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24, titleFontSize=20}}, 
    x={"year:o", axis={labelFontSize=16, values = 2010:10:2100}, title=nothing},
    y={"remshare:q", title = "Share of migrant income", axis={labelFontSize=16,titleFontSize=20,}},
    color={"scen:o",scale={scheme=:category10},legend={title=string("Remshare"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}}
) |> save(joinpath(@__DIR__, "../results/income/", string("FigS4_update.png")))