"""
    plot_elo_history(df, teams; title="NFL Team Elo Ratings Over Time") -> Plot

Plot the Elo rating history for each specified team. The function uses the
pre-game ratings in `computed_elo1` and `computed_elo2`.
"""
function plot_elo_history(df::DataFrame, teams::Vector{String};
                           title::String = "NFL Team Elo Ratings Over Time")
    p = plot(
        title = title,
        xlabel = "Date",
        ylabel = "Elo Rating",
        legend = :outertopright,
        size = (950, 480),
        gridalpha = 0.3,
    )

    for team in teams
        rows1 = filter(r -> r.team1 == team, df)
        rows2 = filter(r -> r.team2 == team, df)

        dates = vcat(rows1.date, rows2.date)
        elos = vcat(rows1.computed_elo1, rows2.computed_elo2)
        isempty(dates) && continue

        order = sortperm(dates)
        plot!(p, dates[order], elos[order], label = team, lw = 1.8, alpha = 0.85)
    end

    hline!(p, [1500.0], color = :gray, ls = :dash, lw = 1, label = "Mean (1500)")
    return p
end

"""
    plot_ratings_bar(ratings; top_n=32) -> Plot

Plot the current Elo ratings. Show the top `top_n` teams.
"""
function plot_ratings_bar(ratings::Dict{String, Float64}; top_n::Int = 32)
    top_n > 0 || throw(ArgumentError("top_n must be greater than zero"))
    isempty(ratings) && throw(ArgumentError("ratings must not be empty"))
    count = min(top_n, length(ratings))
    sorted = sort(collect(ratings), by = last, rev = true)[1:count]
    teams = first.(sorted)
    elos = last.(sorted)

    p = bar(
        teams,
        elos,
        title = "Current NFL Elo Ratings (Top $count)",
        xlabel = "Team",
        ylabel = "Elo Rating",
        legend = false,
        color = :steelblue,
        size = (950, 420),
        rotation = 45,
        gridalpha = 0.3,
        bottom_margin = 8Plots.mm,
        ylim = (minimum(elos) - 30, maximum(elos) + 30),
    )

    hline!(p, [1500.0], color = :gray, ls = :dash, lw = 1.2)
    return p
end

"""
    plot_sb_odds(results::DataFrame) -> Plot

Plot the Super Bowl win probabilities. The table must contain the columns
`team` and `sb_win_pct`.
"""
function plot_sb_odds(results::DataFrame)
    return bar(
        results.team,
        results.sb_win_pct,
        title = "Super Bowl Win Probability by Team",
        xlabel = "Team",
        ylabel = "Win Probability (%)",
        legend = false,
        color = :darkorange,
        size = (950, 420),
        rotation = 45,
        gridalpha = 0.3,
        bottom_margin = 8Plots.mm,
    )
end
