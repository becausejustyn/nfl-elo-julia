# Game data

Put the historical game data in this directory. The default file is
`nfl_games.csv`.

## Required columns

| Column | Type | Content |
|---|---|---|
| `date` | Date | Use the `YYYY-MM-DD` format. |
| `season` | Integer | Specify the NFL season year. |
| `neutral` | Boolean | Use 1 for a neutral site. Use 0 when team 1 is at home. |
| `playoff` | Boolean | Use 1 for a playoff game. Use 0 for a regular-season game. |
| `team1` | String | Specify the home team, or team A at a neutral site. |
| `team2` | String | Specify the away team, or team B at a neutral site. |
| `score1` | Integer | Specify the final score for team 1. |
| `score2` | Integer | Specify the final score for team 2. |
| `result1` | Number | Use 1.0 for a win, 0.5 for a tie, or 0.0 for a loss. |

The loader removes a row if a final score or result is missing. It sorts the
remaining rows by date.

## Source

The included file uses data from the
[FiveThirtyEight NFL Elo dataset](https://github.com/fivethirtyeight/data/tree/master/nfl-elo).
The pipeline ignores precomputed Elo columns.
