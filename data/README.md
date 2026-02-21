# data/

## Schema

| Column     | Type    | Description                                      |
|------------|---------|--------------------------------------------------|
| date       | Date    | Game date (YYYY-MM-DD)                           |
| season     | Int     | NFL season year                                  |
| neutral    | Bool    | 1 = neutral site, 0 = team1 is home              |
| playoff    | Bool    | 1 = playoff game, 0 = regular season             |
| team1      | String  | Home team abbreviation (or team A if neutral)    |
| team2      | String  | Away team abbreviation (or team B if neutral)    |
| score1     | Int     | team1 final score                                |
| score2     | Int     | team2 final score                                |
| result1    | Float   | 1.0 = team1 win, 0.5 = tie, 0.0 = team2 win     |

## Data source

A complete historical NFL dataset in this format is available from
[FiveThirtyEight's NFL Elo dataset](https://github.com/fivethirtyeight/data/tree/master/nfl-elo).
