class_name AsymmetricLinkRegistry
extends RefCounted

var _links_from_coord: Dictionary = {}

func register_link(from_coord: Vector2i, to_coord: Vector2i, cost: float = 1.0, mask_req: int = 0, is_bidirectional: bool = false) -> void:
	if not _links_from_coord.has(from_coord):
		_links_from_coord[from_coord] = [] as Array[Dictionary]

	# Create and append the link
	var link: Dictionary = {
		"to_coord": to_coord,
		"cost": cost,
		"mask_requirement": mask_req
	}
	_links_from_coord[from_coord].append(link)

	if is_bidirectional:
		if not _links_from_coord.has(to_coord):
			_links_from_coord[to_coord] = [] as Array[Dictionary]

		var reverse_link: Dictionary = {
			"to_coord": from_coord,
			"cost": cost,
			"mask_requirement": mask_req
		}
		_links_from_coord[to_coord].append(reverse_link)

func get_links(from_coord: Vector2i) -> Array[Dictionary]:
	if _links_from_coord.has(from_coord):
		return _links_from_coord[from_coord] as Array[Dictionary]
	return [] as Array[Dictionary]

func has_links(from_coord: Vector2i) -> bool:
	if _links_from_coord.has(from_coord):
		var links = _links_from_coord[from_coord]
		return links != null and links.size() > 0
	return false

func remove_links(from_coord: Vector2i) -> void:
	if _links_from_coord.has(from_coord):
		_links_from_coord.erase(from_coord)

func clear() -> void:
	_links_from_coord.clear()
