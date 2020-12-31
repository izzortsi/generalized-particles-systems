using Makie
using Makie.AbstractPlotting, Observables
using Makie.AbstractPlotting.MakieLayout
using AbstractPlotting
##
scene, layout = layoutscene(resolution=(1200, 900))

run_obs = Node{Bool}(false)
rec_obs = Node{Bool}(false)
running_label = LText(scene, lift(x -> x ? "RUNNING" : "HALTED", run_obs))
recording_label = LText(scene, lift(x -> x ? "RECORDING" : "STOPPED", rec_obs))

ax1 = layout[1, 1] = LAxis(scene, width=1000)
layout[2, 1] = grid!(hcat(running_label, recording_label), tellheight=true, tellwidth=true)
trim!(layout)
##
scene
##

xs = -pi:0.01:pi
timeobs = Node(0.0)

phase = lift(x -> (x + 1) * π, timeobs) # Node === Observable
frequency = lift(x -> cos((x + 1) * π), timeobs)
A = lift(x -> sin((1 + x * π)), timeobs)

ys = lift(A, frequency, phase) do amp, fr, ph
    @. 0.3 * cos(amp) * sin(fr * xs - ph)
end

lines!(ax1, xs, ys, color=:blue, linewidth=3)






##
stream = VideoStream(scene, framerate=20)

on(scene.events.keyboardbuttons) do button

    if button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 
        
        run_obs[] = !run_obs[]
        
        run_obs[] ? println("Simulation running.") : println("Simulation stopped.")

        @async while run_obs[]
            
            # update observables in scene

            timeobs[] = time()
            
            sleep(1 / 30)
        end
        # end
    
    elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.r]) 

        if !rec_obs[]
            
            # start recording
            
            rec_obs[] = !rec_obs[]
            
            println("Recording started.")

            @async while rec_obs[]
    
                recordframe!(stream)
                
                sleep(1 / 24)
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

##
# check button pressed with

if ispressed(scene, AbstractPlotting.Keyboard.left_shift)
    println(button, "T")
else
    println(button, "F")
end