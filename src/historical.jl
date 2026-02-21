"""
    historical.jl

Processes a historical NFL game CSV and computes Elo ratings chronologically.
Outputs enriched DataFrame with pre-game Elo and win probability on every row,
plus a season-keyed snapshot Dict for downstream analysis.

Expected CSV columns:
  date, season, neutral, playoff, team1, team2, score1, score2, result1
"""

module Historical

using CSV, DataFrames, Dates
include("elo.jl")
using .Elo

export load_games, compute_historical_elos

"""
    load_games(path::String) -> DataFrame

Load and clean the games CSV. Drops rows with missing scores,
parses dates, and sorts chronologically.
"""
function load_games(path::String)::DataFrame
    df = CSV.read(path, DataFrame)

    df.date    = Date.(string.(df.date))
    df.neutral = Bool.(df.neutral)
    df.playoff = Bool.(df.playoff)
    df.score1  = Int.(df.score1)
    df.score2  = Int.(df.score2)
    df.result1 = Float64.(df.result1)

    dropmissing!(df, [:score1, :score2])
    sort!(df, :date)

    println("Loaded $(nrow(df)) games | Seasons: $(minimum(df.season))–$(maximum(df.season))")
    return df
end

"""
    compute_historical_elos(df::DataFrame)
        -> (df_enriched, ratings, season_history)

Single chronological pass over all games.
Returns:
  - df_enriched     : original DataFrame + computed_elo1, computed_elo2, computed_prob1
  - ratings         : Dict of current (final) Elo ratings for every team
  - season_history  : Dict{Int, Dict{String,Float64}} — end-of-season snapshots
"""
function compute_historical_elos(df::DataFrame)
    ratings        = Dict{String, Float64}()
    season_history = Dict{Int, Dict{String, Float64}}()
    current_season = -1

    df[!, :computed_elo1]  = zeros(Float64, nrow(df))
    df[!, :computed_elo2]  = zeros(Float64, nrow(df))
    df[!, :computed_prob1] = zeros(Float64, nrow(df))

    for row in eachrow(df)
        t1, t2 = row.team1, row.team2

        !haskey(ratings, t1) && (ratings[t1] = Elo.INITIAL_ELO)
        !haskey(ratings, t2) && (ratings[t2] = Elo.INITIAL_ELO)

        # Season boundary
        if row.season != current_season
            if current_season > 0
                season_history[current_season] = copy(ratings)
                revert_ratings!(ratings)
            end
            current_season = row.season
        end

        # Record pre-game state
        row.computed_elo1  = ratings[t1]
        row.computed_elo2  = ratings[t2]
        row.computed_prob1 = win_probability(t1, t2, ratings; neutral = row.neutral)

        # Update
        new_r1, new_r2 = update_elo(ratings[t1], ratings[t2],
                                     row.score1, row.score2, row.neutral)
        ratings[t1] = new_r1
        ratings[t2] = new_r2
    end

    season_history[current_season] = copy(ratings)

    println("Teams tracked: $(length(ratings)) | Seasons snapshotted: $(length(season_history))")
    return df, ratings, season_history
end

end # module
