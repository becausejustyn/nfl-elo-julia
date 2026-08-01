using CSV, NFLElo, Printf, Random

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const CSV_PATH = joinpath(PROJECT_ROOT, "data", "nfl_games.csv")
const RESULTS_PATH = joinpath(PROJECT_ROOT, "results", "season_simulation.csv")
const N_SIMS = 50_000
const RNG_SEED = 2020

# Team 1 is at home when `neutral` is false.
# Set `neutral` to true for a game at a neutral site.

const SCHEDULE = [
    (team1 = "KC",  team2 = "BUF",  neutral = false),
    (team1 = "SF",  team2 = "DAL",  neutral = false),
    (team1 = "PHI", team2 = "NE",   neutral = false),
    (team1 = "BAL", team2 = "CIN",  neutral = false),
    (team1 = "DET", team2 = "GB",   neutral = false),
    (team1 = "MIA", team2 = "NYJ",  neutral = false),
    (team1 = "LAC", team2 = "OAK",  neutral = false),
    (team1 = "MIN", team2 = "CHI",  neutral = false),
]

println("Loading game data and computing Elo ratings...")
df = load_games(CSV_PATH)
_, ratings, _ = compute_historical_elos(df)

println("\nRunning season simulation ($(N_SIMS) iterations)...")
results = simulate_season(SCHEDULE, ratings; n_sims = N_SIMS, rng = MersenneTwister(RNG_SEED))

println("\n── Expected Wins ───────────────────────")
println("  Rank │ Team │ Avg Wins")
println("  ─────┼──────┼─────────")
for (i, row) in enumerate(eachrow(results))
    @printf("  %4d │ %-4s │  %.2f\n", i, row.team, row.avg_wins)
end

mkpath(dirname(RESULTS_PATH))
CSV.write(RESULTS_PATH, results)
println("\nWrote $RESULTS_PATH")
