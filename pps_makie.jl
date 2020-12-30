using Agents, AgentsPlots, Colors, DrWatson, ImageCore, LinearAlgebra, Random

##
using Makie
##
using InteractiveChaos
##
import Statistics: mean
##
include("aux_funs.jl")
##

initialize_model()

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

##
scene, df = interactive_abm(model, agent_step!, model_step!, params_intervals; as=0.8, mdata=mdata, mlabels=mlabels)
##
scene
##
stream = VideoStream(scene, framerate=fps)
##
recordframe!(stream)
##
stream
##
save("/simulation.mp4", stream)
# record(p1[1], "particles.mp4"; framerate=fps)
##


##



# using LinearAlgebra

# using AbstractPlotting

scene = Scene(raw=true, camera=cam2d!, resolution=(500, 500))
r = LinRange(0, 3, 4)
the_time = Node(time())
last_open = false
@async while true
    global last_open
    the_time[] = time()
    # this is a bit awkward, since the isopen(scene) is false
    # as long as the scene isn't displayed
    last_open && !isopen(scene) && break
    last_open = isopen(scene)
    sleep(1 / 30)
end
pos = lift(scene.events.mouseposition, the_time) do mpos, t
    map(LinRange(0, 2pi, 60)) do i
        circle = Point2f0(sin(i), cos(i))
        mouse = to_world(scene, Point2f0(mpos))
        secondary = (sin((i * 10f0) + t) * 0.09) * normalize(circle)
        (secondary .+ circle) .+ mouse
    end
end
lines!(scene, pos)
p1 = scene[end]
p2 = Makie.scatter!(
    scene,
    pos, markersize=0.1f0,
    marker=:star5,
    color=p1.color,
)[end]
center!(scene)
t = Theme(raw=true, camera=campixel!)
b1 = button(t, "color")
b2 = button(t, "marker")
msize = slider(t, 0.1:0.01:0.5)
on(b1[end][:clicks]) do c
    p1.color = rand(RGBAf0)
end
markers = ('π', '😹', '⚃', '◑', '▼')
on(b2[end][:clicks]) do c
    p2.marker = markers[rand(1:5)]
end
on(msize[end][:value]) do val
    p2.markersize = val
end

final = hbox(
    vbox(b1, b2, msize),
    scene
)

##
rand(markers)
# Do not execute beyond this point!
##

RecordEvents(final, "output")


