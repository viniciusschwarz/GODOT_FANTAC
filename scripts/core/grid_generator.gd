class_name GridGenerator extends RefCounted

func generate_tower_map(matrix: BattlefieldMatrix) -> void:
	# 15x15 map
	matrix.initialize_grid(15, 15, 2)

	for x in range(15):
		for y in range(15):
			# Base floor Z0
			var tile_z0 = matrix.get_tile(Vector3i(x, y, 0))
			if tile_z0:
				tile_z0.cardinal_traversal_mask = 15 # Allow all directions

			# Central tower Z1 (9x9) from coords (3, 3) to (11, 11)
			if x >= 3 and x <= 11 and y >= 3 and y <= 11:
				var tile_z1 = matrix.get_tile(Vector3i(x, y, 1))
				if tile_z1:
					tile_z1.cardinal_traversal_mask = 15 # Allow all directions

					# Add stairs on the edges of the Z1 tower
					# We place stairs at the exact edge connecting down to Z0
					# For example, North edge is y=3, South edge is y=11, West edge is x=3, East edge is x=11

					# Place 4 stairs
					if x == 7 and y == 3:
						# North stair connecting down
						tile_z0.vertical_connector_type = TileSpatialNodeResource.VerticalConnectorType.STAIRS_N
					elif x == 7 and y == 11:
						# South stair connecting down
						tile_z0.vertical_connector_type = TileSpatialNodeResource.VerticalConnectorType.STAIRS_S
					elif x == 3 and y == 7:
						# West stair connecting down
						tile_z0.vertical_connector_type = TileSpatialNodeResource.VerticalConnectorType.STAIRS_W
					elif x == 11 and y == 7:
						# East stair connecting down
						tile_z0.vertical_connector_type = TileSpatialNodeResource.VerticalConnectorType.STAIRS_E
			else:
				# Clear out the Z1 tiles that are not part of the tower
				matrix._grid.erase(Vector3i(x, y, 1))
