# Design: add-plot-templates

- `DataTables.PLOT_SCHEMA` validates every `plot_*` table.
- `StoryDirector.pick_template(chronicle, layout, start)`: scores hidden_abundance 1.0 (+0.6 with a
  living food company), election 0.4 + 0.3 per living party (up to three), plague 0.8 (+0.6 with a
  living medicine company), each plus `u01(hash(seed, SALT_TEMPLATE, template)) · 0.8`.
- `StoryRunner` casts on its worker thread with the picked template and keeps `state.template_id`;
  loading a save reloads that template.
