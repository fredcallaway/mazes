include("trimaze.jl")
include("figure.jl")
include("search.jl")
include("bidirectional.jl")

# %% --------

maze = TriMaze(3; start=26, goal=9,
    walls=[(1, 9), (20, 21), (10, 11), (30, 31), (34, 35), (24, 25)]
)

figure("maze") do
    plot!(maze; labels=:names)
end

# %% --------

function plot_history!(maze, history)
    x = zeros(Int, nstate(maze))
    for (t, s) in enumerate(history)
        x[s] = t
    end
    plot!(maze, x; labels=[i == 0 ? "" : string(i) for i in x], colormap=:viridis)
end

strategy = AStar()
search_state, history = search(strategy, maze; max_step=30);
@show length(history)
figure("astar", size=(1000, 250)) do
    (;g, h, frontier) = search_state
    fig = current_figure()

    plot_history!(maze, history)

    Axis(fig[1,2], title="g")
    plot!(maze, g)

    Axis(fig[1,3], title="h")
    plot!(maze, h, colormap=:Reds)

    Axis(fig[1,4], title="f")
    f = g .+ h
    plot!(maze, f, colormap=:Purples)
    scatter!(maze.locations[collect(frontier)], color=:yellow)
end

# %% --------

strategy = BidirectionalSearch()
search_state, history = search(strategy, maze; max_step=30);
@show length(history)
figure("bidirectional", size=(1000, 250)) do
    (;g, h, seen) = search_state
    fig = current_figure()

    plot_history!(maze, history)

    Axis(fig[1,2]; title="g")
    plot!(maze, getfield.(g, :µ))

    Axis(fig[1,3]; title="h")
    plot!(maze, getfield.(h, :µ); colormap=:Reds)

    Axis(fig[1,4]; title="f")
    f = getfield.(g, :µ) .+ getfield.(h, :µ)
    plot!(maze, f; colormap=:Purples)
    scatter!(maze.locations[.!seen], color=:yellow)
end
