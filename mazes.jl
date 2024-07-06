using Graphs
include("figure.jl")

graph = grid((10, 10))
n_state = nv(graph)
locations = collect(Iterators.product(1:10, 1:10))

# make a wall
I = reshape(1:100, 10, 10)

walls = [
    (7, 1:7),
    (1:4, 2),
]

for wall in walls
    w1, w2 = wall
    if w1 isa Int
        for i in w2
            rem_edge!(graph, Edge(I[w1, i], I[w1+1, i]))
        end
    else
        for i in w1
            rem_edge!(graph, Edge(I[i, w2], I[i, w2+1]))
        end
    end
end

function plot_heat(x)
    figure() do
        X = collect(reshape(x, 10, 10))
        if eltype(X) == Float64
            X[isinf.(X)] .= NaN
        end
        heatmap(X, grid=:false, colormap=:Blues)

        for (w1, w2) in walls
            @show w1 w2
            if w1 isa Int
                lines!([w1+.5], [first(w2) - .5, last(w2) + .5], color=:black, linewidth=7)
            else
                lines!([first(w1) - .5, last(w1) + .5], [w2+.5], color=:black, linewidth=7)
            end
        end

        scatter!(Point(locations[start]), color=:black, markersize=24)
        scatter!(Point(locations[start]), color=:white, markersize=20)
        scatter!(Point(locations[goal]), marker=:star5, color=:black, markersize=24)
        scatter!(Point(locations[goal]), marker=:star5, color=:white, markersize=10)
    end
end

plot_heat(h)

# %% --------

start = 22
goal = 38

h = map(vertices(graph)) do i
    sum(abs.(locations[goal] .- locations[i]))
end

seen = falses(n_state)
g = fill(100, n_state)
g[start] = 0

history = fill(NaN, 10, 10)
for i in 1:100
    f = g .+ h
    s = argmin(f .+ seen .* Inf)
    if s == goal
        break
    end
    for s1 in neighbors(graph, s)
        g[s1] = g[s] + 1
    end
    seen[s] = true
    history[s] = i
end

plot_heat(history)
