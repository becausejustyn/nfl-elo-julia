# Changelog

All notable changes to this project will be documented in this file.

## Version 1.0.0

### Fixed

- **Package structure**: Added `src/NFLElo.jl` to satisfy Julia's package layout. `Project.toml` defines NFLElo as a package, but the required main module file was missing, causing `Pkg.instantiate()` to fail.

- **scripts/main.jl**:
  - Added `using Printf, Plots` — `@printf` and `savefig` were undefined.
  - Changed `parse_args(s)` to `ArgParse.parse_args(s)` to avoid shadowing ArgParse's function.

- **src/historical.jl**: CSV.jl loads team columns as `String3`, while `win_probability` expected `String`. Added conversion to `String` in `load_games` and `compute_historical_elos`.

- **src/elo.jl**: Updated `win_probability` to accept `AbstractString` (so `String3` is allowed) and to convert to `String` for dict lookups.

- **scripts/run_playoffs.jl**: Added `using Printf, Plots` so `@printf` and `savefig` are defined.

- **scripts/run_season_sim.jl**: Added `using Printf` so `@printf` is defined.
