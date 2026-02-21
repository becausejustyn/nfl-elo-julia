"""
    metrics.jl

Model evaluation functions for the NFL Elo system.
Computes Brier score, log-loss, and directional accuracy
against historical ground-truth results.
"""

module Metrics

using DataFrames, Statistics

export brier_score, log_loss, accuracy, evaluate_model

"""
    brier_score(probs, results) -> Float64

Mean squared error between predicted probabilities and actual outcomes.
  - 0.25 = random baseline (for binary events)
  - Lower is better
"""
function brier_score(probs::Vector{Float64}, results::Vector{Float64})::Float64
    return mean((probs .- results) .^ 2)
end

"""
    log_loss(probs, results; ε=1e-7) -> Float64

Binary cross-entropy loss. Clipped by ε to avoid log(0).
Lower is better.
"""
function log_loss(probs::Vector{Float64}, results::Vector{Float64};
                  ε::Float64 = 1e-7)::Float64
    return -mean(results .* log.(probs .+ ε) .+
                 (1 .- results) .* log.(1 .- probs .+ ε))
end

"""
    accuracy(probs, results) -> Float64

Fraction of games where the predicted favourite won.
Ties (result1 = 0.5) are excluded.
"""
function accuracy(probs::Vector{Float64}, results::Vector{Float64})::Float64
    mask = results .!= 0.5
    p    = probs[mask]
    r    = results[mask]
    return mean((p .> 0.5) .== (r .== 1.0))
end

"""
    evaluate_model(df::DataFrame) -> Nothing

Print a full accuracy report for a games DataFrame that contains
computed_prob1 and result1 columns.
"""
function evaluate_model(df::DataFrame)
    valid = filter(r -> r.computed_prob1 > 0.0, df)

    bs  = brier_score(valid.computed_prob1, valid.result1)
    ll  = log_loss(valid.computed_prob1, valid.result1)
    acc = accuracy(valid.computed_prob1, valid.result1)

    println("\n── Model Accuracy Report (" * string(nrow(valid)) * " games) ──────────────")
    println("  Brier Score  : $(round(bs,  digits=4))   (0.25 = random, lower = better)")
    println("  Log-Loss     : $(round(ll,  digits=4))")
    println("  Accuracy     : $(round(acc * 100, digits=2))%")
    println("──────────────────────────────────────────────────────────")
end

end # module
