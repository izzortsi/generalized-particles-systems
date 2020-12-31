export makie_abm

function makie_abm(
        model, agent_step!, model_step!, params=Dict();
        ac="#765db4",
        as=1,
        am=:circle,
        scheduler=model.scheduler,
        offset=nothing,
        when=true,
        spu=1:100,
        equalaspect=true,
        resolution=(1200, 720)
    )

    # initialize data collection stuff
    model0 = deepcopy(model)
    modelobs = Observable(model)

    s = 0 # current step

    # Initialize main layout and abm axis
    scene, layout = layoutscene(resolution=resolution, backgroundcolor=RGBf0(0.98, 0.98, 0.98))
    abmax = layout[1,1] = LAxis(scene)
    mlims = modellims(model)
    Makie.xlims!(abmax, 0, mlims[1])
    Makie.ylims!(abmax, 0, mlims[2])
    equalaspect && (abmax.aspect = AxisAspect(1))

    # initialize abm plot stuff
    ids = scheduler(model)
    colors = ac isa Function ? Observable(to_color.([ac(model[i]) for i in ids])) : to_color(ac)
    sizes  = as isa Function ? Observable([as(model[i]) for i in ids]) : as
    markers = am isa Function ? Observable([am(model[i]) for i in ids]) : am
    pos = Observable([model[i].pos for i in ids])
  
    # Initialize ABM interactive platform + parameter sliders
    Makie.scatter!(abmax.scene, pos;
    color=colors, markersize=sizes, marker=markers, strokewidth=0.0)

    controllayout = layout[1, 2] = GridLayout(tellheight=false)

    slidervals, run, update, spuslider, sleslider, reset = make_abm_controls =
    make_abm_controls!(scene, controllayout, model, params, spu)

    # Running the simulation:
    isrunning = lift(x -> x, run.active)
    
    @async while isrunning[]
        model = modelobs[]
        n = spuslider[]
        Agents.step!(model, agent_step!, model_step!, n)
        ids = scheduler(model)
        update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am, offset)
        sleslider[] == 0 ? yield() : sleep(sleslider[])
        isopen(scene) || break # crucial, ensures computations stop if closed window.
    end

    # Clicking the update button:
    on(update) do clicks
        model = modelobs[]
        update_abm_parameters!(model, params, slidervals)
    end

    # Clicking the reset button
    on(reset) do clicks
        modelobs[] = deepcopy(model0)
        update_abm_plot!(pos, colors, sizes, markers, model0, scheduler(model0), ac, as, am, offset)
        L > 0 && add_reset_line!(axs, s)
        update[] = update[] + 1 # also trigger parameter updates
    end

    display(scene)
    return scene
end

function modellims(model)
    if model.space isa Agents.ContinuousSpace
        model.space.extend
    elseif model.space isa Agents.DiscreteSpace
        size(model.space) .+ 1
    end
end

function update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am, offset)
    if Agents.nagents(model) == 0
        @warn "The model has no agents, we can't plot anymore!"
        error("The model has no agents, we can't plot anymore!")
    end
    if offset == nothing
        pos[] = [model[i].pos for i in ids]
    else
        pos[] = [model[i].pos .+ offset(model[i]) for i in ids]
    end
    if ac isa Function; colors[] = to_color.([ac(model[i]) for i in ids]); end
    if as isa Function; sizes[] = [as(model[i]) for i in ids]; end
    if am isa Function; markers[] = [am(model[i]) for i in ids]; end
end

function make_abm_controls!(scene, controllayout, model, params, spu)
    spusl = labelslider!(scene, "spu =", spu; tellwidth=true)
    if model.space isa Agents.ContinuousSpace
        _s, _v = 0:0.01:1, 0
    else
        _s, _v = 0:0.1:10, 1
    end
    slesl = labelslider!(scene, "sleep =", _s, sliderkw=Dict(:startvalue => _v))
    controllayout[1, :] = spusl.layout
    controllayout[2, :] = slesl.layout

    # rtoggle = LToggle(scene, active=false)
    # rtog_label = LText(scene, lift(x -> x ? "running" : "not running", rtoggle.active))
    # run = hcat(rtoggle, rtog_label)
    run = LToggle(scene, active=false)
    update = LButton(scene, label="update")
    reset = LButton(scene, label="reset")
    controllayout[3, :] = MakieLayout.hbox!(run, update, reset, tellwidth=false)

    slidervals = Dict{Symbol,Observable}()
    for (i, (l, vals)) in enumerate(params)
        startvalue = get(model.properties, l, vals[1])
        sll = labelslider!(scene, string(l), vals; sliderkw=Dict(:startvalue => startvalue))
        slidervals[l] = sll.slider.value # directly add the observable
        controllayout[i + 4, :] = sll.layout
    end
    return slidervals, run, update.clicks, spusl.slider.value, slesl.slider.value, reset.clicks
end

function update_abm_parameters!(model, params, slidervals)
    for l in keys(slidervals)
        v = slidervals[l][]
        model.properties[l] = v
    end
end

function vline!(ax, x; kwargs...)
    linepoints = lift(ax.limits, x) do lims, x
        ymin = minimum(lims)[2]
        ymax = maximum(lims)[2]
        Point2f0.([x, x], [ymin, ymax])
    end
    lines!(ax, linepoints; yautolimits=false, kwargs...)
end

function add_reset_line!(axs, s)
    for ax in axs
        vline!(ax, s; color="#c41818")
    end
end