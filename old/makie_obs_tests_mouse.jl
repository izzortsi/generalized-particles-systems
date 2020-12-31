using Makie
using Makie.AbstractPlotting, Observables
using Makie.AbstractPlotting.MakieLayout
using AbstractPlotting
##
scene, layout = layoutscene(resolution=(1200, 900))
tog = LToggle(scene, active=false)
tlabel = LText(scene, "running?")
layout[1, 2] = grid!(hcat(tog, tlabel), tellheight=false)
ax1 = layout[1, 1] = LAxis(scene, axis=false)
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


##
# a todo clique do mouse, checka se tog tá ativo; se tiver, mantem o loop até q fique inativo
on(scene.events.mousebuttons) do buttons
    # if ispressed(scene, Mouse.left)
    @async while tog.active.val
        timeobs[] = time()
        sleep(1 / 30)
    end
    # end
    return
end


is_mouse_over_relevant_area() = isempty(elements) ? AbstractPlotting.is_mouseinside(scene) : mouseover(scene, elements...)

# AbstractPlotting.is_mouseinside(scene)
# mouseover(scene)

# scene.events.mousebuttons

# onmouseleftclick
# onmouseleftclick(mouseevents) do event
    # do something with the mouseevent
# end

##
tog.active[] = true
##
on(scene.events.keyboardbuttons) do button
    # println(button)

    if button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 
        println('s')
    
    elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.r]) 
        println('r')

    elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.p]) 
        println('p')
    
    elseif button == Set(AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.s]) 
        println('s')


    end
# AbstractPlotting.Keyboard.Button[AbstractPlotting.Keyboard.r]

##

    on(scene.events.mousebuttons) do buttons
    # if ispressed(scene, Mouse.left)
        @async while tog.active.val
            timeobs[] = time()
            sleep(1 / 30)
        end
    # end
        return
    end

##

