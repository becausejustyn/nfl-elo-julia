"""
    run_playoffs.jl

Standalone script to run the NFL playoff bracket simulation.
Loads current Elo ratings (computed by main.jl) and simulates
the full AFC + NFC brackets and Super Bowl.

Usage:
    julia scripts/run_playoffs.jl

Edit the AFC_SEEDS and NFC_SEEDS arrays below to match the
current season's playoff bracket before running.
"""

include(joinpath(@__DIR__, "..", "src", "elo.jl"))
include(joinpath(@__DIR__, "..", "src", "historical.jl"))
include(joinpath(@__DIR__, "..", "src", "simulation.jl"))
include(joinpath(@__DIR__, "..", "src", "plots.jl"))

using .Historical, .Simulation, .EloPlots
using CSV, DataFrames

# ── Configuration ─────────────────────────────────────────────────────────────
const CSV_PATH = "data/nfl_games.csv"  # path to your games CSV
const N_SIMS   = 100_000               # Monte Carlo iterations

# ── Playoff Seeds ─────────────────────────────────────────────────────────────
# Order: [1st seed, 2nd, 3rd, 4th, 5th, 6th, 7th]
# Edit these to reflect the actual playoff bracket each season.

const AFC_SEEDS = ["KC",  "BUF", "BAL", "HOU", "LAC", "DEN", "PIT"]
const NFC_SEEDS = ["DET", "PHI", "LAR", "TB",  "MIN", "WSH", "GB" ]

# ── Run ───────────────────────────────────────────────────────────────────────
println("Loading game data and computing Elo ratings...")
df = Historical.load_games(CSV_PATH)
df, ratings, _ = Historical.compute_historical_elos(df)

println("\nRunning playoff simulation ($(N_SIMS) iterations)...")
results = Simulation.simulate_super_bowl(AFC_SEEDS, NFC_SEEDS, ratings; n_sims = N_SIMS)

println("\n── Super Bowl Win Probability ──────────────────────")
println("  Rank │ Team │ Conf Win % │ SB Win %")
println("  ─────┼──────┼────────────┼─────────")
for (i, row) in enumerate(eachrow(results))
    @printf("  %4d │ %-4s │   %6.2f%%  │  %6.2f%%\n",
            i, row.team, row.conf_win_pct, row.sb_win_pct)
end

# Save results
mkpath("results")
CSV.write("results/playoff_simulation.csv", results)
println("\n→ Saved to results/playoff_simulation.csv")

# Save chart
p = EloPlots.plot_sb_odds(results)
savefig(p, "results/playoff_odds.png")
println("→ Saved to results/playoff_odds.png")
