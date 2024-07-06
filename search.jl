abstract type SearchStrategy end
const UNKNOWN = 999999999999999  # a flag for representing unknown  values

function search(strategy::SearchStrategy, maze::TriMaze; max_step=1000)
    history = Int[]
    search_state = initialize(strategy, maze)
    for i in 1:max_step
        s = select(strategy, maze, search_state)
        push!(history, s)
        update!(strategy, maze, search_state, s)
        terminate(strategy, maze, search_state) && break
        i == max_step && @warn "hit max_step"
    end
    search_state, history
end

"Minimum distance to state s from every other state"
function minimum_distances(maze::TriMaze, s)
    no_walls = TriMaze(maze.sz)
    dijkstra_shortest_paths(no_walls.graph, [s]).dists
end


struct AStar <: SearchStrategy end

"Create the initial search state"
function initialize(strategy::AStar, maze::TriMaze)
    g = fill(UNKNOWN, nstate(maze))  # cost to reach each state
    g[maze.start] = 0
    h = minimum_distances(maze, maze.goal)  # heuristic cost from each state to goal
    frontier = Set{Int}([maze.start])
    (;g, h, frontier)
end

"Select a state to expand/process next"
function select(strategy::AStar, maze::TriMaze, search_state)
    (;g, h, frontier) = search_state
    isempty(frontier) && error("frontier is empty!")
    # find the state in frontier that minimizes g(s) + h(s)
    argmin(frontier) do s  # https://docs.julialang.org/en/v1/manual/functions/#Do-Block-Syntax-for-Function-Arguments-1
        g[s] + h[s] + rand() # f(s)
    end
end

"Expand state s, updating search_state"
function update!(strategy::AStar, maze::TriMaze, search_state, s::Int)
    (;g, frontier) = search_state
    delete!(frontier, s)
    # note that we are updating the neighbors of s, not s itself
    for s1 in neighbors(maze, s)
        if g[s1] == UNKNOWN
            push!(frontier, s1)
        end
        g[s1] = min(g[s1], g[s] + 1)
    end
end

"Success condition"
terminate(strategy::AStar, maze::TriMaze, search_state) = search_state.g[maze.goal] != UNKNOWN
