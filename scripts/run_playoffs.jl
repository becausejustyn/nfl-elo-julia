using CSV, NFLElo, Plots, Printf, Random

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const CSV_PATH = joinpath(PROJECT_ROOT, "data", "nfl_games.csv")
const RESULTS_PATH = joinpath(PROJECT_ROOT, "results", "playoff_simulation.csv")
const PLOT_PATH = joinpath(PROJECT_ROOT, "results", "playoff_odds.png")
const N_SIMS = 100_000
const RNG_SEED = 2020

# Put the teams in seed order. Put the first seed first.
# Update these lists before you run the script.

const AFC_SEEDS = ["KC", "BUF", "PIT", "TEN", "BAL", "CLE", "IND"]
const NFC_SEEDS = ["GB", "NO", "SEA", "WSH", "TB", "LAR", "CHI"]

println("Loading game data and computing Elo ratings...")
df = load_games(CSV_PATH)
_, ratings, _ = compute_historical_elos(df)

println("\nRunning playoff simulation ($(N_SIMS) iterations)...")
results = simulate_super_bowl(
    AFC_SEEDS,
    NFC_SEEDS,
    ratings;
    n_sims = N_SIMS,
    rng = MersenneTwister(RNG_SEED),
)

println("\n── Super Bowl Win Probability ──────────────────────")
println("  Rank │ Team │ Conf Win % │ SB Win %")
println("  ─────┼──────┼────────────┼─────────")
for (i, row) in enumerate(eachrow(results))
    @printf("  %4d │ %-4s │   %6.2f%%  │  %6.2f%%\n",
            i, row.team, row.conf_win_pct, row.sb_win_pct)
end

mkpath(dirname(RESULTS_PATH))
CSV.write(RESULTS_PATH, results)
println("\nWrote $RESULTS_PATH")

odds_plot = plot_sb_odds(results)
savefig(odds_plot, PLOT_PATH)
println("Wrote $PLOT_PATH")
