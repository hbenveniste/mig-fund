using CSV, DataFrames, DelimitedFiles, ExcelFiles
using Plots, VegaLite, FileIO, VegaDatasets, FilePaths
using Statistics, Query


############################################ Read data on gravity-derived migration ##############################################
# We use the migration flow data from Azose and Raftery (2018) as presented in Abel and Cohen (2019)
data_ar = CSV.read(joinpath(@__DIR__,"../input_data/data_ar.csv"), DataFrame)
fe_ar_yfe = CSV.read(joinpath(@__DIR__,"../input_data/fe_ar_yfe.csv"), DataFrame)
fe_ar_odyfe = CSV.read(joinpath(@__DIR__,"../input_data/fe_ar_odyfe.csv"), DataFrame)
beta = CSV.read(joinpath(@__DIR__,"../input_data/beta.csv"), DataFrame)


############################################ using specification with remshare endogenous ###################################

############################################ Read data on gravity-derived migration ##############################################
# We use the migration flow data from Azose and Raftery (2018) as presented in Abel and Cohen (2019)
gravity_endo = CSV.read(joinpath(@__DIR__,"../results/gravity/gravity_endo.csv"), DataFrame)
fe_endo_yfe = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_endo_yfe.csv"), DataFrame)
fe_endo_odyfe = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_endo_odyfe.csv"), DataFrame)
beta_endo = CSV.read(joinpath(@__DIR__,"../results/gravity/beta_endo.csv"), DataFrame)

# gravity_endo has data in log. We transform it back.
data_endo = gravity_endo[:,[:year,:orig,:dest,:flow_AzoseRaftery,:distance,:pop_orig,:pop_dest,:ypc_orig,:ypc_dest,:exp_residual,:remcost,:comofflang]]
for name in [:flow_AzoseRaftery,:distance,:pop_orig,:pop_dest,:ypc_orig,:ypc_dest,:exp_residual,:remcost,:comofflang]
    data_endo[!,name] = [exp(data_endo[!,name][i]) for i in eachindex(data_endo[:,1])]
end

############################################ Obtain residuals from gravity model at FUND regions level #####################################
# First with only year fixed effects, as in our main specification
ireg = findfirst(beta_endo[!,:regtype].=="reg_endo_yfe")
gravval_endo = innerjoin(data_endo, unique(fe_endo_yfe[!,[:year,:fe_YearCategorical]]), on = :year)
rename!(gravval_endo, :flow_AzoseRaftery => :flowmig, :fe_YearCategorical => :fe_year_only)

# No need for the constant beta0 which is an average of year fixed effects
gravval_endo[!,:flowmig_grav] = gravval_endo[:,:pop_orig].^beta_endo[ireg,:b1] .* gravval_endo[:,:pop_dest].^beta_endo[ireg,:b2] .* gravval_endo[:,:ypc_orig].^beta_endo[ireg,:b4] .* gravval_endo[:,:ypc_dest].^beta_endo[ireg,:b5] .* gravval_endo[:,:distance].^beta_endo[ireg,:b7] .* gravval_endo[:,:exp_residual].^beta_endo[ireg,:b8] .* gravval_endo[:,:remcost].^beta_endo[ireg,:b9] .* gravval_endo[:,:comofflang].^beta_endo[ireg,:b10] .* map( x -> exp(x), gravval_endo[!,:fe_year_only]) 
for i in eachindex(gravval_endo[:,1])
    if gravval_endo[i,:orig] == gravval_endo[i,:dest]
        gravval_endo[i,:flowmig_grav] = 0.0
    end
end

gravval_endo[!,:diff_flowmig] = gravval_endo[!,:flowmig] .- gravval_endo[!,:flowmig_grav]

# Transpose to FUND region * region level. 
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv", DataFrame)
gravval_endo = innerjoin(gravval_endo, rename(iso3c_fundregion, :fundregion => :originregion, :iso3c => :orig), on =:orig)
gravval_endo = innerjoin(gravval_endo, rename(iso3c_fundregion, :fundregion => :destinationregion, :iso3c => :dest), on =:dest)

gravval_endo_reg = combine(groupby(gravval_endo, [:year,:originregion,:destinationregion]), df -> (flowmig_reg= sum(skipmissing(df[:,:flowmig])), flowmig_grav_reg=sum(skipmissing(df[:,:flowmig_grav])), diff_flowmig_reg=sum(skipmissing(df[:,:diff_flowmig]))))
gravval_endo_reg[!,:diff_flowmig_reg_btw] = [gravval_endo_reg[i,:originregion] == gravval_endo_reg[i,:destinationregion] ? 0 : gravval_endo_reg[i,:diff_flowmig_reg] for i in eachindex(gravval_endo_reg[:,1])]

# Use average of period 2000-2015 for projecting residuals in gravity model
res_endo = combine(groupby(gravval_endo_reg[(gravval_endo_reg[:,:year].>=2000),:], [:originregion,:destinationregion]), df -> mean(df[:,:diff_flowmig_reg_btw]))
push!(res_endo,["CAN","CAN",0.0])
push!(res_endo,["USA","USA",0.0])
rename!(res_endo,:x1 => :residuals)
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
res_endo = innerjoin(res_endo, regionsdf, on = [:originregion, :destinationregion])
sort!(res_endo, (:indexo, :indexd))
select!(res_endo, Not([:indexo, :indexd]))
CSV.write(joinpath(@__DIR__,"../data_mig/gravres.csv"), res_endo; writeheader=false)

# Plot: distribution of residuals across corridors, for all 5 periods
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
gravval_endo_reg = innerjoin(gravval_endo_reg, rename(regions_fullname,:fundregion=>:originregion,:regionname=>:originname), on =:originregion)
gravval_endo_reg = innerjoin(gravval_endo_reg, rename(regions_fullname,:fundregion=>:destinationregion,:regionname=>:destinationname), on =:destinationregion)

# Plot residuals for each destination region
gravval_endo_reg |> @vlplot(
    mark={:line}, width=220, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24}}, 
    y={"diff_flowmig_reg_btw:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"year:o", title = nothing, axis={labelFontSize=16}},
    color={"originname:o",scale={scheme=:tableau20},legend={title=string("Origin region"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}},
    #title = "Residuals for each destination region"
) |> save(joinpath(@__DIR__, "../results/gravity/", "FigS1.png"))
