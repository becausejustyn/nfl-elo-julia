module NFLElo

using CSV
using DataFrames
using Dates
using Plots
using Random
using Statistics

include("elo.jl")
include("historical.jl")
include("metrics.jl")
include("simulation.jl")
include("plots.jl")

export accuracy,
       brier_score,
       compute_historical_elos,
       evaluate_model,
       expected_score,
       load_games,
       log_loss,
       mov_multiplier,
       plot_elo_history,
       plot_ratings_bar,
       plot_sb_odds,
       revert_ratings!,
       simulate_bracket_single,
       simulate_game,
       simulate_season,
       simulate_super_bowl,
       update_elo,
       win_probability

end
