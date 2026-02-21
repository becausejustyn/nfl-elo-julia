"""
    simulation.jl

Monte Carlo simulation functions for NFL seasons and playoff brackets.
Uses frozen Elo ratings (no in-sim rating updates) as specified.

Exports:
  simulate_game         — single game outcome
  simulate_season       — full schedule Monte Carlo
  simulate_bracket_single — one conference bracket → winner
  simulate_super_bowl   — full AFC + NFC + Super Bowl simulation
"""

module Simulation

using DataFrames
include("elo.jl")
using .Elo

export simulate_game, simulate_season, simulate_bracket_single, simulate_super_bowl

"""
    simulate_game(team_a, team_b, ratings; neutral=false) -> String

Simulate a single game via Bernoulli draw on win probability.
Returns the winner's team string.
"""
function simulate_game(team_a::String, team_b::String,
                       ratings::Dict{String, Float64};
                       neutral::Bool = false)::String
    prob_a = win_probability(team_a, team_b, ratings; neutral = neutral)
    return rand() < prob_a ? team_a : team_b
end

"""
    simulate_season(schedule, ratings; n_sims=10_000) -> DataFrame

Monte Carlo simulation over a list of games.

Arguments:
  - schedule : Vector of NamedTuples with fields (team1, team2, neutral)
               team1 is the home team when neutral = false
  - ratings  : Elo ratings dict (not mutated)
  - n_sims   : number of Monte Carlo iterations (default 10,000)

Returns a DataFrame sorted by avg_wins descending.
"""
function simulate_season(schedule::Vector,
                         ratings::Dict{String, Float64};
                         n_sims::Int = 10_000)::DataFrame

    all_teams = unique([t for g in schedule for t in (g.team1, g.team2)])
    win_totals = Dict(t => 0 for t in all_teams)

    for _ in 1:n_sims
        wins = Dict(t => 0 for t in all_teams)
        for game in schedule
            winner = simulate_game(game.team1, game.team2, ratings; neutral = game.neutral)
            wins[winner] += 1
        end
        for (t, w) in wins
            win_totals[t] += w
        end
    end

    results = DataFrame(
        team     = all_teams,
        avg_wins = [win_totals[t] / n_sims for t in all_teams]
    )
    sort!(results, :avg_wins, rev = true)
    return results
end

"""
    simulate_bracket_single(seeds, ratings) -> String

Simulate one 7-team single-elimination conference bracket.
  - seeds : Vector of 7 team strings ordered by seed [1st ... 7th]
  - Seed 1 receives a first-round bye
  - Home field goes to the higher seed through the Conference Championship
  - Conference Championship is played at a neutral site

Returns the conference champion's team string.
"""
function simulate_bracket_single(seeds::Vector{String},
                                  ratings::Dict{String, Float64})::String
    @assert length(seeds) == 7 "Expected 7 seeds, got $(length(seeds))"

    # Wild Card (seed 1 has bye)
    wc = [
        simulate_game(seeds[2], seeds[7], ratings; neutral = false),  # 2 hosts 7
        simulate_game(seeds[3], seeds[6], ratings; neutral = false),  # 3 hosts 6
        simulate_game(seeds[4], seeds[5], ratings; neutral = false),  # 4 hosts 5
    ]

    # Divisional — seed 1 re-enters; higher seed hosts
    div_field  = sort(vcat([seeds[1]], wc), by = t -> findfirst(==(t), seeds))
    d1 = simulate_game(div_field[1], div_field[4], ratings; neutral = false)
    d2 = simulate_game(div_field[2], div_field[3], ratings; neutral = false)

    # Conference Championship — neutral site
    return simulate_game(d1, d2, ratings; neutral = true)
end

"""
    simulate_super_bowl(afc_seeds, nfc_seeds, ratings; n_sims=100_000) -> DataFrame

Full playoff simulation: AFC bracket + NFC bracket + Super Bowl.
Ratings are frozen at final regular-season values (no updates during sim).

Arguments:
  - afc_seeds / nfc_seeds : 7-element Vector of team strings ordered by seed
  - ratings               : final regular-season Elo ratings
  - n_sims                : Monte Carlo iterations (default 100,000)

Returns DataFrame with columns [team, conf_win_pct, sb_win_pct], sorted by sb_win_pct.
"""
function simulate_super_bowl(afc_seeds::Vector{String},
                              nfc_seeds::Vector{String},
                              ratings::Dict{String, Float64};
                              n_sims::Int = 100_000)::DataFrame

    all_teams  = vcat(afc_seeds, nfc_seeds)
    conf_wins  = Dict(t => 0 for t in all_teams)
    sb_wins    = Dict(t => 0 for t in all_teams)

    for _ in 1:n_sims
        afc_winner = simulate_bracket_single(afc_seeds, ratings)
        nfc_winner = simulate_bracket_single(nfc_seeds, ratings)
        conf_wins[afc_winner] += 1
        conf_wins[nfc_winner] += 1

        sb_winner = simulate_game(afc_winner, nfc_winner, ratings; neutral = true)
        sb_wins[sb_winner] += 1
    end

    results = DataFrame(
        team         = all_teams,
        conf_win_pct = [round(conf_wins[t] / n_sims * 100, digits = 2) for t in all_teams],
        sb_win_pct   = [round(sb_wins[t]   / n_sims * 100, digits = 2) for t in all_teams]
    )
    sort!(results, :sb_win_pct, rev = true)
    return results
end

end # module
