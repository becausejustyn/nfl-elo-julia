function validate_observations(probs::AbstractVector, results::AbstractVector)
    length(probs) == length(results) || throw(DimensionMismatch(
        "probabilities and results must have the same length",
    ))
    isempty(probs) && throw(ArgumentError("at least one observation is required"))
    all(p -> 0 <= p <= 1, probs) || throw(ArgumentError("probabilities must be between 0 and 1"))
    all(r -> 0 <= r <= 1, results) || throw(ArgumentError("results must be between 0 and 1"))
    return nothing
end

"""
    brier_score(probs, results) -> Float64

Calculate the mean squared error. A value of 0.25 is the random baseline for a
binary result. A lower value is better.
"""
function brier_score(probs::AbstractVector{<:Real}, results::AbstractVector{<:Real})
    validate_observations(probs, results)
    return mean((probs .- results) .^ 2)
end

"""
    log_loss(probs, results; ε=1e-7) -> Float64

Calculate the binary cross-entropy loss. Limit each probability to prevent
`log(0)`. A lower value is better.
"""
function log_loss(probs::AbstractVector{<:Real}, results::AbstractVector{<:Real};
                  ε::Real = 1e-7)
    validate_observations(probs, results)
    0 < ε < 0.5 || throw(ArgumentError("ε must be between 0 and 0.5"))
    clipped = clamp.(probs, ε, 1 - ε)
    return -mean(results .* log.(clipped) .+ (1 .- results) .* log.(1 .- clipped))
end

"""
    accuracy(probs, results) -> Float64

Calculate the fraction of correct predictions. Do not include tied games. Do
not include games that do not have a predicted favorite.
"""
function accuracy(probs::AbstractVector{<:Real}, results::AbstractVector{<:Real})
    validate_observations(probs, results)
    mask = (results .!= 0.5) .& (probs .!= 0.5)
    any(mask) || throw(ArgumentError("no games have a predicted or actual winner"))
    p = probs[mask]
    r = results[mask]
    return mean((p .> 0.5) .== (r .== 1.0))
end

"""
    evaluate_model(df::DataFrame) -> NamedTuple

Print the model metrics. Return the metric values.
"""
function evaluate_model(df::DataFrame)
    required = (:computed_prob1, :result1)
    all(column -> column in propertynames(df), required) ||
        throw(ArgumentError("DataFrame must contain computed_prob1 and result1"))

    bs = brier_score(df.computed_prob1, df.result1)
    ll = log_loss(df.computed_prob1, df.result1)
    acc = accuracy(df.computed_prob1, df.result1)

    println("\n── Model Accuracy Report ($(nrow(df)) games) ──────────────")
    println("  Brier Score  : $(round(bs, digits = 4))   (0.25 = random, lower = better)")
    println("  Log-Loss     : $(round(ll, digits = 4))")
    println("  Accuracy     : $(round(acc * 100, digits = 2))%")
    println("──────────────────────────────────────────────────────────")
    return (; brier_score = bs, log_loss = ll, accuracy = acc)
end
