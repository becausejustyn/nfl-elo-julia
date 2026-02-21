"""
    run_season_sim.jl

Standalone script to simulate win expectations for an upcoming schedule.
Loads current Elo ratings and runs a Monte Carlo season simulation.

Usage:
    julia scripts/run_season_sim.jl

Edit the SCHEDULE vector below to reflect the games you want to simulate.
"""

include(joinpath(@__DIR__, "..", "src", "elo.jl"))
include(joinpath(@__DIR__, "..", "src", "historical.jl"))
include(joinpath(@__DIR__, "..", "src", "simulation.jl"))

using .Historical, .Simulation
using CSV, DataFrames, Printf

# Configuration 
const CSV_PATH = "data/nfl_games.csv"
const N_SIMS   = 50_000

# schedule
# Format: (team1 = HOME team, team2 = AWAY team, neutral = false/true)
# For neutral-site games (e.g. London, Mexico City, Super Bowl) set neutral=true.

const SCHEDULE = [
    (team1 = "KC",  team2 = "BUF",  neutral = false),
    (team1 = "SF",  team2 = "DAL",  neutral = false),
    (team1 = "PHI", team2 = "NE",   neutral = false),
    (team1 = "BAL", team2 = "CIN",  neutral = false),
    (team1 = "DET", team2 = "GB",   neutral = false),
    (team1 = "MIA", team2 = "NYJ",  neutral = false),
    (team1 = "LAC", team2 = "LV",   neutral = false),
    (team1 = "MIN", team2 = "CHI",  neutral = false),
]

# run simulation
println("Loading game data and computing Elo ratings...")
df = Historical.load_games(CSV_PATH)
df, ratings, _ = Historical.compute_historical_elos(df)

println("\nRunning season simulation ($(N_SIMS) iterations)...")
results = Simulation.simulate_season(SCHEDULE, ratings; n_sims = N_SIMS)

println("\n── Expected Wins ───────────────────────")
println("  Rank │ Team │ Avg Wins")
println("  ─────┼──────┼─────────")
for (i, row) in enumerate(eachrow(results))
    @printf("  %4d │ %-4s │  %.2f\n", i, row.team, row.avg_wins)
end

mkpath("results")
CSV.write("results/season_simulation.csv", results)
println("\n→ Saved to results/season_simulation.csv")
