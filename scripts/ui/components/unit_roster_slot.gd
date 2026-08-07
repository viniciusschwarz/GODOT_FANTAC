extends PanelContainer

func setup(unit_data: Dictionary):
	$HBoxContainer/NameLabel.text = unit_data.get("name", "Unknown Unit")
