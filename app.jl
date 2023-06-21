module App
using GenieFramework
using PlotlyBase
@genietools
include("app/TSPUtils.jl")
include("app/TSP.jl")
include("app/TwoOpt.jl")
using .TSPUtils
using .TSP
using .TwoOpt

# use Plotly's scattergeo traces to draw the cities and travel route on a map
function draw_map(points, travel_route)
    route_idx = sortperm(travel_route)   # numbers drawn on points
    trace_points = scattergeo(
        locationmode="ISO-3",
        lon=[point[2] for point in points],
        lat=[point[1] for point in points],
        text=[string(i) for i in route_idx],
        textposition="bottom right",
        textfont=attr(family="Arial Black", size=18, color="blue"),
        mode="markers+text",
        marker=attr(size=10, color="blue"),
        name="Point"
    )

    trace_line = scattergeo(
        locationmode="ISO-3",
        lat=[points[i][1] for i in travel_route],
        lon=[points[i][2] for i in travel_route],
        mode="lines",
        line=attr(width=2, color="red"),
        name="Route"
    )

    trace_return = scattergeo(
        locationmode="ISO-3",
        lat=[points[1][1], points[travel_route[end]][1]],
        lon=[points[1][2], points[travel_route[end]][2]],
        mode="lines",
        line=attr(width=2, color="green"),
        name="Return"
    )

    return [trace_points, trace_line, trace_return]
end

const cities = [
    (51.5074, -0.1278),   # London
    (40.7128, -74.0060),  # New York
    (35.6895, 139.6917),  # Tokyo
    (-33.8688, 151.2093), # Sydney
    (37.7749, -122.4194), # San Francisco
    (19.4326, -99.1332)   # Mexico City
]

# initialize the map with a route
init_map = draw_map(cities, [1, 2, 3, 4, 5, 6])

# define a named model to handle map plot interactions
@app begin
    @out data = init_map                    # map plot data
    @out appLayout = PlotlyBase.Layout(     # map plot layout
        geo=attr(
            projection=attr(type="natural earth"),
            showland=true, showcountries=true,
            landcolor="#EAEAAE", countrycolor="#444444"
        ),
        margin=attr(l=20, r=20, t=20, b=20),
        autosize=true
    )

    @out appConfig = PlotlyBase.PlotConfig()
    @private points = deepcopy(cities)    # list of city coordinates
    @in reset = false                     # boolean for map reset button
    @out loading = false                  # boolean for loading icon on button
    @out max_reached = false              # algorithm switch when max_reached
    @in data_click = Dict{String, Any}()  # data from map click event

    # when clicking on the map, add a new point to the route and calculate
    # the optimal path
    @onchange data_click begin
        loading = true

        # when clicking on an existing point, the data_click dict has a single key "points".
        # Otherwise, the key is "cursor"
        selector = haskey(data_click, "points") ? "points" : "cursor"

        if haskey(data_click, "points")
            lat = data_click["points"][1]["lat"]
            lon = data_click["points"][1]["lon"]
        else
            lat = data_click["cursor"]["lat"]
            lon = data_click["cursor"]["lon"]
        end

        # remove a point when clicking withing a 5px radius
        closest, idx = TSPUtils.find_closest_point((lat, lon), points)
        if sum((closest .- (lat, lon)) .^ 2) < 5
            length(points) > 1 && deleteat!(points, idx)
        else
            push!(points, (lat, lon))
        end

        travel_route = []
        max_reached = length(points) >= 8 ? true : false
        if !max_reached
            # solve the TSP as a linear programming optimization problem
            D = TSPUtils.distance_matrix(points)
            X = TSP.solve_tsp(D)
            travel_route = TSPUtils.get_travel_route(X)
        else
            # use the heuristic TwoOpt algorithm
            initial_route = collect(1:length(points))
            travel_route = two_opt(points, initial_route)
        end
        data = draw_map(points, travel_route)
        loading = false
    end

    # reset the map to its initial status
    @onchange reset begin
        points = deepcopy(cities)
        data = init_map
    end
end

# when the map is loaded, enable tracking of click events
@mounted watchplots()

@page("/", "app.jl.html")

end
