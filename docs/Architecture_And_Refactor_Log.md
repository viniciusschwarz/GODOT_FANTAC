## Destructible Tactical Prop Controller

- Added headless state mutation for props to `BattlefieldMatrix`.
- Implemented `apply_prop_damage`, `collapse_prop`, and `destroy_elevated_tiles` in `BattlefieldMatrix`.
- Created `tactical_prop.gd` as a view-layer observer listening to `EventBus.prop_state_changed`.
- Generated `scenes/props/tactical_prop.tscn` directly per new generation directives.
