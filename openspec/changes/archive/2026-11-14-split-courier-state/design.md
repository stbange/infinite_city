# Design: split-courier-state

- `CourierState` is a RefCounted owned by the job manager (`jobs.courier`) rather than a node: it
  has no per-frame work, and keeping it with the job manager spares every scene and test a node.
- `JobManager.from_dict` sees a `wallet` key (version 2 layout) and loads the courier state from it.
- `JobManager` went from 264 to under 200 lines; the plan's 150 was not reached because door
  interaction, labels and order filtering stay together where they are easiest to follow.
