using CairoMakie
using Makie.Colors
using Graphs

struct TriMaze
    sz::Int
    start::Int
    goal::Int
    walls::Vector{Tuple{Int, Int}}
    graph::SimpleGraph{Int}
    locations::Vector{Point2{Int64}}
end

Graphs.neighbors(maze::TriMaze, s) = neighbors(maze.graph, s)
nstate(maze::TriMaze) = nv(maze.graph)
states(maze::TriMaze) = vertices(maze.graph)

function TriMaze(sz; start=1, goal=0, walls=Tuple{Int, Int}[])
    locations = Point2{Int}[]
    rows = Vector{Int}[]
    for i in 1:sz
        push!(rows, Int[])
        n_row = 2 * (sz + i) - 1
        for j in (1:n_row) .- i
            push!(locations, Point(j, i))
            push!(rows[end], length(locations))
        end
    end
    for i in sz:-1:1
        push!(rows, Int[])
        n_row = 2 * (sz + i) - 1
        for j in (1:n_row) .- i
            push!(locations, Point(j, 1 + 2sz - i))
            push!(rows[end], length(locations))
        end
    end
    locations .+= Point(1 - minimum(first, locations), 0)

    graph = SimpleGraph(rows[end][end])
    for i in eachindex(rows)
        for j in eachindex(rows[i])
            s = rows[i][j]
            if j > 1
                add_edge!(graph, s, s-1)
            end
            if i > 1
                if length(rows[i]) > length(rows[i-1]) && iseven(j)
                    add_edge!(graph, s, rows[i-1][j-1])
                elseif length(rows[i]) == length(rows[i-1]) && isodd(j)
                    add_edge!(graph, s, rows[i-1][j])
                elseif length(rows[i]) < length(rows[i-1]) && isodd(j)
                    add_edge!(graph, s, rows[i-1][j+1])
                end
            end
        end
    end
    for (a, b) in walls
        rem_edge!(graph, Edge(a, b))
    end
    if goal == 0
        goal = nv(graph)
    end
    TriMaze(sz, start, goal, walls, graph, locations)
end


function Makie.plot!(maze::TriMaze, c=nothing; colormap=:Blues, colorrange=nothing, labels=nothing, axes=false)
    (;sz, start, goal, locations, walls) = maze

    g = SimpleGraph(length(locations))
    triangle = [Point(-1., -.5), Point(1., -.5), Point(0, .5)]
    flipped = triangle .* -1

    isdown(i) = isodd(sum(locations[i]) + sz)

    if isnothing(colorrange)
        colorrange = if isnothing(c)
            (0, 1)
        else
            cc = filter(x -> isfinite(x) && abs(x) < 1e12, c)
            lo = isempty(cc) ? 0 : minimum(cc)
            hi = isempty(cc) ? 1 : maximum(cc)
            (lo - max(1, fld((hi - lo), 10)), hi)
        end
    end

    for (i, (x, y)) in enumerate(locations)
        t = isdown(i) ? flipped : triangle
        color = !isnothing(c) && isfinite(c[i]) && abs(c[i]) < 1e12 ? c[i] : :white
        poly!(t .+ Point(x, y); strokecolor = :gray, strokewidth = 1, color, colormap, colorrange)
    end

    locs = map(eachindex(locations)) do i
        locations[i] + (isdown(i) ? Point(0, .2) : Point(0, -.2))
    end

    if labels != nothing
        text = labels == :names ? string.(eachindex(locations)) : labels
        text!(locs; text, align = (:center, :center))
    end

    if !isnothing(start)
        scatter!(Point(locs[start]), color=:black, markersize=24)
        scatter!(Point(locs[start]), color=:white, markersize=18)
    end
    if !isnothing(goal)
        scatter!(Point(locs[goal]), marker=:star5, color=:black, markersize=24)
        scatter!(Point(locs[goal]), marker=:star5, color=:white, markersize=10)
    end

    corners = [
        Point(sz, 0.5),
        Point(3sz, 0.5),
        Point(4sz, sz + 0.5),
        Point(3sz, 2sz + 0.5),
        Point(sz, 2sz + 0.5),
        Point(0, sz + 0.5),
        Point(sz, 0.5),
    ]
    lines!(corners, linewidth=3, color=:black)

    for (a, b) in walls
        if locations[a][2] == locations[b][2]
            lines!([
                locations[a] + (isdown(a) ? Point(0, -0.5) : Point(0, 0.5)),
                locations[b] + (isdown(b) ? Point(0, -0.5) : Point(0, 0.5)),
            ], linewidth=3, color=:black)
        else
            lines!([
                locations[a] + Point(-1, .5),
                locations[b] + Point(1, -.5),
            ], linewidth=3, color=:black)
        end
    end

    ax = current_axis()
    ax.aspect = 2 / √3
    if !axes
        hidedecorations!(ax); hidespines!(ax)
    end
end

