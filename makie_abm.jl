export makie_abm

function makie_abm(
        model, agent_step!, model_step!, params=Dict();
        ac="#765db4",
        as=1,
        am=:circle,
        scheduler=model.scheduler,
        offset=nothing,
        mdata=nothing,
        adata=nothing,
        alabels=nothing,
        mlabels=nothing,
        when=true,
        spu=1:100,
        equalaspect=true,
    )

    # initialize data collection stuff
    model0 = deepcopy(model)
    modelobs = Observable(model)

    @assert typeof(model.space) <: Union{Agents.ContinuousSpace,Agents.DiscreteSpace}
    !isnothing(adata) && @assert adata[1] isa Tuple "Only aggregated agent data are allowed."
    !isnothing(alabels) && @assert length(alabels) == length(adata)
    !isnothing(mlabels) && @assert length(mlabels) == length(mdata)
    df_agent = Agents.init_agent_dataframe(model, adata)
    df_model = Agents.init_model_dataframe(model, mdata)
    L = (isnothing(adata) ? 0 : size(df_agent)[2] - 1) + (isnothing(mdata) ? 0 : size(df_model)[2] - 1)
    s = 0 # current step

    # Initialize main layout and abm axis
    scene, layout = layoutscene(resolution=(1000, 500 + L * 100), backgroundcolor=DEFAULT_BG)
    abmax = layout[1,1] = LAxis(scene)
    mlims = modellims(model)
    xlims!(abmax, 0, mlims[1])
    ylims!(abmax, 0, mlims[2])
    equalaspect && (abmax.aspect = AxisAspect(1))

    # initialize abm plot stuff
    ids = scheduler(model)
    colors = ac isa Function ? Observable(to_color.([ac(model[i]) for i in ids])) : to_color(ac)
    sizes  = as isa Function ? Observable([as(model[i]) for i in ids]) : as
    markers = am isa Function ? Observable([am(model[i]) for i in ids]) : am
    if offset == nothing
        pos = Observable([model[i].pos for i in ids])
    else
        pos = Observable([model[i].pos .+ offset(model[i]) for i in ids])
    end

    # Initialize ABM interactive platform + parameter sliders
    scatter!(abmax.scene, pos;
    color=colors, markersize=sizes, marker=markers, strokewidth=0.0)
    controllayout = layout[1, 2] = GridLayout(tellheight=false)
    slidervals, run, update, spuslider, sleslider, reset = make_abm_controls =
    make_abm_controls!(scene, controllayout, model, params, spu)

    # Initialize data plots
    if L > 0
        N = Observable([0]) # steps that data are recorded at.
        data, axs = init_data_plots!(scene, layout, model, df_agent, df_model, adata, mdata, N, alabels, mlabels)
    end

    # Running the simulation:
    isrunning = Observable(false)
    on(run) do clicks; isrunning[] = !isrunning[]; end
    on(run) do clicks
        @async while isrunning[]
            model = modelobs[]
            n = spuslider[]
            Agents.step!(model, agent_step!, model_step!, n)
            if L > 0
                s += n
                if Agents.should_we_collect(s, model, when) # update collected data
                    push!(N.val, s)
                    update_data_plots!(data, axs, model, df_agent, df_model, adata, mdata, N)
                end
            end
            ids = scheduler(model)
            update_abm_plot!(pos, colors, sizes, markers, model, ids, ac, as, am, offset)
            sleslider[] == 0 ? yield() : sleep(sleslider[])
            isopen(scene) || break # crucial, ensures computations stop if closed window.
        end
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
    return scene, df_agent, df_model
end

function modellims(model)
    if model.space isa Agents.ContinuousSpace
        model.space.extend
    elseif model.space isa Agents.DiscreteSpace
        size(model.space) .+ 1
    end
end


function init_data_plots!(scene, layout, model, df_agent, df_model, adata, mdata, N, alabels, mlabels)
    Agents.collect_agent_data!(df_agent, model, adata, 0)
    Agents.collect_model_data!(df_model, model, mdata, 0)
    La = isnothing(adata) ? 0 : size(df_agent)[2] - 1
    Lm = isnothing(mdata) ? 0 : size(df_model)[2] - 1
    data, axs = [], []
    datalayout = layout[2, :] = GridLayout()

    # Plot all quantities
    # TODO: make scatter+line plot 1.
    # TODO: make markers in pixel units.
    for i in 1:La
        x = Agents.aggname(adata[i])
        val = Observable([df_agent[end, x]])
        push!(data, val)
        ax = datalayout[i, :] = LAxis(scene)
        push!(axs, ax)
        ax.ylabel = isnothing(alabels) ? x : alabels[i]
        c = JULIADYNAMICS_COLORS[mod1(i, 3)]
        lines!(ax, N, val, color=c)
        scatter!(ax, N, val, marker=MARKER, markersize=5AbstractPlotting.px, color=c,
                 strokewidth=0.5)
    end
    for i in 1:Lm
        x = Agents.aggname(mdata[i])
        val = Observable([df_model[end, x]])
        push!(data, val)
        ax = datalayout[i + La, :] = LAxis(scene)
        push!(axs, ax)
        ax.ylabel = isnothing(mlabels) ? x : mlabels[i]
        c = JULIADYNAMICS_COLORS[mod1(i + La, 3)]
        lines!(ax, N, val, color=c)
        scatter!(ax, N, val, marker=MARKER, markersize=5AbstractPlotting.px, color=c,
                 strokewidth=0.5)
    end
    if La + Lm > 1
        for ax in @view(axs[1:end - 1]); hidexdecorations!(ax, grid=false); end
    end
    axs[end].xlabel = "step"
    return data, axs
end

function update_data_plots!(data, axs, model, df_agent, df_model, adata, mdata, N)
    Agents.collect_agent_data!(df_agent, model, adata, N[][end])
    Agents.collect_model_data!(df_model, model, mdata, N[][end])
    La = isnothing(adata) ? 0 : size(df_agent)[2] - 1
    Lm = isnothing(mdata) ? 0 : size(df_model)[2] - 1

    for i in 1:La
        o = data[i]
        x = Agents.aggname(adata[i])
        val = df_agent[end, x]
        push!(o[], val)
        o[] = o[] # update plot
    end
    for i in 1:Lm
        o = data[i + La]
        x = Agents.aggname(mdata[i])
        val = df_model[end, x]
        push!(o[], val)
        o[] = o[] # update plot
    end
    # TODO: Maybe we can optimize this by setting the limits ourselves (we have the data)
    for ax in axs; autolimits!(ax); end
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
    run = LButton(scene, label="run")
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
    return slidervals, run.clicks, update.clicks, spusl.slider.value, slesl.slider.value, reset.clicks
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