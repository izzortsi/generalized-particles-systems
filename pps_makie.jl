using Agents, Colors, Dates, DrWatson, ImageCore, JSON, LinearAlgebra, Observables, Random
using Makie, Makie.AbstractPlotting, Makie.AbstractPlotting.MakieLayout

import Statistics: mean
##
include("model_functions.jl")
include("visualization_functions.jl")
##


cmap = colormap("RdBu", mid=0.5)


mdata = [avg_nbsize, avg_activation]
mlabels = ["average num neighbors", "average acivation"]

params_intervals = Dict(
    :iradius => 0.1:0.1:8.0,
    :cohere_factor => 0.1:0.01:0.6, 
    :separation => 0.1:0.1:8.0, 
    :separate_factor => 0.1:0.01:0.6, 
    :match_factor => 0.005:0.001:0.1
    )

##

params = Dict(
    :n_particles => 5000, 
    :speed => 1.3, 
    :separation => 0.7, 
    :iradius => 1.4, 
    :cohere_factor => 0.23, 
    :separate_factor => 0.15, 
    :match_factor => 0.03,
    :min_nb => 0., 
    :max_nb => 1.
    )
##

params = Dict(
    :n_particles => 5000, 
    :speed => 1.3, 
    :separation => 0.8, 
    :iradius => 1.7, 
    :cohere_factor => 0.25, 
    :separate_factor => 0.18, 
    :match_factor => 0.084,
    :min_nb => 0., 
    :max_nb => 1.
    )


##
fps = 20

model = initialize_model(dims=(100, 100), params=params)
e = model.space.extend

scene, p = makie_abm(model, ac, 0.6, params_intervals=params_intervals; fps=fps, resolution=(720, 480))

##
