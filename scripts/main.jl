"""
    main.jl

Entry point for the NFL Elo simulation pipeline.

Usage:
    julia scripts/main.jl --csv data/nfl_games.csv

Steps:
  1. Load and validate game data
  2. Compute historical Elo ratings (full chronological pass)
  3. Print model accuracy metrics
  4. Display current team rankings
  5. Export ratings and enriched game data to results/
  6. (Optional) Run example playoff simulation
"""

using ArgParse, CSV, DataFrames, Dates

# ── Load project modules ──────────────────────────────────────────────────────
include(joinpath(@__DIR__, "..", "src", "elo.jl"))
include(joinpath(@__DIR__, "..", "src", "historical.jl"))
include(joinpath(@__DIR__, "..", "src", "simulation.jl"))
include(joinpath(@__DIR__, "..", "src", "metrics.jl"))
include(joinpath(@__DIR__, "..", "src", "plots.jl"))

using .Historical, .Simulation, .Metrics, .EloPlots

# ── Argument parsing ──────────────────────────────────────────────────────────
function parse_args()
    s = ArgParseSettings(description = "NFL Elo Rating Simulation Pipeline")
    @add_arg_table s begin
        "--csv"
            help    = "Path to the games CSV file"
            default = "data/nfl_games.csv"
        "--sims"
            help    = "Number of Monte Carlo iterations for playoff simulation"
            arg_type = Int
            default  = 100_000
        "--plot"
            help   = "Save plots to results/ directory"
            action = :store_true
    end
    return parse_args(s)
end

# ── Main pipeline ─────────────────────────────────────────────────────────────
function main()
    args = parse_args()

    println("\n" * "="^60)
    println("  NFL Elo Simulation Pipeline")
    println("="^60)

    # 1. Load data
    println("\n[1/5] Loading game data from: $(args["csv"])")
    df = Historical.load_games(args["csv"])

    # 2. Compute historical Elos
    println("\n[2/5] Computing historical Elo ratings...")
    df, ratings, season_history = Historical.compute_historical_elos(df)

    # 3. Model accuracy
    println("\n[3/5] Evaluating model accuracy...")
    Metrics.evaluate_model(df)

    # 4. Current rankings
    println("\n[4/5] Current team rankings:")
    sorted = sort(collect(ratings), by = x -> x[2], rev = true)
    @printf("  %4s │ %-4s │ %s\n", "Rank", "Team", "Elo")
    println("  ─────┼──────┼────────")
    for (i, (team, elo)) in enumerate(sorted)
        @printf("  %4d │ %-4s │ %.1f\n", i, team, elo)
    end

    # 5. Export results
    println("\n[5/5] Exporting results...")
    mkpath("results")

    ratings_df = DataFrame(
        rank = 1:length(sorted),
        team = [x[1] for x in sorted],
        elo  = [x[2] for x in sorted]
    )
    CSV.write("results/elo_ratings_current.csv", ratings_df)
    println("  → results/elo_ratings_current.csv")

    output_df = select(df, :date, :season, :playoff, :neutral,
                           :team1, :team2, :score1, :score2, :result1,
                           :computed_elo1, :computed_elo2, :computed_prob1)
    CSV.write("results/elo_game_predictions.csv", output_df)
    println("  → results/elo_game_predictions.csv")

    # Optional: plots
    if args["plot"]
        println("\n  Generating plots...")
        p1 = EloPlots.plot_ratings_bar(ratings)
        savefig(p1, "results/current_ratings.png")
        println("  → results/current_ratings.png")
    end

    println("\n✓ Pipeline complete.\n")
end

main()
