using DelimitedFiles
using Statistics

using MimiFUND

include("scenconverter.jl")

# Run original FUND with SSP scenarios instead of default scenarios

const path_datascendir = joinpath(@__DIR__, "../scen/") 

function getsspmodel(;datascendir=path_datascendir,scen="SSP2",migyesno="mig")
    # first get original fund
    m = getfund()
    
    # load input scenarios
    param_scen = MimiFUND.load_default_parameters(path_datascendir)

    # add scen converter component
    add_comp!(m, scenconverter, before=:scenariouncertainty)

    # set input scenarios
    set_param!(m, :scenconverter, :population, param_scen[Symbol("pop_",migyesno,"_",scen)])
    set_param!(m, :scenconverter, :income, param_scen[Symbol("gdp_",migyesno,"_",scen)])
    set_param!(m, :scenconverter, :energuse, param_scen[Symbol("en_",migyesno,"_",scen)])
    set_param!(m, :scenconverter, :emission, param_scen[Symbol("em_",migyesno,"_",scen)])

    # scenconverter component connections
    connect_param!(m, :scenariouncertainty, :scenpgrowth, :scenconverter, :scenpgrowth)
    connect_param!(m, :scenariouncertainty, :scenypcgrowth, :scenconverter, :scenypcgrowth)
    connect_param!(m, :scenariouncertainty, :scenaeei, :scenconverter, :scenaeei)
    connect_param!(m, :scenariouncertainty, :scenacei, :scenconverter, :scenacei)

    # scenconverter component connections to other components
    #connect_param!(m, :population, :pop0, :scenconverter, :pop0)
    #connect_param!(m, :socioeconomic, :gdp0, :scenconverter, :gdp0)
    #connect_param!(m, :emissions, :emissint0, :scenconverter, :emissint0)
    
    return m
end

