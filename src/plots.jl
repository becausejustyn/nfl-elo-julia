"""
    plots.jl

Visualization functions for the NFL Elo simulation system.
All functions return a Plots.jl plot object for display or saving.
"""

module EloPlots

using DataFrames, Plots, StatsPlots

export plot_elo_history, plot_ratings_bar, plot_sb_odds

"""
    plot_elo_history(df, teams; title="NFL Team Elo Ratings Over Time") -> Plot

Line chart of Elo ratings over time for the given list of team abbreviations.
Uses pre-game Elo stored in computed_elo1 / computed_elo2 columns.
"""
function plot_elo_history(df::DataFrame, teams::Vector{String};
                           title::String = "NFL Team Elo Ratings Over Time")
    p = plot(title    = title,
             xlabel   = "Season",
             ylabel   = "Elo Rating",
             legend   = :outertopright,
             size     = (950, 480),
             gridalpha = 0.3)

    for team in teams
        # Collect all appearances as team1 or team2
        rows1 = filter(r -> r.team1 == team, df)
        rows2 = filter(r -> r.team2 == team, df)

        seasons = vcat(rows1.season,       rows2.season)
        elos    = vcat(rows1.computed_elo1, rows2.computed_elo2)

        idx     = sortperm(seasons)
        plot!(p, seasons[idx], elos[idx], label = team, lw = 1.8, alpha = 0.85)
    end

    hline!(p, [1500.0], color = :gray, ls = :dash, lw = 1, label = "Mean (1500)")
    return p
end

"""
    plot_ratings_bar(ratings; top_n=32) -> Plot

Horizontal bar chart of current Elo ratings, showing the top N teams.
"""
function plot_ratings_bar(ratings::Dict{String, Float64}; top_n::Int = 32)
    sorted  = sort(collect(ratings), by = x -> x[2], rev = true)[1:min(top_n, length(ratings))]
    teams   = [x[1] for x in sorted]
    elos    = [x[2] for x in sorted]

    p = bar(teams, elos,
            title      = "Current NFL Elo Ratings (Top $(top_n))",
            xlabel     = "Team",
            ylabel     = "Elo Rating",
            legend     = false,
            color      = :steelblue,
            size       = (950, 420),
            rotation   = 45,
            gridalpha  = 0.3,
            ylim       = (minimum(elos) - 30, maximum(elos) + 30))

    hline!(p, [1500.0], color = :gray, ls = :dash, lw = 1.2)
    return p
end

"""
    plot_sb_odds(results::DataFrame) -> Plot

Bar chart of Super Bowl win probabilities from simulate_super_bowl output.
Expects columns: team, sb_win_pct.
"""
function plot_sb_odds(results::DataFrame)
    p = bar(results.team, results.sb_win_pct,
            title      = "Super Bowl Win Probability by Team",
            xlabel     = "Team",
            ylabel     = "Win Probability (%)",
            legend     = false,
            color      = :darkorange,
            size       = (950, 420),
            rotation   = 45,
            gridalpha  = 0.3)
    return p
end

end # module
