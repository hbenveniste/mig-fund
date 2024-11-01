using DelimitedFiles
using Statistics

using MimiFUND

include("helper_mig.jl")
include("mig_SocioEconomicComponent.jl")
include("MigrationComponent.jl")
include("AddpopComponent.jl")
include("AddimpactComponent.jl")
include("scenconverter.jl")

# Run FUND with added migration dynamics, using as input SSP scenarios transformed for zero migration to ensure consistency

const path_datamigdir = joinpath(@__DIR__, "../data_mig")

function getmigrationmodel(;datamigdir=path_datamigdir,scen="SSP2",migyesno="mig")
    # first get original fund
    m = getfund()
    
    # load migration parameters
    param_mig = MimiFUND.load_default_parameters(datamigdir)

    # load migration parameters with 3 dimensions
    param_mig_3 = load_parameters_mig(joinpath(datamigdir,"../data_mig_3d"))

    # load input scenarios
    param_scen = MimiFUND.load_default_parameters(joinpath(path_datamigdir, "../scen"))

    # add dimension for age groups
    set_dimension!(m, :agegroups, 0:120)

    # delete base FUND socioeconomic component
    delete!(m, :socioeconomic)

    # add mig_socioeconomic and migration components
    add_comp!(m, scenconverter, before=:scenariouncertainty)
    add_comp!(m, mig_socioeconomic, :socioeconomic, after=:geography)
    add_comp!(m, migration, after=:impactaggregation)
    add_comp!(m, addimpact, after=:migration)
    add_comp!(m, addpop, after=:migration)

    # set input scenarios
    set_param!(m, :scenconverter, :population, param_scen[Symbol("pop_",migyesno,"_",scen,"_update")])
    set_param!(m, :scenconverter, :income, param_scen[Symbol("gdp_",migyesno,"_",scen,"_update")])
    set_param!(m, :scenconverter, :energuse, param_scen[Symbol("en_",migyesno,"_",scen,"_update")])
    set_param!(m, :scenconverter, :emission, param_scen[Symbol("em_",migyesno,"_",scen,"_update")])

    # set parameters for migration component
    set_param!(m, :migration, :lifeexp, param_scen[Symbol("lifeexp_",scen)])
    update_param!(m, :currtax, param_scen[Symbol("cp_",scen)])
    set_param!(m, :migration, :distance, param_mig[:distance])
    set_param!(m, :migration, :migdeathrisk, param_mig[:migdeathrisk])
    set_param!(m, :migration, :ageshare, param_mig[:ageshare])
    set_param!(m, :migration, :agegroupinit, param_mig_3["agegroupinit_update"])
    set_param!(m, :migration, :remres, param_mig[:remres_update])
    set_param!(m, :migration, :remcost, param_mig[:remcost_update])
    set_param!(m, :migration, :comofflang, param_mig[:comofflang])
    set_param!(m, :migration, :policy, param_mig[:policy])
    set_param!(m, :migration, :migstockinit, param_mig[:migstockinit_update])
    set_param!(m, :migration, :gravres, param_mig[:gravres_update])

    # scenconverter component connections
    connect_param!(m, :scenariouncertainty, :scenpgrowth, :scenconverter, :scenpgrowth)
    connect_param!(m, :scenariouncertainty, :scenypcgrowth, :scenconverter, :scenypcgrowth)
    connect_param!(m, :scenariouncertainty, :scenaeei, :scenconverter, :scenaeei)
    connect_param!(m, :scenariouncertainty, :scenacei, :scenconverter, :scenacei)

    # scenconverter component connections to other components
    #connect_param!(m, :population, :pop0, :scenconverter, :pop0)
    #connect_param!(m, :socioeconomic, :gdp0, :scenconverter, :gdp0)
    #connect_param!(m, :emissions, :emissint0, :scenconverter, :emissint0)
    
    # mig socioeconomic component connections
    connect_param!(m, :socioeconomic, :area, :geography, :area)
    connect_param!(m, :socioeconomic, :globalpopulation, :population, :globalpopulation)
    connect_param!(m, :socioeconomic, :populationin1, :population, :populationin1)
    connect_param!(m, :socioeconomic, :population, :population, :population)
    connect_param!(m, :socioeconomic, :pgrowth, :scenariouncertainty, :pgrowth)
    connect_param!(m, :socioeconomic, :ypcgrowth, :scenariouncertainty, :ypcgrowth)
    connect_param!(m, :socioeconomic, :mitigationcost, :emissions, :mitigationcost)

    # migration component connections
    connect_param!(m, :migration, :population, :population, :population)
    connect_param!(m, :migration, :populationin1, :population, :populationin1)
    connect_param!(m, :migration, :income, :socioeconomic, :income)
    connect_param!(m, :migration, :popdens, :socioeconomic, :popdens)
    connect_param!(m, :migration, :vsl, :vslvmorb, :vsl)

    # impacts adder connections
    connect_param!(m, :addimpact, :eloss, :impactaggregation, :eloss)
    connect_param!(m, :addimpact, :sloss, :impactaggregation, :sloss)
    connect_param!(m, :addimpact, :entercost, :impactsealevelrise, :entercost)
    connect_param!(m, :addimpact, :leavecost, :impactsealevelrise, :leavecost)
    connect_param!(m, :addimpact, :otherconsloss, :migration, :deadmigcost)
    connect_param!(m, :addimpact, :income, :socioeconomic, :income)

    # population adder connections
    connect_param!(m, :addpop, :dead, :impactdeathmorbidity, :dead)
    connect_param!(m, :addpop, :entermig, :migration, :entermig)
    connect_param!(m, :addpop, :leavemig, :migration, :leavemig)
    connect_param!(m, :addpop, :deadmig, :migration, :deadmig)

    # FUND components that need a connection to mig socioeconomic component
    connect_param!(m, :emissions, :income, :socioeconomic, :income)
    connect_param!(m, :impactagriculture, :income, :socioeconomic, :income)
    connect_param!(m, :impactbiodiversity, :income, :socioeconomic, :income)
    connect_param!(m, :impactcardiovascularrespiratory, :plus, :socioeconomic, :plus)
    connect_param!(m, :impactcardiovascularrespiratory, :urbpop, :socioeconomic, :urbpop)
    connect_param!(m, :impactcooling, :income, :socioeconomic, :income)
    connect_param!(m, :impactdiarrhoea, :income, :socioeconomic, :income)
    connect_param!(m, :impactextratropicalstorms, :income, :socioeconomic, :income)
    connect_param!(m, :impactforests, :income, :socioeconomic, :income)
    connect_param!(m, :impactheating, :income, :socioeconomic, :income)
    connect_param!(m, :impactvectorbornediseases, :income, :socioeconomic, :income)
    connect_param!(m, :impacttropicalstorms, :income, :socioeconomic, :income)
    connect_param!(m, :vslvmorb, :income, :socioeconomic, :income)
    connect_param!(m, :impactwaterresources, :income, :socioeconomic, :income)
    connect_param!(m, :impactsealevelrise, :income, :socioeconomic, :income)
    connect_param!(m, :impactaggregation, :income, :socioeconomic, :income)

    # FUND components that need a connection to the pop adder component
    connect_param!(m, :population, :enter, :addpop, :enter)
    connect_param!(m, :population, :leave, :addpop, :leave)
    connect_param!(m, :population, :dead, :addpop, :deadall)

    # mig socioeconomic component connections to migration component
    connect_param!(m, :socioeconomic, :transfer, :migration, :remittances)
    connect_param!(m, :socioeconomic, :otherconsloss, :migration, :deadmigcost)

    # mig socioeconomic component connections to impacts adder component
    connect_param!(m, :socioeconomic, :eloss, :addimpact, :elossmig)
    connect_param!(m, :socioeconomic, :sloss, :addimpact, :slossmig)

    set_leftover_params!(m, param_mig)

    return m
end
