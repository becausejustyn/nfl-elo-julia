# Result files

The scripts write their result files to this directory.

| File | Source | Content |
|---|---|---|
| `elo_ratings_current.csv` | `scripts/main.jl` | Ratings for teams in the latest season. |
| `elo_game_predictions.csv` | `scripts/main.jl` | Historical ratings and game predictions. |
| `season_simulation.csv` | `scripts/run_season_sim.jl` | Average wins for the specified schedule. |
| `playoff_simulation.csv` | `scripts/run_playoffs.jl` | Conference and Super Bowl probabilities. |
| `current_ratings.png` | `scripts/main.jl --plot` | Current rating chart. |
| `playoff_odds.png` | `scripts/run_playoffs.jl` | Super Bowl probability chart. |

The repository contains sample result files. A script replaces its result file
when you run that script.
