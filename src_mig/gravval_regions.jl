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
    data_endo[!,name] = [exp(data_endo[!,name][i]) for i in 1:size(data_endo, 1)]
end

############################################ Obtain residuals from gravity model at FUND regions level #####################################
# First with only year fixed effects, as in our main specification
ireg = findfirst(beta_endo[!,:regtype].=="reg_endo_yfe")
gravval_endo = join(data_endo, unique(fe_endo_yfe[!,[:year,:fe_YearCategorical]]), on = :year)
rename!(gravval_endo, :flow_AzoseRaftery => :flowmig, :fe_YearCategorical => :fe_year_only)

# No need for the constant beta0 which is an average of year fixed effects
gravval_endo[!,:flowmig_grav] = gravval_endo[:,:pop_orig].^beta_endo[ireg,:b1] .* gravval_endo[:,:pop_dest].^beta_endo[ireg,:b2] .* gravval_endo[:,:ypc_orig].^beta_endo[ireg,:b4] .* gravval_endo[:,:ypc_dest].^beta_endo[ireg,:b5] .* gravval_endo[:,:distance].^beta_endo[ireg,:b7] .* gravval_endo[:,:exp_residual].^beta_endo[ireg,:b8] .* gravval_endo[:,:remcost].^beta_endo[ireg,:b9] .* gravval_endo[:,:comofflang].^beta_endo[ireg,:b10] .* map( x -> exp(x), gravval_endo[!,:fe_year_only]) 
for i in 1:size(gravval_endo,1)
    if gravval_endo[i,:orig] == gravval_endo[i,:dest]
        gravval_endo[i,:flowmig_grav] = 0.0
    end
end

gravval_endo[!,:diff_flowmig] = gravval_endo[!,:flowmig] .- gravval_endo[!,:flowmig_grav]

# Transpose to FUND region * region level. 
iso3c_fundregion = CSV.read("../input_data/iso3c_fundregion.csv")
gravval_endo = join(gravval_endo, rename(iso3c_fundregion, :fundregion => :originregion, :iso3c => :orig), on =:orig)
gravval_endo = join(gravval_endo, rename(iso3c_fundregion, :fundregion => :destinationregion, :iso3c => :dest), on =:dest)

gravval_endo_reg = by(gravval_endo, [:year,:originregion,:destinationregion], df -> (flowmig_reg= sum(skipmissing(df[:,:flowmig])), flowmig_grav_reg=sum(skipmissing(df[:,:flowmig_grav])), diff_flowmig_reg=sum(skipmissing(df[:,:diff_flowmig]))))
gravval_endo_reg[!,:diff_flowmig_reg_btw] = [gravval_endo_reg[i,:originregion] == gravval_endo_reg[i,:destinationregion] ? 0 : gravval_endo_reg[i,:diff_flowmig_reg] for i in 1:size(gravval_endo_reg,1)]

# Use average of period 2000-2015 for projecting residuals in gravity model
res_endo = by(gravval_endo_reg[(gravval_endo_reg[:,:year].>=2000),:], [:originregion,:destinationregion], df -> mean(df[:,:diff_flowmig_reg_btw]))
push!(res_endo,["CAN","CAN",0.0])
push!(res_endo,["USA","USA",0.0])
rename!(res_endo,:x1 => :residuals)
regions = ["USA", "CAN", "WEU", "JPK", "ANZ", "EEU", "FSU", "MDE", "CAM", "LAM", "SAS", "SEA", "CHI", "MAF", "SSA", "SIS"]
regionsdf = DataFrame(originregion = repeat(regions, inner = length(regions)), indexo = repeat(1:16, inner = length(regions)), destinationregion = repeat(regions, outer = length(regions)), indexd = repeat(1:16, outer = length(regions)))
res_endo = join(res_endo, regionsdf, on = [:originregion, :destinationregion])
sort!(res_endo, (:indexo, :indexd))
select!(res_endo, Not([:indexo, :indexd]))
CSV.write(joinpath(@__DIR__,"../data_mig/gravres.csv"), res_endo; writeheader=false)

# Sensitivity analysis: use only period 2010-2015 for projecting residuals in gravity model
res_endo_sa = rename(gravval_endo_reg[(gravval_endo_reg[:,:year].==2010),[:originregion,:destinationregion,:diff_flowmig_reg_btw]],:diff_flowmig_reg_btw=>:residuals)
push!(res_endo_sa,["CAN","CAN",0.0])
push!(res_endo_sa,["USA","USA",0.0])
misscorr = join(regionsdf[:,[:originregion,:destinationregion]],res_endo_sa,on=[:originregion,:destinationregion],kind=:anti)         # dealing with missing corridors for 2010: use values for 2005 instead
misscorrval = join(misscorr, rename(gravval_endo_reg[(gravval_endo_reg[:,:year].==2005),[:originregion,:destinationregion,:diff_flowmig_reg_btw]],:diff_flowmig_reg_btw=>:residuals), on=[:originregion,:destinationregion],kind=:left)
res_endo_sa = vcat(res_endo_sa,misscorrval)
res_endo_sa = join(res_endo_sa, regionsdf, on = [:originregion, :destinationregion])
sort!(res_endo_sa, (:indexo, :indexd))
select!(res_endo_sa, Not([:indexo, :indexd]))
CSV.write(joinpath(@__DIR__,"../data_mig/gravres.csv"), res_endo_sa; writeheader=false)

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
gravval_endo_reg = join(gravval_endo_reg, rename(regions_fullname,:fundregion=>:originregion,:regionname=>:originname), on =:originregion)
gravval_endo_reg = join(gravval_endo_reg, rename(regions_fullname,:fundregion=>:destinationregion,:regionname=>:destinationname), on =:destinationregion)

# Plot residuals for each destination region
gravval_endo_reg |> @vlplot(
    mark={:line}, width=220, columns=4, wrap={"destinationname:o", title=nothing, header={labelFontSize=24}}, 
    y={"diff_flowmig_reg_btw:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"year:o", title = nothing, axis={labelFontSize=16}},
    color={"originname:o",scale={scheme=:tableau20},legend={title=string("Origin region"), titleFontSize=20, titleLimit=240, symbolSize=80, labelFontSize=24, labelLimit=280, offset=2}},
    resolve = {scale={y=:independent}},
    #title = "Residuals for each destination region"
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_endo_nofe_btw_dest.png"))



# With also origin and destination fixed effects 
ireg_fe = findfirst(beta_endo[!,:regtype].=="reg_endo_odyfe")
gravval_endo = join(gravval_endo, unique(fe_endo_odyfe[!,[:year,:fe_YearCategorical]]), on = :year)
gravval_endo = join(gravval_endo, fe_endo_odyfe[!,Not(:fe_YearCategorical)], on = [:year,:orig,:dest], kind = :left)
rename!(gravval_endo, :fe_YearCategorical => :fe_year, :fe_OrigCategorical => :fe_orig, :fe_DestCategorical => :fe_dest)
# For countries with no calibration data, hence no specific fixed effect, I assign as FE the mean of all FE
gravval_endo[!,:fe_orig] = Missings.coalesce.(gravval_endo[!,:fe_orig], mean(unique(fe_endo_odyfe[:,[:orig,:fe_OrigCategorical]])[:,:fe_OrigCategorical]))
gravval_endo[!,:fe_dest] = Missings.coalesce.(gravval_endo[!,:fe_dest], mean(unique(fe_endo_odyfe[:,[:dest,:fe_DestCategorical]])[:,:fe_DestCategorical]))

gravval_endo[!,:flowmig_grav_fe] = gravval_endo[:,:pop_orig].^beta_endo[ireg_fe,:b1] .* gravval_endo[:,:pop_dest].^beta_endo[ireg_fe,:b2] .* gravval_endo[:,:ypc_orig].^beta_endo[ireg_fe,:b4] .* gravval_endo[:,:ypc_dest].^beta_endo[ireg_fe,:b5] .* gravval_endo[:,:distance].^beta_endo[ireg_fe,:b7] .* gravval_endo[:,:exp_residual].^beta_endo[ireg_fe,:b8] .* gravval_endo[:,:remcost].^beta_endo[ireg_fe,:b9] .* gravval_endo[:,:comofflang].^beta_endo[ireg_fe,:b10] .* map( x -> exp(x), gravval_endo[!,:fe_year]) .* map( x -> exp(x), gravval_endo[!,:fe_orig]) .* map( x -> exp(x), gravval_endo[!,:fe_dest])
for i in 1:size(gravval_endo,1)
    if gravval_endo[i,:orig] == gravval_endo[i,:dest]
        gravval_endo[i,:flowmig_grav_fe] = 0.0
    end
end

gravval_endo[!,:diff_flowmig_fe] = gravval_endo[!,:flowmig] .- gravval_endo[!,:flowmig_grav_fe]

# Transpose to FUND region * region level
gravval_endo_fe_reg = by(gravval_endo, [:year,:originregion,:destinationregion], df -> (flowmig_reg= sum(skipmissing(df[:,:flowmig])), flowmig_grav_fe_reg=sum(skipmissing(df[:,:flowmig_grav_fe])), diff_flowmig_fe_reg=sum(skipmissing(df[:,:diff_flowmig_fe]))))
gravval_endo_fe_reg[!,:diff_flowmig_fe_reg_btw] = [gravval_endo_fe_reg[i,:originregion] == gravval_endo_fe_reg[i,:destinationregion] ? 0 : gravval_endo_fe_reg[i,:diff_flowmig_fe_reg] for i in 1:size(gravval_endo_fe_reg,1)]

# Plot: distribution of residuals across corridors, for all 5 periods
# Plot residuals for each destination region
gravval_endo_fe_reg |> @vlplot(
    mark={:text, size=16}, width=220, columns=4, wrap={"destinationregion:o", title=nothing, header={labelFontSize=24}}, 
    y={"diff_flowmig_fe_reg_btw:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"year:o", title = nothing, axis={labelFontSize=16}},
    color={"originregion:o",scale={scheme=:tableau20}},
    text = "originregion:o",
    resolve = {scale={y=:independent}},
    title = "Residuals for each destination region"
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_endo_fe_btw_dest.png"))


########################################### Third: using specification with remshare endogenous, calibrated directly at region level ###################################

############################################ Read data on gravity-derived migration ##############################################
gravity_reg = CSV.read(joinpath(@__DIR__,"../results/gravity/gravity_reg.csv"), DataFrame)
fe_reg_yfe = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_reg_yfe.csv"), DataFrame)
fe_reg_odyfe = CSV.read(joinpath(@__DIR__,"../results/gravity/fe_reg_odyfe.csv"), DataFrame)
beta_reg = CSV.read(joinpath(@__DIR__,"../results/gravity/beta_reg.csv"), DataFrame)

# gravity_reg has data in log. We transform it back.
data_reg = gravity_reg[:,[:year,:originregion,:destinationregion,:migflow,:distance,:pop_o,:pop_d,:ypc_o,:ypc_d,:exp_residual,:remcost,:comofflang]]
for name in [:migflow,:distance,:pop_o,:pop_d,:ypc_o,:ypc_d,:exp_residual,:remcost,:comofflang]
    data_reg[!,name] = [exp(data_reg[!,name][i]) for i in 1:size(data_reg, 1)]
end

############################################ Obtain residuals from gravity model at FUND regions level #####################################
# First with only year fixed effects, as in our main specification
ireg = findfirst(beta_reg[!,:regtype].=="reg_reg_yfe")
gravval_reg = join(data_reg, unique(fe_reg_yfe[!,[:year,:fe_YearCategorical]]), on = :year)
rename!(gravval_reg, :migflow => :flowmig, :fe_YearCategorical => :fe_year_only)

# No need for the constant beta0 which is an average of year fixed effects
gravval_reg[!,:flowmig_grav] = gravval_reg[:,:pop_o].^beta_reg[ireg,:b1] .* gravval_reg[:,:pop_d].^beta_reg[ireg,:b2] .* gravval_reg[:,:ypc_o].^beta_reg[ireg,:b4] .* gravval_reg[:,:ypc_d].^beta_reg[ireg,:b5] .* gravval_reg[:,:distance].^beta_reg[ireg,:b7] .* gravval_reg[:,:exp_residual].^beta_reg[ireg,:b8] .* gravval_reg[:,:remcost].^beta_reg[ireg,:b9] .* gravval_reg[:,:comofflang].^beta_reg[ireg,:b10] .* map( x -> exp(x), gravval_reg[!,:fe_year_only]) 
for i in 1:size(gravval_reg,1)
    if gravval_reg[i,:originregion] == gravval_reg[i,:destinationregion]
        gravval_reg[i,:flowmig_grav] = 0.0
    end
end

gravval_reg[!,:diff_flowmig] = gravval_reg[!,:flowmig] .- gravval_reg[!,:flowmig_grav]
gravval_reg[!,:diff_flowmig_btw] = [gravval_reg[i,:originregion] == gravval_reg[i,:destinationregion] ? 0 : gravval_reg[i,:diff_flowmig] for i in 1:size(gravval_reg,1)]

# Use average of period 2000-2015 for projecting residuals in gravity model
res_reg = by(gravval_reg[(gravval_reg[:,:year].>=2000),:], [:originregion,:destinationregion], df -> mean(df[:,:diff_flowmig_btw]))
push!(res_reg,["CAN","CAN",0.0])
push!(res_reg,["USA","USA",0.0])
rename!(res_reg,:x1 => :residuals)
res_reg = join(res_reg, regionsdf, on = [:originregion, :destinationregion])
sort!(res_reg, (:indexo, :indexd))
select!(res_reg, Not([:indexo, :indexd]))
CSV.write(joinpath(@__DIR__,"../data_mig/gravres.csv"), res_reg; writeheader=false)

# Plot residuals for each destination region
gravval_reg |> @vlplot(
    mark={:text, size=16}, width=220, columns=4, wrap={"destinationregion:o", title=nothing, header={labelFontSize=24}}, 
    y={"diff_flowmig_btw:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"year:o", title = nothing, axis={labelFontSize=16}},
    color={"originregion:o",scale={scheme=:tableau20}},
    text = "originregion:o",
    resolve = {scale={y=:independent}},
    title = "Residuals for each destination region"
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_reg_nofe_btw_dest.png"))



# With also origin and destination fixed effects 
ireg_fe = findfirst(beta_reg[!,:regtype].=="reg_reg_odyfe")
gravval_reg = join(gravval_reg, unique(fe_reg_odyfe[!,[:year,:fe_YearCategorical]]), on = :year)
gravval_reg = join(gravval_reg, fe_reg_odyfe[!,Not(:fe_YearCategorical)], on = [:year,:originregion,:destinationregion], kind = :left)
rename!(gravval_reg, :fe_YearCategorical => :fe_year, :fe_OrigCategorical => :fe_o, :fe_DestCategorical => :fe_d)
# For countries with no calibration data, hence no specific fixed effect, I assign as FE the mean of all FE
gravval_reg[!,:fe_o] = Missings.coalesce.(gravval_reg[!,:fe_o], mean(unique(fe_reg_odyfe[:,[:originregion,:fe_OrigCategorical]])[:,:fe_OrigCategorical]))
gravval_reg[!,:fe_d] = Missings.coalesce.(gravval_reg[!,:fe_d], mean(unique(fe_reg_odyfe[:,[:destinationregion,:fe_DestCategorical]])[:,:fe_DestCategorical]))

gravval_reg[!,:flowmig_grav_fe] = gravval_reg[:,:pop_o].^beta_reg[ireg_fe,:b1] .* gravval_reg[:,:pop_d].^beta_reg[ireg_fe,:b2] .* gravval_reg[:,:ypc_o].^beta_reg[ireg_fe,:b4] .* gravval_reg[:,:ypc_d].^beta_reg[ireg_fe,:b5] .* gravval_reg[:,:distance].^beta_reg[ireg_fe,:b7] .* gravval_reg[:,:exp_residual].^beta_reg[ireg_fe,:b8] .* gravval_reg[:,:remcost].^beta_reg[ireg_fe,:b9] .* gravval_reg[:,:comofflang].^beta_reg[ireg_fe,:b10] .* map( x -> exp(x), gravval_reg[!,:fe_year]) .* map( x -> exp(x), gravval_reg[!,:fe_o]) .* map( x -> exp(x), gravval_reg[!,:fe_d])
for i in 1:size(gravval_reg,1)
    if gravval_reg[i,:originregion] == gravval_reg[i,:destinationregion]
        gravval_reg[i,:flowmig_grav_fe] = 0.0
    end
end

gravval_reg[!,:diff_flowmig_fe] = gravval_reg[!,:flowmig] .- gravval_reg[!,:flowmig_grav_fe]
gravval_reg[!,:diff_flowmig_fe_btw] = [gravval_reg[i,:originregion] == gravval_reg[i,:destinationregion] ? 0 : gravval_reg[i,:diff_flowmig_fe] for i in 1:size(gravval_reg,1)]

# Plot residuals for each destination region
gravval_reg |> @vlplot(
    mark={:text, size=16}, width=220, columns=4, wrap={"destinationregion:o", title=nothing, header={labelFontSize=24}}, 
    y={"diff_flowmig_fe_btw:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals from gravity"},
    x={"year:o", title = nothing, axis={labelFontSize=16}},
    color={"originregion:o",scale={scheme=:tableau20}},
    text = "originregion:o",
    resolve = {scale={y=:independent}},
    title = "Residuals for each destination region"
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_reg_fe_btw_dest.png"))


# Compare residuals for estimation at country and region levels, both for endogenous remshare
gravres_comp = stack(join(rename(gravval_endo_reg[:,union(1:3,7)],:diff_flowmig_reg_btw=>:country), rename(gravval_reg[:,union(1:3,16)],:diff_flowmig_btw=>:region), on=[:year,:originregion,:destinationregion]), 4:5)
rename!(gravres_comp,:variable=>:type,:value=>:residuals)

gravres_comp |> @vlplot(
    mark={:point, filled=true, size=80}, width=260, columns=4, wrap={"destinationregion:o", title="Residuals from gravity estimation for each destination region. Values for 5-year periods over 1990-2015", header={labelFontSize=24,titleFontSize=20}},  
    y={"residuals:q", axis={labelFontSize=16, titleFontSize=16}, title="Residuals"},
    x={"originregion:o", title = "Origin region", axis={labelFontSize=16, titleFontSize=16}},
    resolve = {scale={y=:independent}},
    color={"originregion:o", scale={scheme=:tableau20}, legend={title="Origin region", titleFontSize=16, symbolSize=60, labelFontSize=16}},
    shape={"type:o", scale={range=["circle", "triangle-up"]}, legend={title="Estimation level", titleFontSize=16, symbolSize=60, labelFontSize=16}}
) |> save(joinpath(@__DIR__, "../results/gravity/", "residuals_countryregion.png"))