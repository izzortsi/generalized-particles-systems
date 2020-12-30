using Agents, AgentsPlots, Colors, DrWatson, ImageCore, LinearAlgebra, Random

##
using Makie
##
using InteractiveChaos
##
import Statistics: mean
##


##
abstract type AbstractParticle <: AbstractAgent end

##
mutable struct Particle <: AbstractParticle
    id::Int
    pos::NTuple{2,Float64}
    vel::NTuple{2,Float64}
    speed::Float64
    mass::Float64
    activation::Float64
    interaction_radius::Float64
    nb_size::Float64
end

##
function initialize_model(;
    dims=(100, 100),
    params=Dict(
    :n_particles => 100, 
    :speed => 1.0, 
    :iradius => 4.0, 
    :min_nb => 0., 
    :max_nb => 1., 
    :cohere_factor => 0.25, 
    :separation => 4.0, 
    :separate_factor => 0.25, 
    :match_factor => 0.01)
)

    space2d = ContinuousSpace(2; periodic=true, extend=dims)

    model = ABM(Particle, space2d; scheduler=random_activation, properties=params, warn=false)
    id = 0
    for _ in 1:params[:n_particles]
        id += 1
        pos = Tuple(rand(2) .* dims[1] .- 1)
        vel = Tuple(rand(2) * 2 .- 1)
        mass = randexp() * 0.5 * exp(-0.5)
        speed = params[:speed]
        activation = 0 # rand()
        interaction_radius = params[:iradius]
        nb_size = 0
        particle = Particle(id, pos, vel, speed, mass, activation, interaction_radius, nb_size)
        add_agent!(particle, model)
    end
    index!(model)
    return model
end


##

function model_step!(model)
    nothing
end

function agent_step!(particle, model)
    # Obtain the ids of neighbors within the particle's visual distance
    ids = space_neighbors(particle, model, particle.interaction_radius)
    particle.nb_size = length(ids)

    particle.nb_size > model.max_nb ? model.max_nb = particle.nb_size : nothing
    particle.nb_size < model.min_nb ? model.min_nb = particle.nb_size : nothing
    med_nb = (model.min_nb + model.max_nb) / 2

    (particle.nb_size > med_nb) & (particle.activation < 0.94) ? particle.activation += 0.05 : nothing
    (particle.nb_size <= med_nb) & (particle.activation > 0.11) ? particle.activation -= 0.1 : nothing

    # Compute velocity based on rules defined above
    particle.vel =
        (
            particle.vel .+ cohere(particle, model, ids) .+ separate(particle, model, ids) .+
            match(particle, model, ids)
        ) ./ 2
    particle.vel = particle.vel ./ norm(particle.vel)
    # Move particle according to new velocity and speed
    move_agent!(particle, model, particle.speed)
end

function cohere(particle, model, ids)
    N = max(length(ids), 1)
    particles = model.agents
    coherence = (0.0, 0.0)
    for id in ids
        coherence = coherence .+ get_heading(particles[id], particle) .* (1 + particles[id].activation)
    end
    # particle.deviation = LinearAlgebra.norm(particle.pos .- (coherence )) .* (particle.cohere_factor * particle.separate_factor)
    # println(particle.deviation)
    # particle.deviation > model.max_nb ? model.max_nb = particle.deviation : nothing
    # particle.deviation < model.min_nb ? model.min_nb = particle.deviation : nothing
    return coherence ./ N .* model.cohere_factor
end

function separate(particle, model, ids)
    seperation_vec = (0.0, 0.0)
    N = max(length(ids), 1)
    particles = model.agents
    for id in ids
        neighbor = particles[id]
        if distance(particle, neighbor) < model.separation
            seperation_vec = seperation_vec .- get_heading(neighbor, particle)
        end
    end
    return seperation_vec ./ N .* model.separate_factor
end

function match(particle, model, ids)
    match_vector = (0.0, 0.0)
    N = max(length(ids), 1)
    particles = model.agents
    for id in ids
        match_vector = match_vector .+ particles[id].vel
    end
    return match_vector ./ N .* model.match_factor
end


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

    return gif(anim, "flock.gif", fps=fps)
end


distance(a1, a2) = sqrt(sum((a1.pos .- a2.pos).^2))
get_heading(a1, a2) = a1.pos .- a2.pos

ac(a) = (colorsigned(cmap[1], cmap[50], cmap[end]) ∘ scalesigned(0.0, 0.5, 1.0))(a.activation)
avg_nbsize(model) = mean(collect(a.nb_size for a in allagents(model)))
avg_activation(model) = mean(collect(a.activation for a in allagents(model)))

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
p1 = interactive_abm(model, agent_step!, model_step!, params_intervals; as=0.8, mdata=mdata, mlabels=mlabels)
# record(p1[1], "particles.mp4"; framerate=fps)
##


##
make_gif(1800, cmap)