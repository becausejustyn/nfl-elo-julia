# NFL Elo Simulation

Use this Julia project to calculate Elo ratings for National Football League
(NFL) teams. You can evaluate historical predictions and simulate future games.

The project calculates all ratings from the game results. It does not use the
Elo columns in the source data.

## Model

The model starts each team at 1500 Elo points. It uses these settings:

| Setting | Value | Function |
|---|---:|---|
| K-factor | 20 | Controls the rating change after a game. |
| Home-field adjustment | 65 | Increases the effective rating of the home team. |
| Elo scale | 400 | Converts a rating difference to a win probability. |
| Season reversion | 1/3 | Moves each rating toward 1500 before a new season. |

The model uses this equation for the win probability of team A:

```text
P(A wins) = 1 / (1 + 10^((rating_B - rating_A) / 400))
```

The model adds 65 points to the effective rating of the home team. It does not
change the stored rating. It does not apply this adjustment at a neutral site.

The model uses the margin of victory to scale the rating change:

```text
multiplier = log(abs(point_difference) + 1) *
             (2.2 / (winner_elo_difference * 0.001 + 2.2))
```

## Install the project

Install Julia 1.9 or a later compatible version. Then install the dependencies:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Run the rating pipeline

Run the pipeline with the included data:

```bash
julia --project=. scripts/main.jl
```

To use a different comma-separated values (CSV) file, specify its path:

```bash
julia --project=. scripts/main.jl --csv path/to/games.csv
```

To create the current-ratings plot, add `--plot`:

```bash
julia --project=. scripts/main.jl --plot
```

The pipeline does these tasks:

1. It loads and validates the game data.
2. It calculates the historical ratings in date order.
3. It prints the Brier score, log loss, and prediction accuracy.
4. It ranks the teams that played in the latest season.
5. It writes the result files.

## Run a season simulation

Edit `SCHEDULE` in `scripts/run_season_sim.jl`. Put the home team in `team1`.
Set `neutral` to `true` for a game at a neutral site.

Then run this command:

```bash
julia --project=. scripts/run_season_sim.jl
```

The script writes `results/season_simulation.csv`.
It uses a fixed random seed so that repeated runs give the same result.

## Run a playoff simulation

Edit `AFC_SEEDS` and `NFC_SEEDS` in `scripts/run_playoffs.jl`. Put the teams in
seed order. Put the first seed first.

Then run this command:

```bash
julia --project=. scripts/run_playoffs.jl
```

The script writes the playoff probabilities and a plot to `results/`.
It uses a fixed random seed so that repeated runs give the same result.

## Run the tests

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Project files

| Path | Function |
|---|---|
| `src/elo.jl` | Calculates win probabilities and rating changes. |
| `src/historical.jl` | Loads game data and calculates historical ratings. |
| `src/metrics.jl` | Calculates model performance metrics. |
| `src/simulation.jl` | Simulates scheduled games and playoff brackets. |
| `src/plots.jl` | Creates rating and probability plots. |
| `scripts/main.jl` | Runs the historical rating pipeline. |
| `scripts/run_season_sim.jl` | Runs a schedule simulation. |
| `scripts/run_playoffs.jl` | Runs a playoff simulation. |

## Data source

The included data uses the format of the
[FiveThirtyEight NFL Elo dataset](https://github.com/fivethirtyeight/data/tree/master/nfl-elo).
See `data/README.md` for the required columns.

## Model limits

The model does not adjust for quarterbacks, injuries, roster changes, or travel.
It uses fixed ratings during each simulation. It also treats team abbreviations
as separate team identities.
