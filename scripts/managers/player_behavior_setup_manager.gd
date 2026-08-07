extends Node

## PlayerBehaviorSetupManager Autoload
## Handles setting up player unit AI behaviors.

func _ready() -> void:
	SignalBus.player_behavior_setup_requested.connect(_on_behavior_setup_requested)
	SignalBus.wego_phase_started.connect(_on_phase_started)

func _on_behavior_setup_requested(unit: Node, preset: String) -> void:
	if PhaseManager.current_phase != PhaseManager.Phase.BEHAVIOR_SETUP:
		return

	# In a real scenario, this would configure the unit's behavior tree
	print("PlayerBehaviorSetupManager: Set behavior for ", unit.name, " to ", preset)

func _on_phase_started(phase_name: String) -> void:
	if phase_name == "behavior_setup":
		print("PlayerBehaviorSetupManager: Behavior Setup Phase started. Applying defaults to deployed units.")
		# Normally, we'd apply presets configured from the Barracks/Roster.
		# For the MVP, we just assign a default and move on automatically
		# if the player doesn't have an explicit UI yet, or wait for them.

		# Auto-complete for MVP flow validation if no manual UI is present
		# Wait a tiny bit then end the phase
		get_tree().create_timer(1.0, true, false, true).timeout.connect(func():
			print("PlayerBehaviorSetupManager: Behavior Setup completed.")
			SignalBus.player_behavior_setup_completed.emit()
			PhaseManager.end_behavior_setup_phase()
		)
