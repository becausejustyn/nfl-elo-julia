using DataFrames
using Dates
using CSV
using NFLElo
using Random
using Test

@testset "Elo ratings" begin
    @test expected_score(1500, 1500) == 0.5

    ratings = Dict("A" => 1500.0, "B" => 1500.0)
    @test win_probability("A", "B", ratings) > 0.5
    @test win_probability("A", "B", ratings; neutral = true) == 0.5

    new_a, new_b = update_elo(1500, 1500, 24, 17, false)
    @test new_a > 1500
    @test new_b < 1500
    @test new_a + new_b ≈ 3000

    reverted = Dict("A" => 1600.0, "B" => 1400.0)
    @test revert_ratings!(reverted) === reverted
    @test reverted["A"] ≈ 1566.67 atol = 0.01
    @test reverted["B"] ≈ 1433.33 atol = 0.01
end

@testset "Historical ratings" begin
    games = DataFrame(
        date = Date.(["2020-09-01", "2021-09-01"]),
        season = [2020, 2021],
        neutral = [false, false],
        playoff = [false, false],
        team1 = ["A", "C"],
        team2 = ["B", "A"],
        score1 = [24, 10],
        score2 = [17, 14],
        result1 = [1.0, 0.0],
    )

    enriched, ratings, history = compute_historical_elos(games)

    @test :computed_elo1 ∉ propertynames(games)
    @test :computed_elo1 ∈ propertynames(enriched)
    @test Set(keys(history[2020])) == Set(["A", "B"])
    @test !haskey(history[2020], "C")
    @test Set(keys(ratings)) == Set(["A", "B", "C"])

    path, io = mktemp()
    close(io)
    CSV.write(path, games)
    loaded = load_games(path)
    rm(path)
    @test eltype(loaded.team1) == String
    @test eltype(loaded.team2) == String
end

@testset "Metrics" begin
    probabilities = [0.8, 0.3, 1.0]
    results = [1.0, 0.0, 1.0]

    @test brier_score(probabilities, results) ≈ (0.04 + 0.09) / 3
    @test log_loss(probabilities, results) >= 0
    @test accuracy(probabilities, results) == 1.0
    @test_throws DimensionMismatch brier_score([0.5], [0.0, 1.0])
    @test_throws ArgumentError log_loss([1.2], [1.0])
end

@testset "Simulations" begin
    ratings = Dict("A" => 1600.0, "B" => 1400.0)
    schedule = [(team1 = "A", team2 = "B", neutral = true)]

    first_run = simulate_season(schedule, ratings; n_sims = 100, rng = MersenneTwister(1))
    second_run = simulate_season(schedule, ratings; n_sims = 100, rng = MersenneTwister(1))
    @test first_run == second_run
    @test sum(first_run.avg_wins) == 1.0

    @test_throws ArgumentError simulate_season(schedule, ratings; n_sims = 0)
    @test_throws ArgumentError simulate_bracket_single(["A", "B"], ratings)
end
