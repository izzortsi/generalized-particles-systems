##

function make_gif(n_steps, cmap)
    anim = @animate for i in 0:n_steps
        i > 0 && Agents.step!(model, agent_step!, 1)
        # println([model.max_nb, model.min_nb])
        p1 = plotabm(
            model;
            # am=bird_triangle,
            as=0.8,
            ac=ac,
            showaxis=false,
            grid=false,
            xlims=(0, e[1]),
            ylims=(0, e[2]),
        )
        title!(p1, "step $(i)")
    end

    return gif(anim, "abm_gif.gif", fps=fps)
end

function scatter_abm(model, ac="#765db4", as=1, am=:circle, scheduler=model.scheduler, resolution=(1280, 720))

    ids = scheduler(model)
    colors = ac isa Function ? Observable(to_color.([ac(model[i]) for i in ids])) : to_color(ac)
    sizes  = as isa Function ? Observable([as(model[i]) for i in ids]) : as
    markers = am isa Function ? Observable([am(model[i]) for i in ids]) : am
    pos = Observable([model[i].pos for i in ids])

    scene = scatter(pos;
    color=colors, markersize=sizes, marker=markers, strokewidth=0.0, resolution=resolution)

    display(scene)

    return scene, ids, colors, sizes, markers, pos, ac, as, am
end

function record_simulation(model::AgentBasedModel, interval::AbstractRange; framerate=30, ac="#765db4", as=1, am=:circle, scheduler=model.scheduler, resolution=(1280, 720))

    scene, ids, colors, sizes, markers, pos, ac, as, am = scatter_abm(model, ac, as, am, scheduler, resolution)

    record(scene, "abm_animation.mp4", interval; framerate=framerate) do t
        Agents.step!(model, agent_step!, model_step!, 1)
        update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am)
    end
end


"""wrapping all of this within a function seems to yield a scope issue with the async loop. it is not working as it is, but it's a 
better choice if said issue is overcome"""
function keyboard_interactions(scene, modelobs, pos, colors, sizes, markers, ac, as, am, run_obs, rec_obs, fps)

    stream = VideoStream(scene, framerate=fps)

    on(scene.events.keyboardbuttons) do button

        if button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 

            run_obs[] = !run_obs[]
            run_obs[] ? println("Simulation running. $(run_obs[])") : println("Simulation stopped.")

            @async while run_obs[]
                # update observables in scene
                println(1)
                model = modelobs[]
                Agents.step!(model, agent_step!, model_step!, 1)
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