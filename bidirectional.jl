using Distributions
struct BidirectionalSearch <: SearchStrategy end

function initialize(search::BidirectionalSearch, maze::TriMaze)
    # binary representation of uncertainty, tracks whether the current g/h value
    # is based on the heuristic (σ=1) or has been definitely established (σ=0)
    # initially, only the start and goal are certain
    g = map(minimum_distances(maze, maze.start)) do d
        Normal(d, d > 0)
    end
    h = map(minimum_distances(maze, maze.goal)) do d
        Normal(d, d > 0)
    end
    seen = falses(nstate(maze))
    (;g, h, seen)
end

function select(search::BidirectionalSearch, maze::TriMaze, search_state)
    (;g, h, seen) = search_state
    f, s = findmin(states(maze)) do s
        # frontier is implemented in two steps
        seen[s] && return Inf  # don't repeat yourself
        g[s].σ == 0 || h[s].σ == 0 || return Inf  # only select nodes that have information to pass on
        g[s].µ + h[s].µ  + rand() # f(s)
    end
    @assert f ≥ 0
    if isinf(f)
        error("No valid states left.")
    end
    s
end

"Minimum of d1 and d2, preferring certain over uncertain information"
function uncertain_min(d1, d2)
    if d1.σ < d2.σ
        d1
    elseif d1.σ > d2.σ
        d2
    else
        Normal(min(d1.µ, d2.µ), d1.σ)
    end
end

function update!(search::BidirectionalSearch, maze::TriMaze, search_state, s::Int)
    (;g, h, seen) = search_state

    for s1 in neighbors(maze, s)
        g[s1] = uncertain_min(g[s1], g[s] + 1)
        h[s1] = uncertain_min(h[s1], h[s] + 1)
    end
    seen[s] = true
end

function terminate(search::BidirectionalSearch, maze::TriMaze, search_state)
    any(states(maze)) do s
        search_state.g[s].σ == 0 &&
        search_state.h[s].σ == 0
    end
end


