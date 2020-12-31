using Agents, Colors, DrWatson, ImageCore, LinearAlgebra, Random
# using InteractiveChaos, 
# using AgentsPlots

import Statistics: mean
##
using Makie
##
include("aux_funs.jl")
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


n_steps = 1500
fps = 18

model = initialize_model(dims=(80, 80), params=params)
e = model.space.extend



##

function makie_abm(model, ac="#765db4", as=1, am=:circle, scheduler=model.scheduler; resolution=(1280, 720), fps=24)
    
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
    color=colors, markersize=sizes, marker=markers, strokewidth=0.0, resolution=resolution)

    keyboard_interactions(scene, modelobs, pos, colors, sizes, markers, ac, as, am, run_obs, rec_obs, fps)

    return scene, ids, colors, sizes, markers, pos, ac, as, am
end
##

##

function keyboard_interactions(scene, modelobs, pos, colors, sizes, markers, ac, as, am, run_obs, rec_obs, fps)

    stream = VideoStream(scene, framerate=fps)

    on(scene.events.keyboardbuttons) do button

        if button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 

            run_obs[] = !run_obs[]
            run_obs[] ? println("Simulation running.") : println("Simulation stopped.")

            @async while run_obs[]
                # update observables in scene
                model = modelobs[]
                Agents.step!(model, agent_step!, model_step!, n)
                ids = scheduler(model)
                update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am)
                isopen(scene) || break # crucial, ensures computations stop if closed window.
                sleep(1 / fps)
            end
            # end
        
        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.r]) 

            if !rec_obs[]
                # start recording
                rec_obs[] = !rec_obs[]
                println("Recording started.")

                @async while rec_obs[]
                    recordframe!(stream)
                    sleep(1 / fps)
                end

            elseif rec_obs[]
                # save stream and stop recording
                rec_obs[] = !rec_obs[]
                savepath = "test_rec.mp4"
                save(savepath, stream)
                println("Recording stopped. File saved at $savepath.")
            end

        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.p]) 
            println('p')

            # save parameters
        
        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 
            println('s')

            # restart simulation with current parameters and same initial conditions

        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 
            println('s')

            # restart simulation with current parameters and random initial conditions
        
        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 
            println('s')

            # restart simulation with random parameters and random initial conditions

        elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 
            println('s')

            # randomize parameters while still running

        end

    end
end

##
makie_abm(model)
##

function update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am)
    
    if Agents.nagents(model) == 0
        @warn "The model has no agents, we can't plot anymore!"
        error("The model has no agents, we can't plot anymore!")
    end
    
    pos[] = [model[i].pos for i in ids]
    
    if ac isa Function; colors[] = to_color.([ac(model[i]) for i in ids]); end
    if as isa Function; sizes[] = [as(model[i]) for i in ids]; end
    if am isa Function; markers[] = [am(model[i]) for i in ids]; end
end

