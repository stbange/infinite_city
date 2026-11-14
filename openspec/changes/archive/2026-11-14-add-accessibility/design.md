# Design: add-accessibility

- Text size sets the root window's `content_scale_factor`, which scales 2D only.
- The palette maps at sign creation, so chunks loaded after the change use it.
- Rebinding replaces an action's key events with one physical key and stores it in settings.
