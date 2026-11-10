# Design: add-routines

- `Routines.new(population)`; `day_plan(id, day_number) -> Array[RoutineStep]` covers the person's
  day with segments in absolute game minutes; a day starts when the previous day's commute home ends if that runs
  past midnight (night shifts, places closing at midnight); `at` looks at the day and the day before.
- Shift draw `hash(seed, SALT_ROUTINE, district, local)`: shift choice, two days off (weekdays
  h % 7 and h % 7 + 1). Shifts: 24 h places 06–14, 14–22, 22–06; places open longer than 9 h
  early (opens, +8 h) or late (closes − 8 h, closes); otherwise opens–closes.
- Commutes take 20 minutes before and after the shift (walkers arrive early and wait inside).
- Evenings out: `hash(seed, SALT_ROUTINE + 1, person, day)` < 0.3 for adults whose day is free by
  20:00 (unemployed and retired people from 15:00): 15 minutes there, two hours at a food
  workplace within two cells open then, 15 minutes back. Venue candidates are cached per home cell.
- Sleeping: 23:00–07:00 at home (night-shift workers 08:00–15:00); children stay at home.
- `RoutineStep`: activity (`sleeping`, `at home`, `commuting`, `working`, `going out`, `out`,
  `going home`), `place` (`NavPlace.inside` of home, workplace or venue), `from` for walks, `start`
  and `end` minutes, `walking`.
