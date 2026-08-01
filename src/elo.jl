const K = 20.0
const HFA = 65.0
const INITIAL_ELO = 1500.0
const REVERT_FRAC = 1 / 3
const REVERT_MEAN = 1500.0

"""
    expected_score(r_a, r_b) -> Float64

Calculate the win probability for team A. Use a 400-point Elo scale.
"""
expected_score(r_a::Real, r_b::Real) = 1 / (1 + 10^((r_b - r_a) / 400))

"""
    mov_multiplier(score_winner, score_loser, elo_diff) -> Float64

Calculate the margin-of-victory multiplier.

`elo_diff` is the pre-game rating of the winner minus the pre-game rating of the
loser. It includes the home-field adjustment.
"""
function mov_multiplier(score_winner::Integer, score_loser::Integer, elo_diff::Real)
    mov = score_winner - score_loser
    return log(abs(mov) + 1) * (2.2 / (elo_diff * 0.001 + 2.2))
end

"""
    update_elo(r_a, r_b, score_a, score_b, is_neutral) -> (new_r_a, new_r_b)

Calculate the Elo ratings after a game. Team A is at home when `is_neutral` is
false. The function applies the K-factor, home-field adjustment, and
margin-of-victory multiplier.
"""
function update_elo(r_a::Real, r_b::Real,
                    score_a::Integer, score_b::Integer,
                    is_neutral::Bool)
    adj_r_a = is_neutral ? r_a : r_a + HFA
    exp_a = expected_score(adj_r_a, r_b)
    exp_b = 1 - exp_a

    actual_a = score_a > score_b ? 1.0 : score_a == score_b ? 0.5 : 0.0
    actual_b = 1 - actual_a

    if score_a != score_b
        winner_score = max(score_a, score_b)
        loser_score = min(score_a, score_b)
        elo_diff = score_a > score_b ? adj_r_a - r_b : r_b - adj_r_a
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

Move each rating toward the mean. By default, move each rating by one third of
the difference from 1500.
"""
function revert_ratings!(ratings::Dict{String, Float64};
                         mean::Float64 = REVERT_MEAN,
                         frac::Float64 = REVERT_FRAC)
    for (team, rating) in ratings
        ratings[team] = rating + frac * (mean - rating)
    end
    return ratings
end

"""
    win_probability(team_a, team_b, ratings; neutral=false) -> Float64

Calculate the win probability for team A. Set `neutral` to true for a game at a
neutral site.
"""
function win_probability(team_a::AbstractString, team_b::AbstractString,
                         ratings::Dict{String, Float64};
                         neutral::Bool = false)
    ta, tb = String(team_a), String(team_b)
    r_a = get(ratings, ta, INITIAL_ELO)
    r_b = get(ratings, tb, INITIAL_ELO)
    adj_r_a = neutral ? r_a : r_a + HFA
    return expected_score(adj_r_a, r_b)
end
