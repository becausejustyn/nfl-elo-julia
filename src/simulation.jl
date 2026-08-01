"""
    simulate_game(team_a, team_b, ratings; neutral=false, rng=Random.default_rng())

Simulate one game. Return the team name of the winner.
"""
function simulate_game(team_a::AbstractString, team_b::AbstractString,
                       ratings::Dict{String, Float64};
                       neutral::Bool = false,
                       rng::AbstractRNG = Random.default_rng())
    prob_a = win_probability(team_a, team_b, ratings; neutral = neutral)
    return rand(rng) < prob_a ? String(team_a) : String(team_b)
end

"""
    simulate_season(schedule, ratings; n_sims=10_000) -> DataFrame

Simulate all games in a schedule.

Arguments:
  - `schedule`: A vector of named tuples. Each tuple has the fields `team1`,
    `team2`, and `neutral`. Team 1 is at home when `neutral` is false.
  - `ratings`: Elo ratings. The function does not change these ratings.
  - `n_sims`: The number of simulations. The default is 10,000.

The function returns a table. It sorts the table by average wins.
"""
function simulate_season(schedule::Vector,
                         ratings::Dict{String, Float64};
                         n_sims::Int = 10_000,
                         rng::AbstractRNG = Random.default_rng())
    n_sims > 0 || throw(ArgumentError("n_sims must be greater than zero"))
    all_teams = unique([String(t) for g in schedule for t in (g.team1, g.team2)])
    win_totals = Dict(t => 0 for t in all_teams)

    for _ in 1:n_sims
        wins = Dict(t => 0 for t in all_teams)
        for game in schedule
            winner = simulate_game(
                game.team1,
                game.team2,
                ratings;
                neutral = game.neutral,
                rng,
            )
            wins[winner] += 1
        end
        for (team, wins_for_team) in wins
            win_totals[team] += wins_for_team
        end
    end

    results = DataFrame(
        team = all_teams,
        avg_wins = [win_totals[t] / n_sims for t in all_teams]
    )
    sort!(results, :avg_wins, rev = true)
    return results
end

"""
    simulate_bracket_single(seeds, ratings) -> String

Simulate one conference bracket. The bracket must have seven teams.

Put the teams in seed order. Put the first seed first. The first seed does not
play in the wild-card round. The higher seed is at home in all conference games.

The function returns the name of the conference champion.
"""
function simulate_bracket_single(seeds::AbstractVector{<:AbstractString},
                                 ratings::Dict{String, Float64};
                                 rng::AbstractRNG = Random.default_rng())
    length(seeds) == 7 || throw(ArgumentError("Expected 7 seeds, got $(length(seeds))"))
    allunique(seeds) || throw(ArgumentError("Each seed must have a different team"))
    teams = String.(seeds)

    # The first seed does not play in this round.
    wc = [
        simulate_game(teams[2], teams[7], ratings; rng),
        simulate_game(teams[3], teams[6], ratings; rng),
        simulate_game(teams[4], teams[5], ratings; rng),
    ]

    seed_number = Dict(team => seed for (seed, team) in enumerate(teams))
    div_field = sort(vcat([teams[1]], wc), by = team -> seed_number[team])
    d1 = simulate_game(div_field[1], div_field[4], ratings; rng)
    d2 = simulate_game(div_field[2], div_field[3], ratings; rng)

    championship = sort([d1, d2], by = team -> seed_number[team])
    return simulate_game(championship[1], championship[2], ratings; rng)
end

"""
    simulate_super_bowl(afc_seeds, nfc_seeds, ratings; n_sims=100_000) -> DataFrame

Simulate the American Football Conference (AFC) bracket, the National Football
Conference (NFC) bracket, and the Super Bowl. The simulation does not change the
ratings.

Arguments:
  - `afc_seeds` and `nfc_seeds`: Seven team names in seed order.
  - `ratings`: The Elo ratings at the end of the regular season.
  - `n_sims`: The number of simulations. The default is 100,000.

The function returns the conference and Super Bowl win percentages for each team.
"""
function simulate_super_bowl(afc_seeds::AbstractVector{<:AbstractString},
                             nfc_seeds::AbstractVector{<:AbstractString},
                             ratings::Dict{String, Float64};
                             n_sims::Int = 100_000,
                             rng::AbstractRNG = Random.default_rng())
    n_sims > 0 || throw(ArgumentError("n_sims must be greater than zero"))
    all_teams = string.(vcat(afc_seeds, nfc_seeds))
    allunique(all_teams) || throw(ArgumentError("A team can occur only once in the playoffs"))
    conf_wins = Dict(team => 0 for team in all_teams)
    sb_wins = Dict(team => 0 for team in all_teams)

    for _ in 1:n_sims
        afc_winner = simulate_bracket_single(afc_seeds, ratings; rng)
        nfc_winner = simulate_bracket_single(nfc_seeds, ratings; rng)
        conf_wins[afc_winner] += 1
        conf_wins[nfc_winner] += 1

        sb_winner = simulate_game(afc_winner, nfc_winner, ratings; neutral = true, rng)
        sb_wins[sb_winner] += 1
    end

    results = DataFrame(
        team = all_teams,
        conf_win_pct = [round(conf_wins[t] / n_sims * 100, digits = 2) for t in all_teams],
        sb_win_pct = [round(sb_wins[t] / n_sims * 100, digits = 2) for t in all_teams]
    )
    sort!(results, :sb_win_pct, rev = true)
    return results
end
