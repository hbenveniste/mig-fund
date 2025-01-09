using Distributions, CSV, DelimitedFiles


###############################################################################################################################
######################### Function to convert a year value into an integer corresponding to FUND's time index #################
###############################################################################################################################
function getindexfromyear(year::Int)
    baseyear = 1950
    return year - baseyear + 1
end


###############################################################################################################################
######################### Functions to charge parameters of multiple dimensions ###############################################
###############################################################################################################################
# Reads parameter csvs from data directory into a dictionary (parameter_name => default_value).
# For parameters defined as distributions, this sets the value to their mode.
function load_parameters_mig(datadir = joinpath(dirname(@__FILE__), "..", "data"))
    files = readdir(datadir)
    filter!(i -> i != "desktop.ini", files)
    parameters = Dict{Any, Any}(splitext(file)[1] => readdlm(joinpath(datadir,file), ',', comments = true) for file in files)

    prepparameters_mig!(parameters)

    return parameters
end


# For Truncated Gamma distributions, fund uses the mode of the untrucated distribution as its default value.
import StatsBase.mode
function mode(d::Truncated{Gamma{Float64},Continuous})
    return mode(d.untruncated)
end


# Returns the mode for a distributional parameter; returns the value if it's not a distribution.
getbestguess(p) = isa(p, ContinuousUnivariateDistribution) ? mode(p) : p


# Converts the original parameter dictionary loaded from the data files into a dictionary of default parameter values.
# Original dictionary: parameter_name => string of distributions or values from csv file
# Final dictionary: parameter_name => default value
function prepparameters_mig!(parameters)
    for (param_name, p) in parameters
        column_count = size(p,2)
        if column_count == 4
            length_index1 = length(unique(p[:,1]))
            length_index2 = length(unique(p[:,2]))
            length_index3 = length(unique(p[:,3]))
            new_p = Array{Float64}(undef, length_index1, length_index2, length_index3)
            cur_1 = 1
            cur_2 = 1
            cur_3 = 1
            for j in 1:size(p,1)
                new_p[cur_1,cur_2,cur_3] = getbestguess(convertparametervalue(p[j,4]))
                cur_3 += 1
                if cur_3 > length_index3
                    cur_3 = 1
                    cur_2 += 1
                    if cur_2 > length_index2
                        cur_2 = 1
                        cur_1 += 1
                    end
                end
            end
            parameters[param_name] = new_p
        elseif column_count == 5
            length_index1 = length(unique(p[:,1]))
            length_index2 = length(unique(p[:,2]))
            length_index3 = length(unique(p[:,3]))
            length_index4 = length(unique(p[:,4]))
            new_p = Array{Float64}(undef, length_index1, length_index2, length_index3, length_index4)
            cur_1 = 1
            cur_2 = 1
            cur_3 = 1
            cur_4 = 1
            for j in 1:size(p,1)
                new_p[cur_1,cur_2,cur_3,cur_4] = getbestguess(convertparametervalue(p[j,5]))
                cur_4 += 1
                if cur_4 > length_index4
                    cur_4 = 1
                    cur_3 += 1
                    if cur_3 > length_index3
                        cur_3 = 1
                        cur_2 += 1
                        if cur_2 > length_index2
                            cur_2 = 1
                            cur_1 += 1
                        end
                    end
                end
            end
            parameters[param_name] = new_p
        elseif column_count == 6
            length_index1 = length(unique(p[:,1]))
            length_index2 = length(unique(p[:,2]))
            length_index3 = length(unique(p[:,3]))
            length_index4 = length(unique(p[:,4]))
            length_index5 = length(unique(p[:,5]))
            new_p = Array{Float64}(undef, length_index1, length_index2, length_index3, length_index4, length_index5)
            cur_1 = 1
            cur_2 = 1
            cur_3 = 1
            cur_4 = 1
            cur_5 = 1
            for j in 1:size(p,1)
                new_p[cur_1,cur_2,cur_3,cur_4,cur_5] = getbestguess(convertparametervalue(p[j,6]))
                cur_5 += 1
                if cur_5 > length_index5
                    cur_5 = 1
                    cur_4 += 1
                    if cur_4 > length_index4
                        cur_4 = 1
                        cur_3 += 1
                        if cur_3 > length_index3
                            cur_3 = 1
                            cur_2 += 1
                            if cur_2 > length_index2
                                cur_2 = 1
                                cur_1 += 1
                            end
                        end
                    end
                end
            end
            parameters[param_name] = new_p
        end
    end
end


# Takes as input a single parameter value. 
# If the parameter value is a string containing a distribution definition, it returns the distribtion.
# If the parameter value is a number, it returns the number.
function convertparametervalue(pv)
    if isa(pv,AbstractString)
        if startswith(pv,"~") && endswith(pv,")")
            args_start_index = something(findfirst(isequal('('), pv), 0) 
            dist_name = pv[2:args_start_index-1]
            args = split(pv[args_start_index+1:end-1], ';')
            fixedargs = filter(i->!occursin("=", i),args)
            optargs = Dict(split(i,'=')[1]=>split(i,'=')[2] for i in filter(i->occursin("=", i),args))

            if dist_name == "N"
                if length(fixedargs)!=2 error() end
                if length(optargs)>2 error() end

                basenormal = Normal(parse(Float64, fixedargs[1]),parse(Float64, fixedargs[2]))

                if length(optargs)==0
                    return basenormal
                else
                    return Truncated(basenormal,
                        haskey(optargs,"min") ? parse(Float64, optargs["min"]) : -Inf,
                        haskey(optargs,"max") ? parse(Float64, optargs["max"]) : Inf)
                end
            elseif startswith(pv, "~Gamma(")
                if length(fixedargs)!=2 error() end
                if length(optargs)>2 error() end

                basegamma = Gamma(parse(Float64, fixedargs[1]),parse(Float64, fixedargs[2]))

                if length(optargs)==0
                    return basegamma
                else
                    return Truncated(basegamma,
                        haskey(optargs,"min") ? parse(Float64, optargs["min"]) : -Inf,
                        haskey(optargs,"max") ? parse(Float64, optargs["max"]) : Inf)
                end
            elseif startswith(pv, "~Triangular(")
                triang = TriangularDist(parse(Float64, fixedargs[1]), parse(Float64, fixedargs[2]), parse(Float64, fixedargs[3]))
                return triang
            else
                error("Unknown distribution")
            end
        elseif pv=="true"
            return true
        elseif pv=="false"
            return false
        elseif endswith(pv, "y")
            return parse(Int, strip(pv,'y'))
        else
            try
                return parse(Float64, pv)
            catch e
                error(pv)
            end
        end
        return pv
    else
        return pv
    end
end