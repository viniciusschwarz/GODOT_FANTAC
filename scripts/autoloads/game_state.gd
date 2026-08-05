extends Node
## Central campaign & session data store.

var current_mission = null
var active_deployment_list: Array = []
var last_battle_results: Dictionary = {}
var player_roster: Array = []

func clear_state():
	current_mission = null
	active_deployment_list.clear()
	last_battle_results.clear()
	player_roster.clear()
