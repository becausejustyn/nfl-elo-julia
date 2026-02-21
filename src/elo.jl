"""
    elo.jl

Core Elo rating functions for the NFL Elo simulation system.
Includes win probability, MOV multiplier, rating update, and season reversion.
"""

module Elo

export expected_score, mov_multiplier, update_elo, revert_ratings!, win_probability

# Constants (can be overridden via Config)
const K           = 20.0
const HFA         = 65.0
const INITIAL_ELO = 1500.0
const REVERT_FRAC = 1 / 3
const REVERT_MEAN = 1500.0

"""
    expected_score(r_a, r_b) -> Float64

Logistic win probability for team A given Elo ratings r_a and r_b.
Uses a 400-point scale (standard chess/FiveThirtyEight convention).
"""
function expected_score(r_a::Float64, r_b::Float64)::Float64
    return 1.0 / (1.0 + 10.0^((r_b - r_a) / 400.0))
end

"""
    mov_multiplier(score_winner, score_loser, elo_diff) -> Float64

Margin-of-victory multiplier (FiveThirtyEight method).
Corrects for autocorrelation between pre-game Elo difference and MOV.

  - score_winner / score_loser : final point totals
  - elo_diff                   : winner's pre-game Elo minus loser's (adjusted for HFA)
"""
function mov_multiplier(score_winner::Int, score_loser::Int, elo_diff::Float64)::Float64
    mov = score_winner - score_loser
    return log(abs(mov) + 1.0) * (2.2 / (elo_diff * 0.001 + 2.2))
end

"""
    update_elo(r_a, r_b, score_a, score_b, is_neutral) -> (new_r_a, new_r_b)

Compute updated Elo ratings after a game.
  - team1 (r_a) is treated as the home team when is_neutral = false
  - Applies K-factor, HFA, and MOV multiplier automatically
"""
function update_elo(r_a::Float64, r_b::Float64,
                    score_a::Int, score_b::Int,
                    is_neutral::Bool)

    adj_r_a = is_neutral ? r_a : r_a + HFA
    exp_a   = expected_score(adj_r_a, r_b)
    exp_b   = 1.0 - exp_a

    actual_a = score_a > score_b ? 1.0 : (score_a == score_b ? 0.5 : 0.0)
    actual_b = 1.0 - actual_a

    if score_a != score_b
        winner_score = max(score_a, score_b)
        loser_score  = min(score_a, score_b)
        elo_diff     = score_a > score_b ? (adj_r_a - r_b) : (r_b - adj_r_a)
        mult = mov_multiplier(winner_score, loser_score, elo_diff)
    else
        mult = 1.0
    end

    new_r_a = r_a + K * mult * (actual_a - exp_a)
    new_r_b = r_b + K * mult * (actual_b - exp_b)

    return new_r_a, new_r_b
end

"""
    revert_ratings!(ratings; mean=REVERT_MEAN, frac=REVERT_FRAC)

Apply season-to-season regression toward the mean for all teams in-place.
Default: 1/3 reversion toward 1500.
"""
function revert_ratings!(ratings::Dict{String, Float64};
                         mean::Float64 = REVERT_MEAN,
                         frac::Float64 = REVERT_FRAC)
    for (team, r) in ratings
        ratings[team] = r + frac * (mean - r)
    end
end

"""
    win_probability(team_a, team_b, ratings; neutral=false) -> Float64

Return team_a's win probability given current ratings dict.
Set neutral=true for neutral-site games (no HFA applied).
"""
function win_probability(team_a::AbstractString, team_b::AbstractString,
                         ratings::Dict{String, Float64};
                         neutral::Bool = false)::Float64
    ta, tb  = string(team_a), string(team_b)
    r_a     = get(ratings, ta, INITIAL_ELO)
    r_b     = get(ratings, tb, INITIAL_ELO)
    adj_r_a = neutral ? r_a : r_a + HFA
    return expected_score(adj_r_a, r_b)
end

end # module
