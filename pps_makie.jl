using Agents, Colors, DrWatson, ImageCore, LinearAlgebra, Random
# using InteractiveChaos, 
# using AgentsPlots
using Dates
# using HDF5, JLD
using JSON
import Statistics: mean
##
using Makie
##
include("model_functions.jl")
include("visualization_functions.jl")
##
using Makie.AbstractPlotting, Observables
using Makie.AbstractPlotting.MakieLayout
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
    :n_particles => 600, 
    :speed => 1.5, 
    :separation => 0.7, 
    :iradius => 1.4, 
    :cohere_factor => 0.23, 
    :separate_factor => 0.15, 
    :match_factor => 0.03,
    :min_nb => 0., 
    :max_nb => 1.
    )

##
# JLD.save("params.jld", "params", params)

##

##

n_steps = 1500
fps = 18

model = initialize_model(dims=(80, 80), params=params)
e = model.space.extend



##

function makie_abm(model, ac="#765db4", as=1, am=:circle, scheduler=model.scheduler; initial_params=model.properties, params_intervals=nothing, resolution=(1280, 720), fps=24, savepath="abm_recording.mp4")
    
    # TODO salvar recording junto com os parametros
    # TODO 
    date = Date(now())
    superfolder = "simulations/simulations_$date"
    timestamp_format = "HH"
    hour = Dates.format(now(), timestamp_format)
    prepath = "$superfolder/$(hour)h/"

    ids = scheduler(model)

    # model-related observables
    modelobs = Observable(model)
    colors = ac isa Function ? Observable(to_color.([ac(model[i]) for i in ids])) : to_color(ac)
    sizes  = as isa Function ? Observable([as(model[i]) for i in ids]) : as
    markers = am isa Function ? Observable([am(model[i]) for i in ids]) : am
    pos = Observable([model[i].pos for i in ids])

    # interaction control observables

    run_obs = Observable{Bool}(false)
    rec_obs = Observable{Bool}(false)
    
    scene, layout = layoutscene(resolution=resolution)
    running_label = LText(scene, lift(x -> x ? "RUNNING" : "HALTED", run_obs))
    recording_label = LText(scene, lift(x -> x ? "RECORDING" : "STOPPED", rec_obs))

    ax1 = layout[1, 1] = LAxis(scene, width=resolution[1] - 100)
    layout[2, 1] = grid!(hcat(running_label, recording_label), tellheight=true, tellwidth=true)

    scatter!(ax1, pos;
    color=colors, markersize=sizes, marker=markers, strokewidth=0.0)

    stream = VideoStream(scene, framerate=fps)

    on(scene.events.keyboardbuttons) do button

        if button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 

            run_obs[] = !run_obs[]
            run_obs[] ? println("Simulation running. $(run_obs[])") : println("Simulation stopped.")

            @async while run_obs[]
                # update observables in scene
                model = modelobs[]
                Agents.step!(model, agent_step!, model_step!, 1)
                ids = scheduler(model)
                update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am)
                
                if !isopen(scene)
                    if !rec_obs[]
                        break
                    else
                
                        new_filepath, tstamp = namefile(prepath, savepath)
                        path = mkpath("$(@__DIR__)/$prepath$tstamp")
                        
                        open("$path/params$tstamp.json", "w") do f 
                            write(f, JSON.json(modelobs[].properties))
                        end

                        save(new_filepath, stream)
                        println("Window closed while recording. Recording stopped. Files saved at $prepath$tstamp.")
                        break
                    end
                end

                sleep(1 / fps)
            end
            # end
        
        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.r]) 

            if !rec_obs[]
                # start recording
                # start a new stream and set a new filename for the recording
                stream = VideoStream(scene, framerate=fps)
                
                #
                rec_obs[] = !rec_obs[]
                println("Recording started.")

                @async while rec_obs[]
                    recordframe!(stream)
                    sleep(1 / fps)
                end

            elseif rec_obs[]
                # save stream and stop recording
                rec_obs[] = !rec_obs[]
                new_filepath, tstamp = namefile(prepath, savepath)
                path = mkpath("$(@__DIR__)/$prepath$tstamp")

                open("$path/params$tstamp.json", "w") do f 
                    write(f, JSON.json(modelobs[].properties))
                end

                save(new_filepath, stream)
                println("Recording stopped. Files saved at $prepath$tstamp.")
            end

        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.p]) 
            nothing
        
        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.p]) 
            nothing

        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.v])
            # save parameters 
            nothing


        end
    end

    return scene, ids, colors, sizes, markers, pos, ac, as, am
end
function namefile(prepath, savepath)
    timestamp_format = "HH:MM:SS"
    tstamp = Dates.format(now(), timestamp_format)
    dot_idx = findlast(isequal('.'), savepath)
    new_filepath = prepath * "$tstamp/" * savepath[1:dot_idx - 1] * "$(tstamp[end - 1:end])" * savepath[dot_idx:end]
    return new_filepath, tstamp
end

##
model = initialize_model(dims=(80, 80), params=params)
e = model.space.extend

scene, p = makie_abm(model)
##



##
ispressed(scene, Keyboard.left_shift)

##
on(scene.events.keyboardbuttons) do button
    if ispressed(scene, AbstractPlotting.Keyboard.left_shift) & AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.i] ∈
        println(button)
    end
end


##
