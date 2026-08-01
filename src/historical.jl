const REQUIRED_GAME_COLUMNS = (
    :date, :season, :neutral, :playoff, :team1, :team2, :score1, :score2, :result1,
)

function validate_game_columns(df::DataFrame)
    missing_columns = setdiff(REQUIRED_GAME_COLUMNS, propertynames(df))
    isempty(missing_columns) || throw(ArgumentError(
        "Missing required columns: $(join(missing_columns, ", "))",
    ))
    return nothing
end

"""
    load_games(path::String) -> DataFrame

Load the game data from a comma-separated values (CSV) file. Remove rows that
do not have final scores. Sort the games by date.
"""
function load_games(path::AbstractString)
    df = CSV.read(path, DataFrame)
    validate_game_columns(df)
    dropmissing!(df, [:score1, :score2, :result1])
    isempty(df) && throw(ArgumentError("No completed games found in $path"))

    df.date = Date.(string.(df.date))
    df.season = Int.(df.season)
    df.team1 = String.(df.team1)
    df.team2 = String.(df.team2)
    df.neutral = Bool.(df.neutral)
    df.playoff = Bool.(df.playoff)
    df.score1 = Int.(df.score1)
    df.score2 = Int.(df.score2)
    df.result1 = Float64.(df.result1)

    sort!(df, :date)
    return df
end

"""
    compute_historical_elos(df::DataFrame)
        -> (df_enriched, ratings, season_history)

Calculate the ratings in date order. Return the game data, the final ratings,
and the ratings at the end of each season. The game data contains the pre-game
ratings and the win probability for team 1.
"""
function compute_historical_elos(df::DataFrame)
    validate_game_columns(df)
    games = sort(copy(df), :date)

    ratings = Dict{String, Float64}()
    season_history = Dict{Int, Dict{String, Float64}}()
    current_season = nothing

    games[!, :computed_elo1] = zeros(nrow(games))
    games[!, :computed_elo2] = zeros(nrow(games))
    games[!, :computed_prob1] = zeros(nrow(games))

    for row in eachrow(games)
        if isnothing(current_season)
            current_season = row.season
        elseif row.season != current_season
            if row.season < current_season
                throw(ArgumentError("Games must be ordered by season"))
            end
            if !isempty(ratings)
                season_history[current_season] = copy(ratings)
                revert_ratings!(ratings)
            end
            current_season = row.season
        end

        t1, t2 = String(row.team1), String(row.team2)
        r1 = get!(ratings, t1, INITIAL_ELO)
        r2 = get!(ratings, t2, INITIAL_ELO)

        row.computed_elo1 = r1
        row.computed_elo2 = r2
        row.computed_prob1 = win_probability(t1, t2, ratings; neutral = row.neutral)

        new_r1, new_r2 = update_elo(r1, r2, row.score1, row.score2, row.neutral)
        ratings[t1] = new_r1
        ratings[t2] = new_r2
    end

    if !isnothing(current_season)
        season_history[current_season] = copy(ratings)
    end

    return games, ratings, season_history
end
