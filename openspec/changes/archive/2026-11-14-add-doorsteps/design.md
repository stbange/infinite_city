# Design: add-doorsteps

- `DoorstepRules.answer(population, routines, customer, minute)` → {state, who, tip, line}; the
  household check walks the flat's residents and takes the first one whose routine says "at home".
- `Doorstep.answer(job)` (world) uses its own `Routines`; while the customer's job market is not
  built, the customer answers at full tip. `JobManager` multiplies the tip by the answer's factor
  and records `job.paid`.
