module TSPUtils

export haversine_distance, distance_matrix, find_closest_point, get_travel_route

# Compute Haversine distance between two points on the sphere's surface using their latitude and longitude.
function haversine_distance(lat1, lon1, lat2, lon2)
    R = 6371  # Use Earth's radius in kilometers

    # Convert latitude and longitude from degrees to radians
    dLat = (lat2 - lat1) * π / 180
    dLon = (lon2 - lon1) * π / 180

    a = sin(dLat / 2)^2 + cos(lat1 * π / 180) * cos(lat2 * π / 180) * sin(dLon / 2)^2
    c = 2 * atan(sqrt(a), sqrt(1 - a))
    
    # Return the distance in kilometers
    return R * c
end

# Create a distance matrix for the given points.
function distance_matrix(points)
    n = length(points)
    dist_matrix = Matrix{Float64}(undef, n, n)

    # Fill matrix with distances between each pair of points
    for i in 1:n
        for j in 1:n
            if i == j
                dist_matrix[i, j] = 0
            else
                lat1, lon1 = points[i]
                lat2, lon2 = points[j]
                dist_matrix[i, j] = haversine_distance(lat1, lon1, lat2, lon2)
            end
        end
    end
    return dist_matrix
end

# Identify the closest point to a given coordinate from an array of points.
function find_closest_point(coord::Tuple{Float64,Float64}, points::Array{Tuple{Float64,Float64},1})
    lat1, lon1 = coord
    distances = [haversine_distance(lat1, lon1, lat2, lon2) for (lat2, lon2) in points]
    min_distance_index = argmin(distances)
    # Return the closest point and its index
    return points[min_distance_index], min_distance_index
end

# Construct a travel route based on an adjacency matrix (X), where each row in X represents a location, 
# and a 1 in the jth column indicates that j is the next location in the route from this location.
function get_travel_route(X)
    N = size(X, 1)
    route = [1]  # Start from location 1
    current_point = 1  

    # Loop until all locations are covered
    while length(route) < N
        next_points = findall(X[current_point, :] .== 1)

        found_next_point = false
        # Find an unvisited point to travel next
        for next_point in next_points
            if next_point ∉ route || (length(route) == N - 1 && next_point == 1)
                push!(route, next_point)
                current_point = next_point
                found_next_point = true
                break
            end
        end

        # Break loop and return incomplete route if no valid next point is found
        if !found_next_point
            break
        end
    end

    return route
end
end
