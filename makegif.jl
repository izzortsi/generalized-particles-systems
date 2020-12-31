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