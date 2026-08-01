using ArgParse, CSV, DataFrames, NFLElo, Plots, Printf

const PROJECT_ROOT = normpath(joinpath(@__DIR__, ".."))
const RESULTS_DIR = joinpath(PROJECT_ROOT, "results")

function parse_args()
    s = ArgParseSettings(description = "NFL Elo Rating Simulation Pipeline")
    @add_arg_table s begin
        "--csv"
            help = "Read game data from this CSV file."
            default = joinpath(PROJECT_ROOT, "data", "nfl_games.csv")
        "--plot"
            help = "Save plots in the results directory."
            action = :store_true
    end
    return ArgParse.parse_args(s)
end

function main()
    args = parse_args()

    println("\n" * "="^60)
    println("  NFL Elo Simulation Pipeline")
    println("="^60)

    println("\n[1/5] Loading game data from: $(args["csv"])")
    df = load_games(args["csv"])
    println("Loaded $(nrow(df)) games from $(minimum(df.season)) to $(maximum(df.season)).")

    println("\n[2/5] Computing historical Elo ratings...")
    df, ratings, _ = compute_historical_elos(df)
    println("Tracked $(length(ratings)) teams.")

    println("\n[3/5] Evaluating model accuracy...")
    evaluate_model(df)

    println("\n[4/5] Current team rankings:")
    latest_season = maximum(df.season)
    latest_games = df[df.season .== latest_season, :]
    active_teams = Set(vcat(latest_games.team1, latest_games.team2))
    current_ratings = Dict(team => ratings[team] for team in active_teams)
    sorted = sort(collect(current_ratings), by = last, rev = true)
    @printf("  %4s │ %-4s │ %s\n", "Rank", "Team", "Elo")
    println("  ─────┼──────┼────────")
    for (i, (team, elo)) in enumerate(sorted)
        @printf("  %4d │ %-4s │ %.1f\n", i, team, elo)
    end

    println("\n[5/5] Exporting results...")
    mkpath(RESULTS_DIR)

    ratings_df = DataFrame(
        rank = 1:length(sorted),
        team = first.(sorted),
        elo = last.(sorted),
    )
    ratings_path = joinpath(RESULTS_DIR, "elo_ratings_current.csv")
    CSV.write(ratings_path, ratings_df)
    println("  Wrote $ratings_path")

    output_df = select(df, :date, :season, :playoff, :neutral,
                       :team1, :team2, :score1, :score2, :result1,
                       :computed_elo1, :computed_elo2, :computed_prob1)
    predictions_path = joinpath(RESULTS_DIR, "elo_game_predictions.csv")
    CSV.write(predictions_path, output_df)
    println("  Wrote $predictions_path")

    if args["plot"]
        println("\n  Creating the ratings plot...")
        ratings_plot = plot_ratings_bar(current_ratings)
        plot_path = joinpath(RESULTS_DIR, "current_ratings.png")
        savefig(ratings_plot, plot_path)
        println("  Wrote $plot_path")
    end

    println("\nPipeline complete.\n")
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
