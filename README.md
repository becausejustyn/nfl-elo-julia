# NFL Elo Simulation (Julia)

NFL Elo rating system written in Julia. Computes historical team ratings from raw game results, evaluates predictive accuracy, and runs Monte Carlo simulations for seasons and playoff brackets. This is primarily as a learning experience for using Julia. I have never used this language before and am not sure I will want to use it again after this.

> Note: many rules change in the NFL such as playoff seeding numbers, etc. and I am not worrying about that. 

---

## Overview

This project implements a complete NFL Elo rating pipeline:

1. **Historical computation**: processes every game in chronological order, updating team ratings game-by-game and recording the pre-game rating and win probability for each matchup.
2. **Accuracy evaluation**: measures Brier score, log-loss, and directional accuracy against ground-truth results.
3. **Current rankings**: produces a live team ranking based on the most recent rating state.
4. **Season simulation**: Monte Carlo simulation of a schedule of games, producing expected win totals for each team.
5. **Playoff simulation**: simulates the full AFC and NFC brackets (7 teams each, standard NFL seeding rules) and the Super Bowl, producing conference championship and Super Bowl win probabilities for every team.

All Elo ratings are computed **from scratch**; any pre-computed columns in the input CSV are ignored.

---

## Model Design

### Elo Basics

The Elo system works by assigning each team a numerical rating and updating it after every game. The core update rule is:

```
new_rating = old_rating + K × multiplier × (actual − expected)
```

Where:

- **K = 20**: fixed K-factor controlling how much a single game can move a rating. A value of 20 is a standard choice for NFL; lower values produce more stable ratings, higher values make the system react faster to recent results.
- **expected**: the pre-game win probability derived from the difference in ratings (see below).
- **actual**: 1.0 for a win, 0.5 for a tie, 0.0 for a loss.
- **multiplier**: a margin-of-victory scaling factor (see below).

**Win probability** uses the standard logistic function with a 400-point scale (the same scale used in chess Elo and by FiveThirtyEight):

```
P(A wins) = 1 / (1 + 10^((R_B − R_A) / 400))
```

A 400-point Elo difference corresponds to roughly a 91% win probability.

### Home Field Advantage

When a game is played at team1's stadium (`neutral = 0` in the data), team1 receives a **+65 Elo point boost** before the win probability is computed. This is added to their effective rating only for the purpose of computing expected score — the stored rating is never inflated.

A 65-point HFA corresponds to roughly a 59% win probability in an evenly matched game, which is consistent with historical NFL home win rates.

For neutral-site games (`neutral = 1` — e.g. Super Bowl, London games, Mexico City), no HFA is applied.

### Margin of Victory Multiplier

A pure win/loss Elo system treats a 1-point win identically to a 40-point blowout. MOV adjustment corrects this by scaling the K-factor based on how decisive the win was.

This project uses the **FiveThirtyEight autocorrelation-corrected MOV multiplier**:

```
multiplier = log(|MOV| + 1) × (2.2 / (elo_diff × 0.001 + 2.2))
```

Where:
- `|MOV|` is the absolute margin of victory (winning score − losing score).
- `elo_diff` is the winner's pre-game Elo minus the loser's pre-game Elo (after HFA adjustment).

The second term is the **autocorrelation correction**: good teams tend to win by more, so without correction a dominant team would get inflated ratings from blowing out weak opponents. The correction dampens the multiplier when the winner was already a heavy favourite. A 1-point win has a multiplier of ~0.69; a 21-point win by an evenly matched team has a multiplier of ~2.2.

### Season Reversion

NFL team quality changes substantially from season to season due to injuries, free agency, and draft picks. To reflect this uncertainty, at the **start of each new season** every team's rating is regressed 1/3 of the way toward the league average of 1500:

```
new_rating = old_rating + (1/3) × (1500 − old_rating)
```

This means a team rated 1600 starts the new season at 1567, and a team rated 1400 starts at 1433. No team ever starts a season at their full previous rating. New or expansion teams that haven't appeared before are initialized at 1500.

---

## Project Structure

```
nfl-elo/
│
├── src/
│   ├── elo.jl           # Core Elo functions (update, win prob, MOV, reversion)
│   ├── historical.jl    # Historical computation from CSV → enriched DataFrame
│   ├── simulation.jl    # Monte Carlo season + playoff bracket simulation
│   ├── metrics.jl       # Model accuracy: Brier score, log-loss, accuracy
│   └── plots.jl         # Visualization: Elo history, ratings bar, SB odds
│
├── scripts/
│   ├── main.jl          # Full pipeline entrypoint (load → compute → export)
│   ├── run_playoffs.jl  # Playoff bracket simulation runner
│   └── run_season_sim.jl # Season schedule simulation runner
│
├── notebooks/
│   └── nfl_elo_simulation.ipynb  # Self-contained Jupyter notebook version
│
├── data/
│   └── README.md        # Expected CSV schema and data source info
│
├── results/             # Generated output files (gitignored by default)
│   └── README.md
│
├── Project.toml         # Julia package dependencies
├── .gitignore
└── README.md
```

### Module responsibilities

| File | Responsibility |
|------|---------------|
| `src/elo.jl` | Pure functions: `expected_score`, `mov_multiplier`, `update_elo`, `revert_ratings!`, `win_probability`. No I/O, no state. |
| `src/historical.jl` | Loads CSV, validates schema, runs the chronological rating pass, returns enriched DataFrame + snapshots. |
| `src/simulation.jl` | `simulate_game`, `simulate_season`, `simulate_bracket_single`, `simulate_super_bowl`. All use frozen ratings. |
| `src/metrics.jl` | `brier_score`, `log_loss`, `accuracy`, `evaluate_model`. Stateless evaluation functions. |
| `src/plots.jl` | `plot_elo_history`, `plot_ratings_bar`, `plot_sb_odds`. Returns Plots.jl objects. |
| `scripts/main.jl` | Orchestrates the full pipeline end-to-end with CLI argument support. |
| `scripts/run_playoffs.jl` | Edit seeds, run, get Super Bowl odds. |
| `scripts/run_season_sim.jl` | Edit schedule, run, get expected wins. |

---

## Setup & Installation

### Install dependencies

```bash
cd nfl-elo
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

This reads `Project.toml` and installs all required packages into the project environment.

---

## Data

A complete historical dataset in exactly this format is available from the [FiveThirtyEight NFL Elo repository](https://github.com/fivethirtyeight/data/tree/master/nfl-elo).

---

## Usage

### Full Pipeline

Runs data loading → historical Elo computation → accuracy report → current rankings → CSV export:

```bash
julia --project=. scripts/main.jl --csv data/nfl_games.csv
```

Add `--plot` to also save PNG charts to `results/`:

```bash
julia --project=. scripts/main.jl --csv data/nfl_games.csv --plot
```

### Playoff Simulation

Edit the `AFC_SEEDS` and `NFC_SEEDS` arrays in `scripts/run_playoffs.jl` to match the current playoff bracket, then run:

```bash
julia --project=. scripts/run_playoffs.jl
```

Output: `results/playoff_simulation.csv` and `results/playoff_odds.png`.

### Season Simulation

Edit the `SCHEDULE` vector in `scripts/run_season_sim.jl` with your upcoming games, then run:

```bash
julia --project=. scripts/run_season_sim.jl
```

Output: `results/season_simulation.csv`.

### Jupyter Notebook

The `notebooks/nfl_elo_simulation.ipynb` notebook is a self-contained version of the full pipeline, ideal for interactive exploration and visualization.

```bash
jupyter notebook notebooks/nfl_elo_simulation.ipynb
```

Make sure IJulia is installed and the Julia kernel is available:

```julia
using Pkg; Pkg.add("IJulia")
using IJulia; installkernel("Julia")
```

---

## Configuration

All model hyperparameters are defined as constants in `src/elo.jl`:

| Constant       | Default  | Description                                      |
|----------------|----------|--------------------------------------------------|
| `K`            | `20.0`   | K-factor — controls rating volatility            |
| `HFA`          | `65.0`   | Home field advantage in Elo points               |
| `INITIAL_ELO`  | `1500.0` | Starting rating for new/expansion teams          |
| `REVERT_FRAC`  | `1/3`    | Fraction of gap to mean regressed each new season|
| `REVERT_MEAN`  | `1500.0` | Mean rating that teams regress toward            |

To experiment with different values, edit `src/elo.jl` directly or override the constants in your script before calling the functions.

---

## Output Files

| File | Description |
|------|-------------|
| `results/elo_ratings_current.csv` | Current Elo rating for every team, ranked |
| `results/elo_game_predictions.csv` | All games with pre-game Elo and predicted win probability |
| `results/playoff_simulation.csv` | Conference and Super Bowl win % per team |
| `results/season_simulation.csv` | Average expected wins per team for a given schedule |
| `results/current_ratings.png` | Bar chart of current team ratings |
| `results/playoff_odds.png` | Bar chart of Super Bowl win probabilities |

---

## Model Accuracy

When run against the full FiveThirtyEight historical dataset (1920–2023), typical accuracy metrics are:

| Metric | Expected range | Interpretation |
|--------|---------------|----------------|
| Brier Score | 0.22 – 0.24 | Beats the 0.25 random baseline |
| Log-Loss | ~0.65 | Lower = better calibrated probabilities |
| Accuracy | ~65% | % of games where predicted favourite won |

These are consistent with published NFL Elo model benchmarks. The model is deliberately kept simple — no QB adjustments, no strength-of-schedule corrections, no within-season momentum — making it a solid and interpretable baseline.

